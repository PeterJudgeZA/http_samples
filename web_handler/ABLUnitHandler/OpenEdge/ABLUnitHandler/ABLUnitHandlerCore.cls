 
/*------------------------------------------------------------------------
   File        : ABLUnitHandlerCore
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : isyed
   Created     : Tue Oct 18 00:42:51 EDT 2016
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.*.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING OpenEdge.ABLUnit.Runner.ABLRunner.
USING OpenEdge.ABLUnit.Runner.TestConfig.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Lang.AppError.
USING Progress.Lang.Error.
USING OpenEdge.ABLUnit.Reflection.TestInfo.
USING OpenEdge.ABLUnit.Reflection.TypeInfo.
USING OpenEdge.Core.Collections.Array.
USING OpenEdge.ABLUnit.Reflection.AnnotationInfo.
USING OpenEdge.ABLUnit.Reflection.ClassAnnotationInfo.


BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.ABLUnitHandler.ABLUnitHandlerCore: 
    
    
   
    DEFINE TEMP-TABLE TestList
        FIELD annotationType AS CHARACTER
        FIELD testname       AS CHARACTER.      
    
    /*
    
    Invoke ABLUnit libraries with the input provided
    */
    METHOD PUBLIC VOID InvokeABLUnitTests(INPUT configJSON AS JsonObject,INPUT updatefile AS CHARACTER):
        DEFINE VARIABLE testConfig AS CLASS     TestConfig NO-UNDO.
        DEFINE VARIABLE ablRunner  AS ABLRunner NO-UNDO.
       
       
        testConfig = NEW TestConfig(configJson).
        ablRunner = NEW ABLRunner(testConfig, updateFile).
        ablRunner:RunTests(). 
        
        CATCH InvokeTestsException AS Progress.Lang.Error :
            
            
            DO TRANSACTION:
                FIND  ClientSessions WHERE ClientSessions.sessionguid = String(configJson:GetJsonObject("options"):GetJsonObject("output"):GetCharacter("fileName")) EXCLUSIVE-LOCK.
                ASSIGN
                    ClientSessions.endTime         = NOW
                    ClientSessions.SessionStatus = "Aborted".
                
                VALIDATE ClientSessions.
            END.
            
            MESSAGE "Failed in InvokeTestsException".
            MESSAGE InvokeTestsException:GetMessage(1).
            MESSAGE InvokeTestsException:CallStack.
            RETURN ERROR InvokeTestsException:GetMessage(1).     
        END CATCH.
        
    END METHOD.
    
    /*
      Get the list of testcases for a given Procedure/Class and annotationType
    */
        
    METHOD PUBLIC MEMPTR GetTestList(INPUT testcase AS CHARACTER,INPUT annotationType AS CHARACTER):
          
        DEFINE VARIABLE ablRunner        AS ABLRunner           NO-UNDO.
        DEFINE VARIABLE updateFile       AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE testConfig       AS TestConfig          NO-UNDO.
        DEFINE VARIABLE typeInfo         AS TypeInfo            NO-UNDO.
        DEFINE VARIABLE testInfo         AS TestInfo            NO-UNDO.
        DEFINE VARIABLE methodInfoList   AS Array               NO-UNDO.
        DEFINE VARIABLE i                AS INTEGER             NO-UNDO.
        DEFINE VARIABLE j                AS INTEGER             NO-UNDO.
        DEFINE VARIABLE annotationName   AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE classAnnotInfo   AS ClassAnnotationInfo NO-UNDO.
        DEFINE VARIABLE testlistJson     AS MEMPTR              NO-UNDO.
        DEFINE VARIABLE annotations      AS Array               NO-UNDO.
        DEFINE VARIABLE annotationsCount AS INTEGER             NO-UNDO.
        DEFINE VARIABLE annotationInfo   AS AnnotationInfo      NO-UNDO.
        DEFINE VARIABLE configJson       AS Jsonobject          NO-UNDO.
        DEFINE VARIABLE configObj        AS JsonObject          NO-UNDO.
        DEFINE VARIABLE configArr        AS JsonArray           NO-UNDO.

     
        configJson = NEW JSONObject().
        configObj = NEW JSONObject().
        configArr = NEW JsonArray().
      
        
        configObj:Add("test",testcase).
        configArr:Add(configObj).
        
        configJson:Add("tests",configArr).
        
        
        testConfig = NEW TestConfig(configJson).
        ablRunner = NEW ABLRunner(testConfig, updateFile).
        typeInfo = ablRunner:BuildTypeInfo(testcase).

        methodInfoList = typeInfo:methods.

        DO i=1 TO typeInfo:methodsCount:
            testInfo = CAST(methodInfoList:GetValue(i), TestInfo).
    
            annotations = testInfo:annotations.
            annotationsCount = testInfo:annotationsCount.
                
            DO j=1 TO annotationsCount:
                annotationInfo = CAST(annotations:GetValue(j), AnnotationInfo).
                annotationName = annotationInfo:getAnnotationName().
        
                CASE annotationName:
                    
                    WHEN annotationType THEN
                        DO:
                            CREATE  testlist.
                            ASSIGN 
                                testlist.annotationType = annotationType
                                testlist.testname       = testInfo:getTestName().
                    
                
                        END.
                
                END CASE.
            END.
        END.

        TEMP-TABLE TestList:WRITE-JSON("memptr",testlistJson,TRUE).
        RETURN testlistJSon.
        
        CATCH GetTestListExc AS Progress.Lang.Error :
            
            MESSAGE "Failure in GetTestList method".
            MESSAGE GetTestListExc:GetMessage(1).
            MESSAGE GetTestListExc:CallStack.
            return error GetTestListExc:CallStack.
                
        END CATCH.
        
        FINALLY:
           
            DELETE OBJECT   configJson.
            DELETE OBJECT  configObj.
            DELETE OBJECT configArr.
        END FINALLY.
          
    END METHOD.  
    
    
    /*
        Check if the test is passed or failed from the generated xml file per session
    
    */
    
    METHOD PUBLIC VOID ValidateResults(INPUT sessionid AS CHARACTER,INPUT resultsDir AS CHARACTER, input rec_id as RECID):
        
        DEFINE VARIABLE hdl           AS HANDLE     NO-UNDO.
        DEFINE VARIABLE Jobj          AS JsonObject NO-UNDO.
        DEFINE VARIABLE DatasetObj    AS JSONOBject NO-UNDO.
        DEFINE VARIABLE testsuitesArr AS JsonArray  NO-UNDO.
        DEFINE VARIABLE teststatus    AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE Xmlfile       AS CHARACTER  NO-UNDO.
        CREATE DATASET hdl.

        Jobj = NEW JSONObject().
    
        Xmlfile = resultsDir + "/" + sessionid + ".xml".
    
        FILE-INFO:FILE-NAME = Xmlfile.
        IF NOT FILE-INFO:FILE-TYPE MATCHES "*F*" THEN
        DO:
            MESSAGE "Result xml file was not found in results directory. The test might not have run, hence aborting".
            
            DO TRANSACTION:
                FIND  ClientSessions WHERE ClientSessions.sessionguid = sessionid EXCLUSIVE-LOCK.
                ASSIGN
                    ClientSessions.endTime = NOW.
                ClientSessions.SessionStatus = "Aborted".
                
                VALIDATE ClientSessions.
            END.
            RETURN ERROR "Aborting the test as result xml file not found".
        END.
        
        
        hdl:READ-XML("file", resultsDir + "/" + sessionid + ".xml","empty","",?,?,?).

        JObj:Read(hdl).


        DatasetObj = JObj:GetJsonObject("NewDataSet").

        testsuitesArr = DatasetObj:GetJsonArray("testsuites").

        
        IF (int(testsuitesArr:GetJsonObject(1):GetCharacter("errors")) NE 0) OR (int(testsuitesArr:GetJsonObject(1):GetCharacter("failures")) NE 0) THEN
            teststatus = "FAILED".
        ELSE 
            teststatus = "PASSED".
        
        
        DO TRANSACTION ON ERROR UNDO, LEAVE:
           
            FIND  ClientSessions WHERE RECID(ClientSessions) = rec_id EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            
            if available ClientSessions then 
            do:
                ASSIGN 
                    ClientSessions.endTime         = NOW
                    ClientSessions.SessionStatus = "Completed"
                    ClientSessions.execTime      = INTERVAL(ClientSessions.endTime,ClientSessions.startTime,'milliseconds')
                    ClientSessions.testStatus    = teststatus
                    ClientSessions.testcases     = STRING(testsuitesArr:GetJsonObject(1):GetCharacter("tests")).
            
                VALIDATE ClientSessions.
            end.
            else 
            do:
                message "Record is locked or not available".
                return error "Record is locked or not available".
                
            end.
        END.
        
        CATCH ValidateResults AS Progress.Lang.Error :
            MESSAGE "Failed in ValidateResults".
            MESSAGE ValidateResults:CallStack.
            MESSAGE ValidateResults:GetMessage(1).
        END CATCH.
        
        FINALLY:
            

            DELETE OBJECT   JObj.
            DELETE OBJECT  DatasetObj.
            DELETE OBJECT testsuitesArr.

        END FINALLY.    
        
    END METHOD.
    
    
    /*
            
        Generate configjson for ABLUnit
    */
    
    METHOD PUBLIC JSONObject GenABLUnitInput(INPUT poEntity AS JSONObject,INPUT sessguid AS CHARACTER,INPUT resultsDir AS CHARACTER):
        
        DEFINE VARIABLE PostDataJson   AS JsonObject NO-UNDO.
        DEFINE VARIABLE ABLUnitJsonArr AS JSonArray  NO-UNDO.
        DEFINE VARIABLE configJSON     AS JsonObject NO-UNDO.
        DEFINE VARIABLE Jobj1          AS JSOnObject NO-UNDO.
        DEFINE VARIABLE JobjOutput     AS JsonObject NO-UNDO.
        DEFINE VARIABLE tests          AS JsonObject NO-UNDO.
        DEFINE VARIABLE testArr        AS JsonArray  NO-UNDO.
        
        PostDataJson = NEW JsonObject().
        ABLUnitJsonArr = NEW JsonArray().
        configJSOn = NEW JsonObject().
        testArr = NEW JSonArray().
        
        ABLUnitJsonArr = CAST(poEntity:GetJsonArray("ABLUnit"),JsonArray).
        tests = CAST(ABLUnitJsonArr:GetJsonObject(1),JSONObject).
        testArr = tests:GetJsonArray("tests").
        
      
        JObj1 = NEW JsonObject().
        JObjOutput = NEW JsonObject().
        tests = NEW JsonObject().

        JObj1:Add("location",resultsDir).
        JObj1:Add("fileName",sessguid).
        JObj1:Add("format","xml").


        JObjOutput:Add("output",Jobj1).
        JObjOutput:Add("quitOnEnd",TRUE).
        JObjOutput:Add("showErrorMessage",TRUE).
       
        configJson:Add("options",JObjOutput).
        configJson:Add("tests",testArr).
        
        RETURN configJson.
    
        CATCH GetABLUnitException AS Progress.Lang.Error :
           
            DO TRANSACTION:  
                FIND  ClientSessions WHERE ClientSessions.sessionguid = sessguid EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                ASSIGN
                    ClientSessions.endTime = NOW.
                ClientSessions.SessionStatus = "Aborted".
            
                MESSAGE GetABLUnitException:CallStack.
                MESSAGE GetABLUnitException:GetMessage(1).
            
                MESSAGE "Failed in GetABLUnitException".
                return error "Failed in GetABLUnitException ".
            END.
        END CATCH.
    
    END METHOD.
    
    

END CLASS.
