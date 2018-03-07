 
/*------------------------------------------------------------------------
   File        : TestMetrics
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : isyed
   Created     : Thu Nov 03 21:53:13 EDT 2016
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Web.WebResponseWriter.
USING OpenEdge.Net.HTTP.StatusCodeEnum.
USING OpenEdge.Web.WebHandler.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.ABLUnitHandler.TestMetrics INHERITS WebHandler: 

    DEFINE TEMP-TABLE ClntSession LIKE ClientSessions.
    
   
    DEFINE TEMP-TABLE TestSummary 
        FIELD CompletedSessions AS INTEGER
        FIELD ActiveSessions    AS INTEGER.
        
    DEFINE TEMP-TABLE CountMetrics
        FIELD TotalClientSessions AS INTEGER
        FIELD TotalTestSessions   AS INTEGER
        FIELD TotalTestCases      AS INTEGER
        FIELD TotalPassed         AS INTEGER
        FIELD TotalFailed         AS INTEGER
        FIELD TotalAborted        AS INTEGER.
    
    DEFINE TEMP-TABLE MaxExecTime    
        FIELD MaxExecTime AS character
        FIELD testcase    AS CHARACTER
        FIELD testsession as CHARACTER.
        
        
    DEFINE TEMP-TABLE MinExecTime    
        FIELD MinExecTime AS character
        FIELD testcase    AS CHARACTER
        FIELD testsession as character.
    
        
    DEFINE DATASET TestMetrics FOR TestSummary,CountMetrics,MaxExecTime,MinExecTime.    
       

    CONSTRUCTOR TestMetrics():
        
        
        
        EMPTY TEMP-TABLE TestSummary.
        EMPTY TEMP-TABLE MaxExecTime.
        EMPTY TEMP-TABLE MinExecTime.
        EMPTY TEMP-TABLE CountMetrics.
        DATASET TestMetrics:EMPTY-DATASET ().
        
    END CONSTRUCTOR.
	

    METHOD OVERRIDE PROTECTED INTEGER HandleNotAllowedMethod( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
	
        	
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").
    END METHOD.


    METHOD OVERRIDE PROTECTED INTEGER HandleNotImplemented( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
	
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").
    END METHOD.
 	
	
    /*
     Get all metrics related statistics
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
           
           
            /*
             Check if URI has query param "intervalof". If it does not exist then set the value to 
             10 years and get all the available data.
            */
                
            WHEN poRequest:GetContextValue("REQUEST_URI") MATCHES "*metrics" THEN
                DO:
                    if poRequest:URI:GetQueryValue("intervalof") NE ? then
                        RespHandle = RunMetrics(String(poRequest:URI:GetQueryValue("intervalof"))).
                    else
                    do:
                        RespHandle = RunMetrics("10years").
                    end.
                end.
		
            OTHERWISE 
            DO:
                MESSAGE "Pattern did not match".
                oResponse:StatusCode = 500.
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
            owriter:Write(err1:CallStack).
            oWriter:Close().
            return 0.
        END CATCH.
        
       
      
		
    END METHOD. 
 	
 	
 
    METHOD PUBLIC Memptr RunMetrics(bytime as char):
        
        DEFINE VARIABLE dynQuery           AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE count_testsessn    AS INTEGER     NO-UNDO INIT 0.
        DEFINE VARIABLE count_tcases       AS INTEGER     NO-UNDO INIT 0.
        DEFINE VARIABLE count_failedtests  AS INTEGER     NO-UNDO INIT 0.
        DEFINE VARIABLE count_passedtests  AS INTEGER     NO-UNDO INIT 0.
        DEFINE VARIABLE count_abortedtests AS INTEGER     NO-UNDO INIT 0.
        DEFINE VARIABLE test_status        AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE act_teststate      AS INTEGER     NO-UNDO.
        DEFINE VARIABLE comp_teststate     AS INTEGER     NO-UNDO.
        DEFINE VARIABLE test_state         AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE counter            AS INTEGER     NO-UNDO INIT 1.
        DEFINE VARIABLE max_exectime       AS INTEGER     INIT 0.
        DEFINE VARIABLE max_tcase          AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE min_exectime       AS INTEGER     INIT 0.
        DEFINE VARIABLE min_tcase          AS CHARACTER   NO-UNDO.
        def    var      MemptrObj          as Memptr      NO-UNDO.
        def    var      dtime              as datetime-tz no-undo.
        def    var      by_time            as int         no-undo.
        def    var      val1               as char.
        
        
        /*
        Extract input value for intervalOf query parameter and convert it into datetime-tz value
        */
        case true:
            
            when bytime matches "*mins" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("mins"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"minutes").
                end.
                  
            when bytime matches "*min" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("min"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"minutes").
                end.
                
            when bytime matches "*hours" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("hours"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"hours").
                end.
                 
            when bytime matches "*hour" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("hour"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"hours").
                end.
            
            when bytime matches "*days" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("days"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"days").
                end.
            
            when bytime matches "*day" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("day"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"days").
                    
                end.
            
                
            when bytime matches "*weeks" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("weeks"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"weeks").
                end.
            
            when bytime matches "*week" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("week"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"weeks").
                end.
        
        
            when bytime matches "*months" then 
                do:
                   
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("months"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"months").
                end.
           
            when bytime matches "*month" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("month"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"months").
                end.
            
            when bytime matches "*years" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("years"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"years").
                end.
            
            when bytime matches "*year" then 
                do:
                    by_time =  INT(SUBSTRING(bytime,1,LENGTH(bytime) - LENGTH("year"))).
                    dtime = ADD-INTERVAL(NOW,-(by_time),"years").
                end.
                
            OTHERWISE 
            DO:
                RETURN ERROR "Invalid Entry".
                            
            END.
        end.  
        
        /*
            Calculate test metrics for various parameters
        */
                    
        FOR EACH ClientSessions NO-LOCK where ClientSessions.startTime > dtime:
            count_testsessn = count_testsessn + 1.
            count_tcases = count_tcases + int(ClientSessions.testcases).
            
            test_status = ClientSessions.testStatus.
            
            
            CASE test_status:
                
                WHEN "PASSED" THEN
                    count_passedtests = count_passedtests + 1.
                 
                WHEN "Failed" THEN 
                    count_failedtests = count_failedtests + 1.
              END.
         
            test_state = ClientSessions.SessionStatus.
            CASE test_state:
                
                WHEN "Started" THEN
                    act_teststate = act_teststate + 1.
                 
                WHEN "Completed" THEN 
                    comp_teststate = comp_teststate + 1.
                    
                WHEN "Aborted" THEN
                    count_abortedtests = count_abortedtests + 1.    
                 
            END.
                 
        END. 
        
        CREATE CountMetrics.
        ASSIGN 
            CountMetrics.TotalClientSessions = TotalClientSessions(dtime)
            CountMetrics.TotalAborted        = count_abortedtests
            CountMetrics.TotalFailed         = count_failedtests
            CountMetrics.TotalPassed         = count_passedtests
            CountMetrics.TotalTestCases      = count_tcases
            CountMetrics.TotalTestSessions   = count_testsessn.
            
            
        CREATE TestSummary.
        ASSIGN 
            TestSummary.ActiveSessions    = act_teststate
            TestSummary.CompletedSessions = comp_teststate.
            
            
        EMPTY TEMP-TABLE ClntSession.
        FOR EACH ClientSessions where ClientSessions.sessionStatus = "Completed"  and ClientSessions.startTime > dtime NO-LOCK BY ClientSessions.ExecTime:
            create ClntSession.
            buffer-copy ClientSessions to ClntSession.
        END.  
        
        if temp-table ClntSession:HAS-RECORDS 
            then
        do:
            find first ClntSession.
            create MinExecTime.
            assign
                MinExecTime.MinExecTime = String(ClntSession.ExecTime) + " millisec"
                MinExecTime.testcase    = ClntSession.testname
                MinExecTime.testsession = ClntSession.sessionguid.
        
            find last ClntSession.       
            Create MaxExecTime.
            assign 
                MaxExecTime.MaxExecTime = String(ClntSession.ExecTime) + " millisec"
                MaxExecTime.testcase    = ClntSession.testname
                MaxExecTime.testsession = ClntSession.sessionguid.
           
            EMPTY TEMP-TABLE ClntSession.    
        end.
       
        DATASET TestMetrics:WRITE-JSON("Memptr",MemptrObj,TRUE).
      
        EMPTY TEMP-TABLE TestSummary.
        EMPTY TEMP-TABLE MaxExecTime.
        EMPTY TEMP-TABLE MinExecTime.
        EMPTY TEMP-TABLE CountMetrics.
        DATASET TestMetrics:EMPTY-DATASET ().
        
        return MemptrObj.
       
       
        CATCH e AS Progress.Lang.Error :
            message "failed in RunMetrics filter".
            message e:CallStack.
            message e:GetMessage(1).
            return error e:CallStack.
        END CATCH.
      
             
        
    END METHOD.
    
    
    METHOD PUBLIC INTEGER ExecMetricsInfo(INPUT dynQuery AS CHARACTER):
       
        DEFINE VARIABLE qh        AS WIDGET-HANDLE.
        DEFINE VARIABLE MemptrObj AS MEMPTR        NO-UNDO.
        DEFINE VARIABLE counter   AS INTEGER       INIT 0 NO-UNDO.

        CREATE QUERY qh.
        qh:SET-BUFFERS(BUFFER ClientSessions:HANDLE).
        qh:QUERY-PREPARE("FOR EACH ClientSessions WHERE " + String(dynQuery)).
        qh:QUERY-OPEN.
 
        REPEAT WITH FRAME y:
            qh:GET-NEXT().
            IF qh:QUERY-OFF-END THEN LEAVE.
            counter = counter + 1.
        END.

        qh:QUERY-CLOSE().
        DELETE OBJECT qh.
        
        
        RETURN counter.
         
    END METHOD. 
    
    
 
    METHOD PUBLIC INTEGER TotalClientSessions(input by_time as datetime-tz):
       
        DEFINE VARIABLE flag AS LOGICAL INIT TRUE.
        DEFINE VARIABLE i    AS INTEGER INIT 0.

       
        FOR EACH ClientSessions where ClientSessions.startTime > by_time NO-LOCK:
            DEFINE VARIABLE cguid AS CHARACTER.   
            cguid = ClientSessions.clientguid.
    
            IF (flag) THEN 
            DO:
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
                i = i + 1.
                flag = FALSE.
            END.         
    
         
            FIND ClntSession WHERE ClntSession.clientguid = cguid NO-LOCK NO-ERROR.
            IF NOT AVAILABLE ClntSession THEN
            DO:
           
                CREATE ClntSession.
                BUFFER-COPY ClientSessions TO ClntSession.
                i = i + 1.
        
            END.
        END.
       
       
        RETURN i.




        CATCH e AS Progress.Lang.Error :
            MESSAGE e:CallStack.
            return error e:CallStack.
        END CATCH.
        
    END METHOD.
	
END CLASS.
