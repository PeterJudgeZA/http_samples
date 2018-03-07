/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any pburpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : NamedFile
    Description : 
    Author()   : pjudge
    Created     : Thu Mar 01 12:27:27 EST 2018
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Memptr.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.HttpHeaderBuilder.
using Progress.Json.ObjectModel.JsonObject.
using Progress.IO.FileInputStream.

class NamedFile:
    /* Returns a named image. 
       
       @param Memptr The image file 
       @return HttpHeader The Content-Disposition header with an embedded filename */
    method public HttpHeader ReadNamedImage(output pImage as class Memptr):
        define variable mImg as memptr no-undo.
        define variable webAppName as character no-undo.
        define variable hdr as HttpHeader no-undo.
        
        assign webAppName = web-context:get-cgi-value('env':u, 'CONTEXT_PATH':u).
        if webAppName eq '':u then
            assign webAppName = 'ROOT':u. 
        
        copy-lob file substitute('&1/webapps/&2/static/images/communities.png':u, 
                            os-getenv('CATALINA_BASE':u),
                            webAppName)
                 to mImg.
        
        assign pImage  = new Memptr(mImg)
               hdr     = HttpHeaderBuilder:Build('Content-Disposition')
                                :Value('attachment; fileName=communities.png')
                                :Header.
        return hdr.
        finally:
            set-size(mImg) = 0.
        end finally.
    end method.
    
    /* Returns a named image
       
       @param character The Content-Disposition header value with an embedded filename
       @return Memptr The image file  */
    method public class Memptr ReadNamedImage(output pContentDisposition as character):
        define variable imgData as class Memptr no-undo.
        define variable mImg as memptr no-undo.
        define variable webAppName as character no-undo.
        
        assign webAppName = web-context:get-cgi-value('env':u, 'CONTEXT_PATH':u).
        if webAppName eq '':u then
            assign webAppName = 'ROOT':u. 
        
        copy-lob file substitute('&1/webapps/&2/static/images/communities.png':u, 
                            os-getenv('CATALINA_BASE':u),
                            webAppName)
                 to mImg.
        
        assign imgData             = new Memptr(mImg)
               pContentDisposition = 'attachment; fileName=communities.png'
               .
        return imgData.
        finally:
            set-size(mImg) = 0.
        end finally.
    end method. 

    /* Returns a named image. 
       
       @param FileInputStream The image file 
       @return HttpHeader The Content-Disposition header with an embedded filename */
    method public HttpHeader ReadNamedImage(output pImage as FileInputStream ):
        define variable mImg as memptr no-undo.
        define variable webAppName as character no-undo.
        define variable hdr as HttpHeader no-undo.
        
        assign webAppName = web-context:get-cgi-value('env':u, 'CONTEXT_PATH':u).
        if webAppName eq '':u then
            assign webAppName = 'ROOT':u. 
        
        assign file-info:file-name = substitute('&1/webapps/&2/static/images/communities.png':u, 
                                        os-getenv('CATALINA_BASE':u),
                                        webAppName)
               hdr = HttpHeaderBuilder:Build('Content-Disposition')
                                        :Value('attachment; fileName=communities.png')
                                        :Header.
        assign pImage = new FileInputStream(file-info:full-pathname).
        return hdr.
    end method. 
    
end class.