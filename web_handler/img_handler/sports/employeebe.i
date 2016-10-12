
 /*------------------------------------------------------------------------
    File        : EmployeeBE
    Purpose		:
    Syntax      : 
    Description :
    Author(s)   : pjudge
    Created     : Fri Sep 04 11:14:26 EDT 2015
    Notes       : 
  ----------------------------------------------------------------------*/
  
  /** Dynamically generated schema file **/
   
@openapi.openedge.entity.primarykey (fields="EmpNum").

/* Media Link Fields */
    /* mandatory annotations */
    @openapi.openedge.entity.field.property(field="EmpPhoto", name="type", value="mr.image").
    @openapi.openedge.entity.field.property(field="EmpPhoto", name="format", value="string-json").

    /* optional annotations */
    @openapi.openedge.entity.field.property(field="EmpPhoto", name="contentEncoding", value="binary").
    @openapi.openedge.entity.field.property(field="EmpPhoto", name="readOnly", value="false").

DEFINE TEMP-TABLE ttEmployee BEFORE-TABLE bttEmployee
    FIELD EmpNum           AS INTEGER   INITIAL "0" LABEL "Emp No"
    FIELD LastName         AS CHARACTER LABEL "Last Name"
    FIELD FirstName        AS CHARACTER LABEL "First Name"
    FIELD Birthdate        AS DATE      INITIAL "?" LABEL "Birthdate"
    FIELD StartDate        AS DATE      INITIAL "?" LABEL "Start Date"
    
    /* used to return the MLE for the employee photo */
    field EmpPhoto as character        
    
    INDEX EmpNo IS PRIMARY UNIQUE EmpNum   ASCENDING 
    INDEX Name IS UNIQUE          LastName ASCENDING FirstName ASCENDING . 


DEFINE DATASET dsEmployee FOR ttEmployee.