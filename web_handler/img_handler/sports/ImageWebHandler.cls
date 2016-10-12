/*------------------------------------------------------------------------
    File        : ImageWebHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Fri Sep 04 11:23:36 EDT 2015
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.ByteBucket.
using OpenEdge.Core.Memptr.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using OpenEdge.Net.HTTP.Filter.Writer.BodyWriterBuilder.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterBuilder.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.HttpHeaderBuilder.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.StatusCodeEnum.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MultipartEntity.
using OpenEdge.Web.IWebRequest.
using OpenEdge.Web.WebHandler.
using OpenEdge.Web.WebResponse.
using OpenEdge.Web.WebResponseWriter.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.
using Progress.Lang.Error.
using sports.EmployeeBE.

class sports.ImageWebHandler inherits WebHandler:
    define private variable moBE as EmployeeBE no-undo.
        
    constructor public ImageWebHandler ():
        assign moBE = new EmployeeBE().
    end constructor.

	method override protected integer HandleNotAllowedMethod( input poRequest as OpenEdge.Web.IWebRequest ):
		return integer(StatusCodeEnum:MethodNotAllowed).
	end method.

	method override protected integer HandleNotImplemented( input poRequest as OpenEdge.Web.IWebRequest ):
		return integer(StatusCodeEnum:NotImplemented).
	end method.

    /* Handles an exception that has been raised while dealing with the request 
    
       @param Progress.Lang.Error The as-yet-unhandled exception
       @param IWebRequest The request that resulting in the exception
       @return integer A non-null status code use to deal with errors */
    method override protected integer HandleException(input poError as Progress.Lang.Error,
                                                      input poRequest as IWebRequest):
        define variable oResp as IHttpResponse no-undo.
        define variable oException as JsonObject no-undo.
        
        assign oResp = new WebResponse()
               oResp:StatusCode  = 500
               oResp:ContentType = 'application/json':u
               oException = WriteError(poError)
               oResp:Entity = oException.               
        oException:Add('req':u, substitute('&1 &2':u, poRequest:Method, poRequest:URI:Path)).
        
        WriteResponse(oResp).
        
        return 0.
    end method.
    
    method private JsonObject WriteError(input poError as Error):
        define variable oResponse as JsonObject no-undo.
        define variable oError as JsonObject no-undo.
        define variable oErrorList as JsonArray no-undo.
        define variable iLoop as integer no-undo.
        define variable cRetVal as character no-undo.
        define variable iMax as integer no-undo.

        assign oResponse  = new JsonObject()
               oError     = new JsonObject()
               oErrorList = new JsonArray().
        
        oResponse:Add('ver':u, '0.1.0').
        oResponse:Add('type':u, poError:GetClass():TypeName).
        oResponse:Add('origin':u, oErrorList).
        
        oErrorList:add(program-name(3)).
        
        if type-of(poError, AppError) then
            oResponse:Add('retVal':u, cast(poError, AppError):ReturnValue).
        
        assign oErrorList = new JsonArray().
        oResponse:Add('err':u, oErrorList).
        do iLoop = 1 to poError:NumMessages:
            assign oError = new JsonObject().
            oErrorList:Add(oError).
            
            oError:Add('_errorMsg':u, poError:GetMessage(iLoop)).
            oError:Add('_errorNum':u, poError:GetMessageNum(iLoop)).
        end.
        
        oResponse:WriteFile(session:temp-dir + 'error.json', true).
        
        return oResponse.
    end method.
    
    method override protected integer HandleHead( input poRequest as IWebRequest):
        define variable iEmpNum as integer no-undo.
        
        define variable cFilename as character no-undo.
        define variable oPic as class Memptr no-undo.
        define variable oResp as IHttpResponse no-undo.
        
        /* URL is /web/img/Employee/{EmpNum} */
        iEmpNum = integer(poRequest:GetPathParameter('EmpNum':u)).
        oPic = moBE:ReadEmployeePic(iEmpNum, output cFilename).
        
        oResp = new WebResponse().
        if oPic:size eq 0 then
            oResp:StatusCode = 404.
        else
        do:    
            oResp:StatusCode = 200.
            oResp:ContentType = 'image/png':u.
            oResp:ContentLength = oPic:Size.
            oResp:SetHeader(HttpHeaderBuilder:Build('Content-Disposition':u)
                            :Value(substitute('attachment; filename=&1':u, quoter(cFilename)))
                            :Header).
        end.

        WriteResponse(oResp).
        
        return integer(StatusCodeEnum:None).
    end method.
    
    method override protected integer HandleGet( input poRequest as IWebRequest):
        define variable iEmpNum as integer no-undo.
        define variable cFilename as character no-undo.
        define variable oPic as class Memptr no-undo.
        define variable oResp as IHttpResponse no-undo.
        define variable oHeader as HttpHeader no-undo.
        define variable oEntity as MultipartEntity no-undo.
        define variable oPart as MessagePart no-undo.
        
        /* URL is /web/img/Employee/{EmpNum} */
        iEmpNum = integer(poRequest:GetPathParameter('EmpNum':u)).

        assign oPic = moBE:ReadEmployeePic(iEmpNum, output cFilename)
               oResp = new WebResponse().
        
        if oPic:size eq 0 then
            assign oResp:StatusCode = 404
                   oResp:StatusReason = 'Employee image not found'.
        else
        do:
            assign oResp:StatusCode = 200.
            
            if poRequest:HasHeader('Accept':u) and
               poRequest:GetHeader('Accept':u):Value eq 'multipart/form-data':u then
            do:
                assign oEntity = new MultipartEntity()
                       oEntity:Boundary = guid
                       
                       oResp:Entity      = oEntity
                       oResp:ContentType = 'multipart/form-data':u
                       
                       oPart = new MessagePart('image/png':u, oPic)
                       
                       oHeader = HttpHeaderBuilder:Build('Content-Disposition':u)
                                    :Value(substitute('form-data; name="fileContents"; filename=&1':u, quoter(cFilename)))
                                    :Header.

                oEntity:AddPart(oPart).
                oPart:Headers:Put(oHeader).
            end.
            else
            do:
                assign oResp:Entity      = oPic
                       oResp:ContentType = 'image/png':u
                       oHeader = HttpHeaderBuilder:Build('Content-Disposition':u)
                                    :Value(substitute('attachment; filename=&1':u, quoter(cFilename)))
                                    :Header.

                /* don't set the size so that we can chunk this response */
                oResp:SetHeader(oHeader).
            end.
        end.
        
        WriteResponse(oResp).
        
        return integer(StatusCodeEnum:None).
    end method.

    method private void WriteResponse(input poResp as IHttpResponse):
        define variable oWriter as WebResponseWriter no-undo.
        define variable oCTWriter as MessageWriter no-undo.
        define variable oBytes as ByteBucket no-undo.
        define variable mEntity as memptr no-undo. 
                  
        /* dump to stream */
        oWriter = new WebResponseWriter(poResp).
        oWriter:Open().
        
        /* Convert from an image to bytes */
        if valid-object(poResp:Entity) then
        do on error undo, throw:         
            oCTWriter = BodyWriterBuilder:Build(poResp):Writer.
             
            oCTWriter:Open().
            oCTWriter:Write(poResp:Entity).
            oCTWriter:Close().
             
            oBytes = cast(oCTWriter:Entity, ByteBucket).
            
            mEntity = oBytes:GetBytes():value.
            
            poResp:ContentLength = get-size(mEntity).
            oWriter:Write(mEntity).
            
            catch e as Progress.Lang.Error :
                message e:getmessage(1).
                message e:callstack.
            end catch.
            finally:
                set-size(mEntity) = 0.
            end finally.
        end.
        
        oWriter:Close().
    end method.
    
    method override protected integer HandleDelete( input poRequest as IWebRequest):
        define variable oResp as IHttpResponse no-undo.
        define variable iEmpNum as integer no-undo.
        define variable lRemoved as logical no-undo.
        
        /* URL is /web/img/Employee/{EmpNum} */
        assign iEmpNum = integer(poRequest:GetPathParameter('EmpNum':u))
               lRemoved = moBE:RemoveEmployeePic(iEmpNum).
        
        /* update */
        assign oResp = new WebResponse().
        
        if lRemoved then
            assign oResp:StatusCode = 200.
        else
            assign oResp:StatusCode = 404.
        
        WriteResponse(oResp).
        
        return integer(StatusCodeEnum:None).
    end method.
    
    method override protected integer HandlePut( input poRequest as IWebRequest):
        define variable oResp as IHttpResponse no-undo.
        
        /* update */
        assign oResp = new WebResponse()
               oResp:StatusCode  = 200.
               
        WriteImage(poRequest, oResp).               
        WriteResponse(oResp).
        
        return integer(StatusCodeEnum:None).
    end method.
    
    method private void WriteImage(input poRequest as IWebRequest,
                                   input poResponse as IHttpResponse):
        define variable iEmpNum as integer no-undo.
        define variable oEntity as MultipartEntity no-undo.
        define variable oPart as MessagePart no-undo.
        define variable oEntityWriter as MessageWriter no-undo.
        define variable oHeader as HttpHeader no-undo.
        define variable cImageFileName as character no-undo.
        
        oHeader = poRequest:GetHeader('Content-Type').
        oHeader:ParamDelimiter = ';':u.
        oHeader:ExtractParameters().
                                           
        /* URL is /web/img/Employee/{EmpNum} */
        assign iEmpNum = integer(poRequest:GetPathParameter('EmpNum':u))
               oEntityWriter = EntityWriterBuilder:Build(poRequest)
                                :Option('multipartBoundary':u, oHeader:GetParameterValue('boundary':u))                                
                                :Writer.
        oEntityWriter:Open().
        oEntityWriter:Write(poRequest:Entity).
        oEntityWriter:Close().
        
        assign oEntity = cast(oEntityWriter:Entity, MultipartEntity)
               oPart   = oEntity:GetPart(1)
               oHeader = oPart:Headers:Get('Content-Disposition':u)
               
               /* Content-Disposition: form-data; name="myphoto.png"; filename="emp_21.png" */
               cImageFileName = oHeader:GetParameterValue('filename':u).

        moBE:WriteEmployeePic(iEmpNum, 
                              cImageFileName, 
                              cast(oPart:Body, ByteBucket):GetBytes()).
    end method.
    
    method override protected integer HandlePost( input poRequest as IWebRequest):
        define variable oResp as IHttpResponse no-undo.
        
        /* update */
        assign oResp = new WebResponse()
               oResp:StatusCode  = 201.
               
        WriteImage(poRequest, oResp).
        WriteResponse(oResp).
        
        return integer(StatusCodeEnum:None).
    end method.
    
end class.