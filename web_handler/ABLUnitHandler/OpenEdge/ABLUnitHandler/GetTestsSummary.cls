 
/*------------------------------------------------------------------------
   File        : GetTestsSummary
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : isyed
   Created     : Tue Oct 18 22:53:36 EDT 2016
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Web.WebResponseWriter.
USING OpenEdge.Net.HTTP.StatusCodeEnum.
USING OpenEdge.Web.WebHandler.
USING OpenEdge.Net.HTTP.StatusCodeEnum.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.
USING OpenEdge.Net.HTTP.IHttpResponse FROM PROPATH.
USING OpenEdge.Web.IWebRequest FROM PROPATH.
USING OpenEdge.ABLUnitHandler.ABLUnitHandlerCore.
USING System.IO.StreamReader FROM ASSEMBLY.
USING System.Configuration.ClientSettingsSection FROM ASSEMBLY.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.ABLUnitHandler.GetTestsSummary INHERITS WebHandler: 
    
   
    DEFINE TEMP-TABLE ClntSession LIKE ClientSessions.
    
    DEFINE TEMP-TABLE testSuite 
        FIELD testSuiteStatus AS CHARACTER.
        
    DEFINE DATASET ClntStatus FOR testSuite,ClntSession.    
    
    
    CONSTRUCTOR GetTestsSummary():
    
        EMPTY TEMP-TABLE ClntSession.
        DATASET ClntStatus:EMPTY-DATASET ().
        
        
    END CONSTRUCTOR.    

    METHOD OVERRIDE PROTECTED INTEGER HandleNotAllowedMethod( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.

    METHOD OVERRIDE PROTECTED INTEGER HandleNotImplemented( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.
    
    
    /*
        Handles all the Test Summary related information
    */
    
    METHOD OVERRIDE PROTECTED INTEGER HandleGet( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        DEFINE VARIABLE oResponse    AS OpenEdge.Net.HTTP.IHttpResponse NO-UNDO.
        DEFINE VARIABLE oWriter      AS OpenEdge.Web.WebResponseWriter  NO-UNDO.
        DEFINE VARIABLE oBody        AS OpenEdge.Core.String            NO-UNDO.
        DEFINE VARIABLE RespHandle   AS MEMPTR                          NO-UNDO.
        DEFINE VARIABLE sortbyval    AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE filter_entry AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE iLoop        AS INTEGER                         NO-UNDO.
        DEFINE VARIABLE DynQuery     AS CHARACTER                       NO-UNDO.
        DEFINE VARIABLE i            AS INTEGER                         NO-UNDO.
        
        ASSIGN 
            oResponse            = NEW OpenEdge.Web.WebResponse()
            oResponse:StatusCode = INTEGER(StatusCodeEnum:OK).
        oResponse:ContentType = "application/json".
            
        owriter = NEW WebResponseWriter(oResponse).
     
            
        CASE TRUE:
            WHEN poRequest:GetContextValue("REQUEST_URI") MATCHES "*clientsession*" THEN   
                RespHandle = GetAllClientSessions(STRING(poRequest:GetPathParameter("clientsessionid"))).
                
            WHEN poRequest:GetContextValue("REQUEST_URI") MATCHES "*all/active" THEN
                RespHandle = GetAllActiveSessions().
                    
            WHEN   poRequest:GetContextValue("REQUEST_URI") MATCHES "*all/complete" THEN
            
                RespHandle = GetCompletedSessions().
                    
            WHEN  poRequest:GetContextValue("REQUEST_URI") MATCHES "*all/aborted" THEN
                RespHandle = GetAbortedSessions(). 
                
            WHEN  poRequest:GetContextValue("REQUEST_URI") MATCHES "*tests*" THEN
                RespHandle = GetUnitests(STRING(poRequest:GetPathParameter("testcase"))). 
            
            WHEN poRequest:GetContextValue("REQUEST_URI") MATCHES "*session/*" THEN
                RespHandle = GetTestSession(STRING(poRequest:GetPathParameter("sessionid"))).
                
            WHEN poRequest:GetContextValue("REQUEST_URI") MATCHES "*all" THEN
                DO:
                    
                    IF poRequest:URI:GetQueryValue("sortby") NE ? AND poRequest:URI:GetQueryValue("filter") EQ ? THEN
                    DO:
                        /*   Below URL's are expected to access /getcompletedsessions with sorting
                                
                           /sessions/all?sortby=StartTime
                           /sessions/all?sortby=EndTime
                           /sessions/all?sortby=ExecTime
                                       
                         */
                    
                    
                        MESSAGE "Inside *all?  URI ".                
                        
                        sortbyval = poRequest:URI:GetQueryValue("sortby").
         
                        IF sortbyval NE "" THEN 
                        DO: 
                            CASE sortbyval:
                                WHEN "startTime" THEN
                                    RespHandle =    SortbyStartTime().
                                WHEN "endTime" THEN
                                    RespHandle = SortbyEndTime().
                                WHEN "execTime" THEN
                                    RespHandle =  SortbyExecTime().
                            
                                OTHERWISE 
                                DO:
                                    oResponse:StatusCode = 500.
                                    oResponse:ContentType = "text/html":U.
                                    owriter:write("Sortby value did not match").
                                    oWriter:Close().
                                    RETURN 0.
                                END.
                                
                            END.
                        END.
                   
                    END.     
                    ELSE
                    
                        RespHandle = GetAllSessions().
                     
                    /*
                     
                       Filter using Dynamic Query
                    */
                     
                    IF poRequest:URI:GetQueryValue("filter") NE ? THEN
                    DO:
                       
                        filter_entry = STRING(poRequest:URI:GetQueryValue("filter")).
                       
                        IF NUM-ENTRIES(filter_entry,"&") >= 1 THEN       
                        DO:
                            iLoop = NUM-ENTRIES(filter_entry,"&").
                            DO i = 1 TO iLoop:
                                    
                                IF i = 1 THEN
                                    DynQuery = ENTRY(i,filter_entry,"&").
                                ELSE
                                    DynQuery = DynQuery + " AND "  + ENTRY(i,filter_entry,"&").
                                   
                            END.
                            DynQuery = STRING(DynQuery) + " NO-LOCK".
                            
                            IF poRequest:URI:GetQueryValue("sortby") NE ? THEN
                                DynQuery = DynQuery + " BY " + String(poRequest:URI:GetQueryValue("sortby")).
                            
                            MESSAGE "DynQuery is " + String(DynQuery).
                            RespHandle = ExecDynamicQuery(DynQuery). 
                               
                        END.
                       
                    END.   
                END.   

            OTHERWISE 
            DO:
                oResponse:StatusCode = 500.
                oResponse:ContentType = "text/html".
                owriter:Write("Pattern did not match").
                oWriter:Close().
                RETURN 0.
                    
            END.
        END.

   
        owriter:Write(RespHandle).
    
        oWriter:Close().
        RETURN 0.
        
        
        CATCH err1 AS Progress.Lang.Error :
            MESSAGE "Failed in HandleGet Method".
            MESSAGE err1:GetMessage(1).
            MESSAGE err1:CallStack.
            oResponse:StatusCode = 500.
            oResponse:ContentType = "text/html".
            owriter:Write(err1:CallStack).
            owriter:Close().
        END CATCH.
        
       

    END METHOD.
    
    /* Get the list of test sessions(ABLUnit tests) executed by a particular client session.
    In addition to that, it verifies if client session is Passed,Failed or Running.
                        
    Passed - If all the tests in the ABLUnit Procedures or Classes of the Client session are successfully executed.
                        
    Failed - If one or more tests in the ABLUnit Procedurs or Classes of the Client session are failed.
                        
    Running - In one or more ABLUnit Procedures or Classes of the Client session are still running.
                            
                            
                           
    */
    
    METHOD PUBLIC MEMPTR GetAllClientSessions(INPUT clientsession-id AS CHARACTER):
        
       
        DEFINE VARIABLE MemptrObj   AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE flag_status AS LOGICAL   INITIAL TRUE NO-UNDO.
        DEFINE VARIABLE flag_exec   AS LOGICAL   INITIAL TRUE NO-UNDO.
        DEFINE VARIABLE testStatus  AS CHARACTER INITIAL "Running" NO-UNDO.
        
        MESSAGE "In GetAllClientSessions".
        MESSAGE "client session value is " + clientsession-id.
        
        FOR EACH ClientSessions WHERE ClientSessions.clientguid = clientsession-id NO-LOCK:
            IF AVAILABLE ClientSessions THEN 
            DO:
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
               
                IF ClientSessions.testStatus EQ "Started" THEN 
                DO:
                    testStatus = "Running".
                    
                END.
                IF flag_status THEN
                DO:
                    IF ClientSessions.testStatus NE "" THEN 
                    DO:
                        flag_status = TRUE.
                
                        IF flag_exec THEN
                        DO:
                            IF ClientSessions.testStatus NE "Failed" THEN
                            DO:
                                MESSAGE "teststatus value is(failed) " + ClientSessions.testStatus.
                                flag_exec = TRUE.
                                testStatus = "Passed".
                            END.
                                
                            ELSE
                            DO:
                                flag_exec = FALSE.
                                testStatus = "Failed".
                            END.
                        END.
                    END.
                    ELSE
                        flag_status = FALSE.
            
                END.
               
            
            END.
            ELSE 
                testStatus = "Could not find the test".
        END.
            
            
        MESSAGE "testStatus value is " + testStatus.
        CREATE testSuite.
        ASSIGN 
            testSuite.testSuiteStatus = testStatus.
            
        DATASET ClntStatus:WRITE-JSON("Memptr",MemptrObj,TRUE).  
      
        DATASET ClntStatus:EMPTY-DATASET ().
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
        		message "Failed in GetAllClientSessions".
        		return error e:CallStack.
        END CATCH.
    END METHOD.
    
    /*
                        
        Get all Client sessions tests that are still activate and running
    */
    
    METHOD PUBLIC MEMPTR GetAllActiveSessions():
        
        DEFINE VARIABLE MemptrObj AS MEMPTR.
        
        FOR EACH ClientSessions NO-LOCK:
            IF ClientSessions.SessionStatus = "Started" THEN
            DO:
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
            END.
                
        END. 
        
        TEMP-TABLE ClntSession:WRITE-JSON("Memptr",MemptrObj,TRUE).
        EMPTY TEMP-TABLE ClntSession.
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
        		message "Failed in GetAllActiveSessions".
        		return error e:CallStack.
        END CATCH.
        
        
    END METHOD.
    
    
    METHOD PUBLIC MEMPTR GetAllSessions():
        DEFINE VARIABLE MemptrObj AS MEMPTR.
        
        FOR EACH ClientSessions NO-LOCK:
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession.
        END. 
        
        TEMP-TABLE ClntSession:WRITE-JSON("Memptr",MemptrObj,TRUE).
        EMPTY TEMP-TABLE ClntSession.
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
        		message "Failed in GetAllSessions".
        		return error e:CallStack.
        END CATCH.
    END METHOD.
    
    /*
        Get information about a individual ABLUnitTest Procedure or Class of any Client session
    */
    
    METHOD PUBLIC MEMPTR GetTestSession(INPUT testsession AS CHARACTER):
        
        DEFINE VARIABLE MemptrObj AS MEMPTR.
        
        FIND FIRST ClientSessions WHERE ClientSessions.sessionguid = testsession NO-LOCK.
        CREATE ClntSession.
        BUFFER-COPY ClientSessions TO ClntSession.
           
        TEMP-TABLE ClntSession:WRITE-JSON("Memptr",MemptrObj,TRUE). 
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
        		message "Failed in GetTestSession".
        		return error e:CallStack.
        END CATCH.
        
    END METHOD.
    
    
    /*
                        
        Get all  sessions tests that have completed execution.
    */
    
    METHOD PUBLIC MEMPTR GetCompletedSessions():

        
        DEFINE VARIABLE MemptrObj AS MEMPTR.
        
        FOR EACH ClientSessions NO-LOCK:
            IF ClientSessions.SessionStatus = "Completed" THEN
            DO:
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
            END.
                
        END. 
           
        TEMP-TABLE ClntSession:WRITE-JSON("Memptr",MemptrObj,TRUE).    
        EMPTY TEMP-TABLE ClntSession.    
        RETURN MemptrObj.
        
         CATCH e AS Progress.Lang.Error :
                message "Failed in GetCompletedSessions".
                return error e:CallStack.
        END CATCH.
        
    END METHOD.
    
   
    /*
                        
        Get all Client sessions tests that are aborted in the middle of the test.
    */
    
    
    METHOD PUBLIC MEMPTR GetAbortedSessions():

        DEFINE VARIABLE MemptrObj AS MEMPTR.

        FOR EACH ClientSessions NO-LOCK:
            IF ClientSessions.SessionStatus = "Aborted" THEN
            DO:
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
            END.
                
        END. 
           
        TEMP-TABLE ClntSession:WRITE-JSON ("memptr",MemptrObj,TRUE). 
        EMPTY TEMP-TABLE ClntSession.
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
                message "Failed in GetAbortedSessions".
                return error e:CallStack.
        END CATCH.
        
    END METHOD.
    
    /*
        Get the list of Unit tests in a given ABLUnit Procedure or ClassName.
    */
    
    METHOD PUBLIC MEMPTR GetUnitests(INPUT testcase AS CHARACTER):

        DEFINE VARIABLE GetTests  AS OpenEdge.ABLUnitHandler.ABLUnitHandlerCore.
        DEFINE VARIABLE MemptrObj AS MEMPTR.
        
        GetTests = NEW OpenEdge.ABLUnitHandler.ABLUnitHandlerCore().
        
        /* We are only getting the procedures/methods with annotation as @Test.
           The same method can be used to get informaton for any annotation name.
        */
        
        MemptrObj = GetTests:GetTestList(testcase,"Test").
        
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
                message "Failed in GetUnitests".
                return error e:CallStack.
        END CATCH.
        
        
    END METHOD.
    
    /*
        Functions to sort the ClientSessions output
    */
    
    METHOD PUBLIC MEMPTR SortbyStartTime():

        DEFINE VARIABLE MemptrObj AS MEMPTR.

        FOR EACH ClientSessions NO-LOCK  BY ClientSessions.startTime: 
           
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession.
                
        END. 
           
        TEMP-TABLE ClntSession:WRITE-JSON ("memptr",MemptrObj,TRUE). 
        EMPTY TEMP-TABLE ClntSession.
        
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
                message "Failed in SortbyStartTime".
                return error e:CallStack.
        END CATCH.
        
    END METHOD.
    
    
    METHOD PUBLIC MEMPTR SortbyEndTime():

        DEFINE VARIABLE MemptrObj AS MEMPTR.

        FOR EACH ClientSessions NO-LOCK  BY ClientSessions.endTime: 
           
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession.
                
        END. 
           
        TEMP-TABLE ClntSession:WRITE-JSON ("memptr",MemptrObj,TRUE). 
        EMPTY TEMP-TABLE ClntSession.
        
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
                message "Failed in SortbyEndTime".
                return error e:CallStack.
        END CATCH.
        
        
    END METHOD.
    
    
    
    METHOD PUBLIC MEMPTR SortbyExecTime():

        DEFINE VARIABLE MemptrObj AS MEMPTR.

        FOR EACH ClientSessions NO-LOCK  BY ClientSessions.ExecTime: 
           
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession.
                
        END. 
           
        TEMP-TABLE ClntSession:WRITE-JSON ("memptr",MemptrObj,TRUE). 
        EMPTY TEMP-TABLE ClntSession.
        
        RETURN MemptrObj.
        
        CATCH e AS Progress.Lang.Error :
                message "Failed in SortbyExecTime".
                return error e:CallStack.
        END CATCH.
        
    END METHOD.
    
    /*
       Execute DynamicQuery based on input value on ClientSessions table
    */
   
    METHOD PUBLIC MEMPTR ExecDynamicQuery(INPUT dynQuery AS CHARACTER):
       
        DEFINE VARIABLE qh        AS WIDGET-HANDLE.
        DEFINE VARIABLE MemptrObj AS MEMPTR        NO-UNDO.

        CREATE QUERY qh.
        qh:SET-BUFFERS(BUFFER ClientSessions:HANDLE).
        qh:QUERY-PREPARE("FOR EACH ClientSessions WHERE " + String(dynQuery)).
        qh:QUERY-OPEN.
 
        REPEAT WITH FRAME y:
            qh:GET-NEXT().
            IF qh:QUERY-OFF-END THEN LEAVE.
            CREATE ClntSession.
            BUFFER-COPY ClientSessions TO ClntSession.
        END.

        qh:QUERY-CLOSE().
        DELETE OBJECT qh.
        
        TEMP-TABLE ClntSession:WRITE-JSON ("memptr",MemptrObj,TRUE). 
        EMPTY TEMP-TABLE ClntSession.
        
        RETURN MemptrObj.
        
         CATCH e AS Progress.Lang.Error :
                message "Failed in ExecDynamicQuery".
                return error e:CallStack.
        END CATCH.
         
    END METHOD. 
  
  
   /*
        Clean-up the temp-tables and datasets used for this user session
    */
     
     
    DESTRUCTOR PUBLIC GetTestsSummary():
        
        EMPTY TEMP-TABLE ClntSession.
        DATASET ClntStatus:EMPTY-DATASET ().
        
    END DESTRUCTOR.
   
END CLASS.
