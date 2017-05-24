/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : RedirectWebHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Mon Feb 27 09:48:06 EST 2017
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.ByteBucket.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using OpenEdge.Net.HTTP.Filter.Writer.BodyWriterBuilder.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.StatusCodeEnum.
using OpenEdge.Net.URI.
using OpenEdge.Web.IWebRequest.
using OpenEdge.Web.WebHandler.
using OpenEdge.Web.WebRequest.
using OpenEdge.Web.WebResponse.
using OpenEdge.Web.WebResponseWriter.

class RedirectWebHandler inherits WebHandler: 
    
    method override public integer HandleRequest():
        define variable webRequest as IWebRequest no-undo.
        define variable webResponse as WebResponse no-undo.
        define variable responseWriter as WebResponseWriter no-undo.
        define variable location as URI no-undo.
        
        assign webRequest = new WebRequest()
               
               webResponse = new WebResponse()
               webResponse:StatusCode = integer(OpenEdge.Net.HTTP.StatusCodeEnum:Found)
               
               location = URI:Parse(substitute('http://example.com/&1?&2',
                                        webRequest:URI:Path,
                                        webRequest:URI:QueryString))               
               .
        this-object:Logger:Info(substitute('&1 redirected to &2',
                                    webRequest:URI:ToString(),
                                    location:ToString())).
        
        webResponse:SetHeader('Location':u, location:ToString()). 

        responseWriter = new WebResponseWriter(webResponse).
        responseWriter:Open().
        responseWriter:Close().
                
        return 0.
    end method. 

    /* Default handler for unsupported methods
       
       @param IWebRequest The request being serviced 
       @return integer An optional status code. A zero or null value means this method will deal with all errors */
    method override protected integer HandleNotAllowedMethod(input poRequest as IWebRequest):
        return integer(StatusCodeEnum:MethodNotAllowed).
    end method.
    
    /* Default handler for unknown methods
       
       @param IWebRequest The request being serviced 
       @return integer An optional status code. A zero or null value means this method will deal with all errors */
    method override protected integer HandleNotImplemented(input poRequest as IWebRequest):
        return integer(StatusCodeEnum:NotImplemented).
    end method.
    
end class.