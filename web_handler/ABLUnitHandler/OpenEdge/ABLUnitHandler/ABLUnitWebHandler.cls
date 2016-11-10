 
/*------------------------------------------------------------------------
   File        : ABLUnitWebHandler
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : isyed
   Created     : Mon Oct 10 12:48:02 EDT 2016
   Notes       : 
 ----------------------------------------------------------------------*/


USING Progress.Lang.*.
USING OpenEdge.Web.WebResponseWriter.
USING OpenEdge.Net.HTTP.StatusCodeEnum.
USING OpenEdge.Web.WebHandler.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Lang.AppError.
USING Progress.Lang.Error.
USING OpenEdge.ABLUnitHandler.ABLUnitHandlerCore.





BLOCK-LEVEL ON ERROR UNDO, THROW.



CLASS OpenEdge.ABLUnitHandler.ABLUnitWebHandler INHERITS WebHandler: 

    DEFINE VARIABLE happSrv     AS HANDLE NO-UNDO.
    DEFINE VARIABLE asynchandle AS HANDLE NO-UNDO.
    DEFINE TEMP-TABLE ClntSession LIKE ClientSessions.
   
    CONSTRUCTOR PUBLIC ABLUnitWebHandler():
        
       
        
    END CONSTRUCTOR.
    
   
    
    METHOD OVERRIDE PROTECTED INTEGER HandleNotAllowedMethod( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.

    METHOD OVERRIDE PROTECTED INTEGER HandleNotImplemented( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.


    /*
       Access the RunWebDriver Class for the URL -  /webdriver/invoke
       The Payload should in the below format
        
      {"Sessionid":"<sessionId>","ABLUnit":[{"tests":[{"test":"test1.p"}]}]}
       
    
    */

    METHOD OVERRIDE PROTECTED INTEGER HandlePost( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        DEFINE VARIABLE oResponse        AS OpenEdge.Net.HTTP.IHttpResponse NO-UNDO.
        DEFINE VARIABLE oWriter          AS OpenEdge.Web.WebResponseWriter  NO-UNDO.
        DEFINE VARIABLE oBody            AS MEMPTR                          NO-UNDO.
        DEFINE VARIABLE PostDataJson     AS JsonObject                      NO-UNDO.
        DEFINE VARIABLE ABLUnitJsonArr   AS JsonArray                       NO-UNDO.
        DEFINE VARIABLE updatefile       AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE configJSon       AS Jsonobject                      NO-UNDO.
        DEFINE VARIABLE sessguid         AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE clntguid         AS CHARACTER                       INIT "" NO-UNDO.   
        DEFINE VARIABLE ABLUnitFunctions AS ABLUnitHandlerCore              NO-UNDO.
        DEFINE VARIABLE ApsvURL          AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE resultsDir       AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE testname         AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE rec_id           AS RECID                           NO-UNDO.
        CREATE SERVER happSrv.
        
        resultsDir = STRING(poRequest:GetContextValue("BASE_PATH") + "/static/results").
        ApsvURL = "http://localhost:" + String(poRequest:LocalPort) + poRequest:WebAppPath + "/apsv".
        happSrv:CONNECT("-URL " + ApsvURL) NO-ERROR.
        
     
        ABLUnitFunctions = NEW ABLUnitHandlerCore().
        
        sessguid = REPLACE(GUID(GENERATE-UUID),"/","-").
        ASSIGN 
            oResponse            = NEW OpenEdge.Web.WebResponse()
            oResponse:StatusCode = INTEGER(StatusCodeEnum:OK).
        
        PostDataJson = NEW JsonObject().
        configJson = NEW JsonObject().
        
        PostDataJson = CAST(poRequest:Entity,JSONObject).
        
       
        updatefile = resultsDir + "/" + sessguid + ".html".
        
        /* Generate payload for ABLUnit */
        
        configJson = ABLUnitFunctions:GenABLUnitInput(PostDataJson,sessguid,resultsDir).
        
        /* Create a new record in the database for this new session */
        
        IF PostDataJson:GetJsonArray("ABLUnit"):GetJsonObject(1):GetJsonArray("tests")
                                                    :GetJsonObject(1):Has("test") THEN
         
            testname = "test:" + String(PostDataJson:GetJsonArray("ABLUnit"):GetJsonObject(1)
                                        :GetJsonArray("tests"):GetJsonObject(1):GETCHARACTER ("test")).
        
        ELSE IF PostDataJson:GetJsonArray("ABLUnit"):GetJsonObject(1):GetJsonArray("tests")
                                                    :GetJsonObject(1):Has("folder") THEN 
        
                testname = "folder:" + String(PostDataJson:GetJsonArray("ABLUnit"):GetJsonObject(1)
                                        :GetJsonArray("tests"):GetJsonObject(1):GETCHARACTER ("folder")).
     
        
        
        /* It is recommeneded to send a Client Identity with the request. In-case if the value is not available
           in the client request  then set it to null */ 
           
        IF PostDataJson:Has("Sessionid") THEN
            clntguid = PostDataJson:GetCharacter("Sessionid").
             
        DO  TRANSACTION ON ERROR UNDO, LEAVE:
            CREATE ClientSessions.
            ASSIGN  
                ClientSessions.clientguid         = clntguid
                ClientSessions.sessionguid         = sessguid
                ClientSessions.startTime     = NOW
                ClientSessions.testname      = testname
                ClientSessions.sessionStatus = "Started".
               
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession. 
            
            VALIDATE ClientSessions.
            
            FIND ClientSessions WHERE ClientSessions.sessionguid = sessguid NO-LOCK.
            rec_id = RECID(ClientSessions).
        END.      
        
        
        /*  If the asynchronous behaviour is implemented at the client then uncomment the below code. */
        //RUN RunABLUnit.p(INPUT configJson,INPUT updatefile,INPUT sessguid,INPUT resultsDir,INPUT rec_id).
      
        /*
        
        If the client is not asynchronous and if you want to run each test asynchronously, then uncomment the below code. It will run each requests 
        asynchronously on APSV transport.
        
        */
        
        RUN RunABLUnit.p ON SERVER hAppSrv ASYNCHRONOUS SET asynchandle (INPUT configJson,INPUT updatefile,INPUT sessguid,INPUT resultsDir,INPUT rec_id).
       
        
        /* Return the Session information to the client */
        TEMP-TABLE ClntSession:WRITE-JSON("Memptr",oBody,TRUE).
       
         
        ASSIGN 
            oResponse:ContentType = 'application/json':u .
        
        
        
        ASSIGN 
            oWriter = NEW WebResponseWriter(oResponse).
        oWriter:Write(oBody).
        
    
        oWriter:Close().
        RETURN 0.
        
        CATCH e AS Progress.Lang.Error :
            
            /*
                Update the session as aborted if it enters the catch block
            */
           
            DO  TRANSACTION : 
                FIND  ClientSessions WHERE ClientSessions.sessionguid = sessguid EXCLUSIVE-LOCK.
                ASSIGN 
                    ClientSessions.EndTime = NOW.
                ClientSessions.SessionStatus = "Aborted".    
                
                VALIDATE ClientSessions.
                MESSAGE "It failed invoking ABLUnit".
                DEFINE VARIABLE iLoop AS INTEGER NO-UNDO.
                DO iLoop = 1 TO e:NumMessages:
                    MESSAGE 
                        'ERROR: ' e:GetMessage(iLoop) SKIP.
                END.
            END.
                  
        END CATCH.
        
        
        FINALLY:
            
          
        END FINALLY.

    END METHOD.           
    
 
    DESTRUCTOR ABLUnitWebHandler():
        
        hAppSrv:DISCONNECT().
        DELETE OBJECT hAppSrv.
        
        EMPTY TEMP-TABLE ClntSession.
        
    END DESTRUCTOR.
END CLASS.
