/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
   File        : RequestEchoHandler
   Purpose     : A handler that returns what was sent to it as JSON
   Description : 
   Author(s)   : pjudge
   Created     : 2018-02-27
   Notes       : * Modelled after httpbin.org
 ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.ByteBucket.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using OpenEdge.Net.HTTP.Cookie.
using OpenEdge.Net.HTTP.Filter.Payload.BinaryEntityWriter.
using OpenEdge.Net.HTTP.Filter.Payload.JsonEntityWriter.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using OpenEdge.Net.HTTP.Filter.Payload.StringEntityWriter.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterBuilder.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.NullHeader.
using OpenEdge.Net.HTTP.StatusCodeEnum.
using OpenEdge.Net.ISupportEncoding.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MimeTypeHelper.
using OpenEdge.Net.MultipartEntity.
using OpenEdge.Web.IWebRequest.
using OpenEdge.Web.WebRequest.
using OpenEdge.Web.WebResponse.
using OpenEdge.Web.WebResponseWriter.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.Object.
using Progress.Web.IWebHandler.

class RequestEchoHandler implements IWebHandler: 
    /* Processes/handles an exception
       
       @param Progress.Lang.Error The error/exception being processed
       @param IHttpResponse The current response. May be incomplete
       @return integer ZERO or a HTTP status code to indicate an error */
    method protected integer HandleException( input poError as Progress.Lang.Error, input pResponse as IHttpResponse):
        define variable jew as JsonEntityWriter no-undo.
        define variable writer as WebResponseWriter no-undo.
        
        assign pResponse:StatusCode  = integer(StatusCodeEnum:InternalServerError)
               pResponse:ContentType = 'application/json':u.
        
        // Convert error into JSON for return
        jew = new JsonEntityWriter().
        jew:Open().
        jew:Write(poError).
        jew:Close().
        
        cast(pResponse:Entity, JsonObject):Add('error':u, cast(jew:Entity, JsonObject)).
        
        writer = new WebResponseWriter(pResponse).
        writer:Open().
        writer:Close().
        
        return 0.
    end method.
    
    /* Handles an HTTP request
       
       @return integer ZERO or a HTTP status code to indicate an error */
    method public integer HandleRequest():
        define variable req    as IWebRequest       no-undo.
        define variable res    as IHttpResponse     no-undo.
        define variable writer as WebResponseWriter no-undo.
        
        assign req    = new WebRequest()
               res    = new WebResponse()
               writer = new WebResponseWriter(res)
               .
        WriteRequest(req, res).
        
        writer:Open().
        writer:Close().
        
        return 0.
        catch e as Progress.Lang.Error:
            return HandleException(e, res). 
        end catch.
    end method.
    
    method protected void WriteRequest(input pReq as IWebRequest,
                                       input pResp as IHttpResponse):
        define variable data as JsonObject no-undo.
        define variable childArray as JsonArray no-undo.
        define variable childObject as JsonObject no-undo.
        define variable childData as JsonObject no-undo.
        define variable headerData as JsonObject no-undo.
        define variable cnt as integer no-undo.
        define variable loop as integer no-undo.
        define variable hdr as HttpHeader extent no-undo.
        define variable cookie as Cookie extent no-undo.
        define variable ew as MessageWriter no-undo.
        define variable names as character extent no-undo.
        define variable mpEntity as MultipartEntity no-undo.
        define variable msgPart as MessagePart no-undo.
        define variable msgBody as Progress.Lang.Object no-undo.
        define variable showCgi as logical no-undo.
        define variable partData as memptr no-undo.
        
        if not valid-object(pResp) then
            assign pResp = new WebResponse().
        
        assign pResp:ContentType = 'application/json':u
               data              = new JsonObject()
               pResp:Entity      = data
               .
        data:Add('method':u, pReq:Method).
        data:Add('uri':u, pReq:URI:ToString()).
        data:Add("origin":u, pReq:RemoteHost).
        
        // URI template & path parameters
        assign childObject  = new JsonObject()
               cnt           = num-entries(pReq:PathParameterNames)
               extent(names) = 1
               .
        data:Add('pathParameters':u, childObject).
        do loop = 1 to cnt:
            assign names[1] = trim(entry(loop, pReq:PathParameterNames)).
            childObject:Add(names[1], pReq:GetPathParameter(names[1])). 
        end.
        
        assign childObject   = new JsonObject()
               extent(names) = ?
               showCgi       = false 
               .
        data:Add('args', childObject).
        pReq:URI:GetQueryNames(output names).
        do cnt = extent(names) to 1 by -1:
            if names[cnt] eq 'debug':u then
                assign showCgi = true.
            
            childObject:Add(names[cnt], pReq:URI:GetQueryValue(names[cnt])).
        end.
        
        pReq:GetHeaders(output hdr). 
        assign childObject= new JsonObject().
        data:Add('headers', childObject).
        
        do cnt = extent(hdr) to 1 by -1:
            childObject:Add(hdr[cnt]:Name,
                            string(substitute('&1&2':u,
                                        hdr[cnt]:GetBaseValue(),
                                        hdr[cnt]:GetParameterValues()))).
        end.
        
        pReq:GetCookies(output cookie).
        assign childObject = new JsonObject().
        
        data:Add('cookies', childObject).
        do cnt = extent(cookie) to 1 by -1:
            childObject:Add(cookie[cnt]:Name, cookie[cnt]:ToString()).
        end.
        
        assign ew = EntityWriterBuilder:Build(pReq):Writer.
        if not valid-object(ew) then
            data:Add('data':u, new JsonObject()).
        else
        do:
            ew:Open().
            ew:Write(pReq:Entity).
            ew:Close().
            
            assign msgBody = ew:Entity.
            
            // Stringify the body
            Stringify('data':u, pReq:ContentType, pReq:Entity, data).
            
            assign childObject = new JsonObject().
            data:Add('form', childObject).
            
            if MimeTypeHelper:IsMultipart(pReq:ContentType) then
            do:
                assign mpEntity      = cast(msgBody, MultipartEntity)
                       extent(names) = ?
                       extent(names) = 1
                       .
                do cnt = 1 to mpEntity:Size:
                    assign extent(hdr) = ?
                           names[1]    = '':u
                           msgPart     = mpEntity:GetPart(cnt)
                           childData   = new JsonObject()
                           headerData  = new JsonObject().
                           .
                    childData:Add('headers', headerData).
                    
                    msgPart:Headers:GetAll(output hdr).
                    
                    do loop = extent(hdr) to 1 by -1:
                        if hdr[loop]:Name eq 'Content-Disposition':u then
                            assign names[1] = hdr[loop]:GetParameterValue('name':u).
                        
                        headerData:Add(hdr[loop]:Name,
                                        string(substitute('&1&2':u,
                                                    hdr[loop]:GetBaseValue(),
                                                    hdr[loop]:GetParameterValues()))).
                    end.
                    
                    if String:IsNullOrEmpty(names[1]) then
                        assign names[1] = 'part.':u + string(cnt).
                    else
                    if String:IsQuoted(names[1], StringConstant:DOUBLE_QUOTE) then
                        assign names[1] = trim(names[1], StringConstant:DOUBLE_QUOTE).
                    
                    // Stringify the part body
                    Stringify('data':u, msgPart:ContentType, msgPart:Body, childData).
                    
                    childObject:Add(names[1], childData).
                end. 
            end.
        end.
        
        if showCgi then
        do:
            assign childObject   = new JsonObject()
                   extent(names) = ?
                   extent(names) = 1
                   names[1] = web-context:get-cgi-list('ENV':u)
                   .
            data:Add('cgi.ENV', childObject).
            do cnt = num-entries(names[1]) to 1 by -1:
                childObject:Add(entry(cnt, names[1]), 
                                web-context:get-cgi-value('ENV':u, entry(cnt, names[1]))).
            end.
            
            assign childObject   = new JsonObject()
                   extent(names) = ?
                   extent(names) = 1
                   names[1] = web-context:get-cgi-list('FORM':u)
                   .
            data:Add('cgi.FORM', childObject).
            do cnt = num-entries(names[1]) to 1 by -1
            on error undo, throw:
                assign partData = web-context:get-binary-data(entry(cnt, names[1])) no-error.
                
                if get-size(partData) eq 0 then
                    childObject:Add(entry(cnt, names[1]), 
                                    web-context:get-cgi-value('FORM':u, entry(cnt, names[1]))).
                else
                do:
                    childData = new JsonObject().
                    childObject:Add(entry(cnt, names[1]), childData).
                    
                    childData:Add("fileName", web-context:get-cgi-value('FORM':u, entry(cnt, names[1]))).
                    childData:Add("bytes", get-size(partData)).
                end.
                finally:
                    set-size(partData) = 0.
                end finally.
            end.
            
            assign childObject   = new JsonObject()
                   extent(names) = ?
                   extent(names) = 1
                   names[1] = web-context:get-cgi-list('QUERY':u)
                   .
            data:Add('cgi.QUERY', childObject).
            do cnt = num-entries(names[1]) to 1 by -1:
              childObject:Add(entry(cnt, names[1]), 
                              web-context:get-cgi-value('QUERY':u, entry(cnt, names[1]))).
            end.
        end.
    end method.
    
    /* Turns the request's body/entity and any message parts into strings. It first tries using the StringEntityWriter;
       if that fails, then it tries to base64-encode a binary version. If that fails, an error is thrown.
       
       If base64-encoded data is used, the entity is encoded using https://en.wikipedia.org/wiki/Data_URI_scheme  
       which results in a string : "data:<content-type>;base64,<base64-encoded-data>"
       
       @param character The name of the field, or 'data' for the whole body 
       @param character The original content type of the data
       @param Progress.Lang.Object The data to stringify
       @param JsonObject The parent JSON object under add the stringified data */
    method protected void Stringify(input pName as character,
                                    input pContentType as character,
                                    input pData as Object,
                                    input pParent as JsonObject):
        define variable ew as MessageWriter no-undo.
        define variable stringData as longchar no-undo.
        
        // Stringify the data 
        assign ew = new StringEntityWriter().
        
        // Use UTF-8 since we're returning JSON
        if type-of(ew, ISupportEncoding) then            
            assign cast(ew, ISupportEncoding):Encoding = 'UTF-8':u.
        
        ew:Open().
        ew:Write(pData).
        ew:Close().
        
        pParent:Add(pName, cast(ew:Entity, String):Value).
        
        catch ewErr as Progress.Lang.Error:
            assign ew = new BinaryEntityWriter().
            
            ew:Open().
            ew:Write(pData).
            ew:Close().
            
            fix-codepage(stringData) = 'UTF-8':u.
            assign stringData = substitute('data:&1;base64,':u, entry(1, pContentType, ';':u))
                              + base64-encode(cast(ew:entity, ByteBucket):GetBytes():Value).
            
            pParent:Add(pName, stringData). 
        end catch.
    end method.
    
end class.