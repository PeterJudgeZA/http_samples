/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : Employee
    Syntax      : 
    Author(s)   : pjudge
    Created     : Fri Sep 04 11:14:26 EDT 2015
    Notes       : 
  ----------------------------------------------------------------------*/
  
@program FILE(name="Employee.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="EmployeeBE", URI="/Employee", schemaName="dsEmployee", schemaFile="SportsSvc/src/sports/EmployeeBE.cls").


block-level on error undo, throw.

using OpenEdge.BusinessLogic.BusinessEntity from propath.
using OpenEdge.Core.Memptr from propath.
using OpenEdge.Core.SerializationFormatEnum from propath.
using OpenEdge.Net.MediaLinkEntity from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Json.ObjectModel.ObjectModelParser.

class sports.EmployeeBE inherits BusinessEntity:
	{sports/EmployeeBE.i}
	
    /* using a static here because this JsonObject is basically a DB emulation */
    define static private variable moImageMap as JsonObject no-undo.
    define static private variable mcImageFolder as character no-undo.
        
	define data-source srcEmployee for Employee.
	
	constructor static EmployeeBE():
     	assign mcImageFolder = os-getenv ('CATALINA_BASE') + '/openedge/resources':u.         
        if search(mcImageFolder + '/emp_img_map.json':u) ne ? then
            moImageMap = cast((new ObjectModelParser():ParseFile(mcImageFolder + '/emp_img_map.json':u)), JsonObject).
        else
            moImageMap = new JsonObject().
    end constructor.
    
    constructor public EmployeeBE():
    	define var hDataSourceArray as handle no-undo extent 1.
        define var cSkipListArray as char no-undo extent 1.
        
        super (dataset dsEmployee:handle).
                
        /* Data Source for each table in dataset. Should be in table order as defined 
     	   in dataset */     
     	hDataSourceArray[1] =  data-source srcEmployee:handle.
     	     	
     	/* Skip-list entry for each table in dataset. Should be in temp-table order 
           as defined in dataset */
        /* Each skip-list entry is a comma-separated list of field names, to be
 	       ignored in create stmt */
     	    
     	cSkipListArray[1] = "".
     	
     	this-object:ProDataSource = hDataSourceArray.
        this-object:SkipList = cSkipListArray.
    end constructor.
    
    destructor EmployeeBE():
        moImageMap:WriteFile(mcImageFolder + '/emp_img_map.json':u, true).        
    end destructor.
    
    /*------------------------------------------------------------------------------
            Purpose:  Get one or more records, based on a filter string                                                                     
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json"). 
    method public void ReadEmployee(input filter as character, output dataset dsEmployee):
    	super:ReadData(filter).
    	    	
    	AddMLE(input-output table ttEmployee by-reference).
    end method.
    
    /*------------------------------------------------------------------------------
            Purpose: Create one or more new records                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/  
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="create", URI="", alias="", mediaType="application/json").
    method public void CreateEmployee(input-output dataset dsEmployee):    		
        super:CreateData(dataset dsEmployee by-reference).
        
        AddMLE(input-output table ttEmployee by-reference).
    end method.    
	
    /*------------------------------------------------------------------------------
            Purpose:  Update one or more records                                                                  
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="update", URI="", alias="", mediaType="application/json").
    method public void UpdateEmployee(input-output dataset dsEmployee):    		
        super:UpdateData(dataset dsEmployee by-reference).
        
        AddMLE(input-output table ttEmployee by-reference).
    end method.
	
    /*------------------------------------------------------------------------------
            Purpose:    Delete a record                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="delete", URI="", alias="", mediaType="application/json").
    method public void DeleteEmployee(input-output dataset dsEmployee):
        for each ttEmployee:
            RemoveEmployeePic(ttEmployee.EmpNum).
        end.
        
        super:DeleteData(dataset dsEmployee by-reference).
        
        AddMLE(input-output table ttEmployee by-reference).
    end method.
    
    /*------------------------------------------------------------------------------
            Purpose:    Submit a record                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/SubmitEmployee (IN-OUT dataset)", alias="", mediaType="application/json").
    method public void SubmitEmployee(input-output dataset dsEmployee):
      	super:Submit(dataset dsEmployee by-reference).
      	
      	AddMLE(input-output table ttEmployee by-reference).
    end method.
    
    method public class Memptr ReadEmployeePic(input  piEmpNum as integer,
                                               output pcFilename as character):
        define variable mImg as memptr no-undo.
        
        if moImageMap:Has(string(piEmpNum)) and
           not moImageMap:IsNull(string(piEmpNum)) then
        do:
            assign pcFilename = moImageMap:GetCharacter(string(piEmpNum)).
            
            if search(mcImageFolder + '/':u + pcFilename) ne ? then
                copy-lob from file mcImageFolder + '/':u + pcFilename to mImg.
            else
            do:
                assign pcFilename = '':u.
                return new Memptr(0).
            end.
        end.
        else
            return new Memptr(0).
            
        return new Memptr(mImg).            
        
        finally:
            set-size(mImg) = 0.
        end finally. 
    end method.
    
    method public void WriteEmployeePic(input piEmpNum as integer, 
                                        input pcFilename as character,
                                        input poImg as class memptr):
        if moImageMap:Has(string(piEmpNum)) then
            moImageMap:Set(string(piEmpNum), pcFilename).
        else
            moImageMap:Add(string(piEmpNum), pcFilename).
        
        copy-lob from poImg:Value to file mcImageFolder + '/':u + pcFilename.
        
        // for others' use        
        moImageMap:WriteFile(mcImageFolder + '/emp_img_map.json':u, true).
    end method.
    
    /* @return logical TRUE if the image was removed, false otherwise */
    method public logical RemoveEmployeePic(input piEmpNum as integer):
        define variable cFile as character no-undo.
        
        // no-op if nothing's there
        if not moImageMap:Has(string(piEmpNum)) or
           moImageMap:IsNull(string(piEmpNum)) then
            return false.
        
        assign cFile = mcImageFolder + '/':u + moImageMap:GetCharacter(string(piEmpNum)).
         
        moImageMap:SetNull(string(piEmpNum)).

        os-delete value(cFile).
        
        // for others' use        
        moImageMap:WriteFile(mcImageFolder + '/emp_img_map.json':u, true).
        
        return true.
        catch oError as Progress.Lang.Error :
            /* assume an error caused the delete to fail */
            return false.
        end catch.
    end method.
    
    method private void AddMLE(input-output table ttEmployee):
        define variable oMLE as MediaLinkEntity no-undo.
        
        for each ttEmployee:
            assign oMLE = new MediaLinkEntity()            
                   oMLE:EditUrl = '/web/img/Employee/' + string(ttEmployee.EmpNum)  
                   .
            if moImageMap:Has(string(ttEmployee.EmpNum)) and
               not moImageMap:IsNull(string(ttEmployee.EmpNum)) then
                assign oMLE:ReadUrl = '/web/img/Employee/' + string(ttEmployee.EmpNum).
            
            assign ttEmployee.EmpPhoto = oMLE:Serialize(SerializationFormatEnum:Json).
        end. 
    end method.
    
end class.
