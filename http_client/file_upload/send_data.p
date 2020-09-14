/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : send_data.p
    Purpose     : Examples uploading binary files to an http server 
    Created     : 2020-09-20
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Memptr.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using Progress.IO.FileInputStream.
using OpenEdge.Net.HTTP.RequestBuilder.
using Progress.Json.ObjectModel.JsonObject.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define variable hc as IHttpClient no-undo.
define variable req as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.
define variable fis as FileInputStream no-undo.
define variable img as memptr no-undo.
define variable data as class Memptr no-undo.

hc = ClientBuilder:Build():Client.

// File-based
file-info:file-name = 'headers.pdf'.
fis = new FileInputStream(file-info:full-pathname).

req = RequestBuilder:Put('http://httpbin.org/put', fis)
            :ContentType('application/pdf')
            :AcceptContentType('application/json')
            :Request.
            
resp = hc:Execute(req).

// Process the response appropriately
cast(resp:entity, JsonObject):WriteFile(session:temp-dir + 'put.json', yes).

// memptr-based
file-info:file-name = 'smile.png'.
copy-lob from file file-info:full-pathname to img.
data = new Memptr(img).

req = RequestBuilder:Post('http://httpbin.org/post', data)
            :ContentType('image/png')
            :AcceptContentType('application/json')
            :Request.

resp = hc:Execute(req).

// Process the response appropriately
cast(resp:entity, JsonObject):WriteFile(session:temp-dir + 'post.json', yes).

finally:
    set-size(img) = 0.
end finally.