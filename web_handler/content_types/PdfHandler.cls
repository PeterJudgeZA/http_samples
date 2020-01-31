/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : PdfHandler
    Description : 
    Author(s)   : pjudge
    Created     : 2020-01-31
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Web.IWebRequest.
using OpenEdge.Web.WebHandler.
using OpenEdge.Web.WebResponseWriter.

class PdfHandler inherits WebHandler: 

    method override protected integer HandleNotAllowedMethod( input poRequest as IWebRequest ):
        return integer(OpenEdge.Net.HTTP.StatusCodeEnum:MethodNotAllowed).
    end method.

    method override protected integer HandleNotImplemented( input poRequest as IWebRequest ):
        return integer(OpenEdge.Net.HTTP.StatusCodeEnum:NotImplemented).
    end method.
    
    /*------------------------------------------------------------------------------
            Purpose: Default handler for the HTTP GET method. The request being 
                     serviced and an optional status code is returned. A zero or 
                     null value means this method will deal with all errors.
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
     method override protected integer HandleGet( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable oResponse as OpenEdge.Net.HTTP.IHttpResponse no-undo.
        define variable oWriter   as OpenEdge.Web.WebResponseWriter  no-undo.
        define variable oBody     as OpenEdge.Core.Memptr no-undo.
        define variable pdfData as memptr no-undo.
            
        /* The WebResponse body is a wrapper around an entire HTTP response message.
           It contains a status code and reason; headers; cookies and a message body.
           
           API-level doc for this and related classes can be found at
           https://documentation.progress.com/output/oehttpclient/      */
        assign 
            oResponse            = new OpenEdge.Web.WebResponse()
            oResponse:StatusCode = integer(OpenEdge.Net.HTTP.StatusCodeEnum:OK)
            .
        
        copy-lob from file 'README.pdf' to pdfData.
        
        /* This body object can be a string or something else (JsonObject for instance) */
        assign oResponse:Entity        = new OpenEdge.Core.Memptr(pdfData)
               /* HTTP messages require a content type */
               oResponse:ContentType   = 'application/pdf':u
               oWriter = new WebResponseWriter(oResponse)
               .
        oWriter:Open().
        oWriter:Close().
        
        /* A response of 0 means that this handler will build the entire response;
           a non-zero value is mapped to a static handler in the webapp's /static/error folder.
           The mappings are maintained in the webapps's WEB-INF/web.xml 
           A predefined set of HTTP status codes is provided in the OpenEdge.Net.HTTP.StatusCodeEnum 
           enumeration */
        return 0.
     end method. 
     
    method override protected integer HandlePut( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable oBody     as OpenEdge.Core.Memptr no-undo.
        define variable pdfData as memptr no-undo.
        
        if    poRequest:ContentType eq 'application/pdf' 
           or type-of(poRequest:Entity, OpenEdge.Core.Memptr)
        then
            pdfData = cast(poRequest:Entity, OpenEdge.Core.Memptr):Value.
        
        // do something with the PDF
        
        // build and return a response 
        
        return 0.
      end method.
    
end class.