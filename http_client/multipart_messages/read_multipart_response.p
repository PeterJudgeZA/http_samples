/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : read_multipart_response.p
    Purpose     : Illutrates reading the parts in a multipart message 
    Author(s)   : pjudge
    Created     : 2018-11-21
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MimeTypeHelper.
using OpenEdge.Net.MultipartEntity.

/* ***************************  Main Block  *************************** */
define variable req as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.
define variable mpEntity as MultipartEntity no-undo.
define variable msgPart as MessagePart no-undo.
define variable partBody as Progress.Lang.Object no-undo.
define variable cnt as integer no-undo.
define variable loop as integer no-undo.
define variable hdr as HttpHeader no-undo.

// Dummy request that assumes you get multipart data returned
assign req  = RequestBuilder:Get('http://example.com/multipart-response':u)
                            :Request
       resp = ClientBuilder:Build():Client:Execute(req)
       .

// verify this is multipart data
if   MimeTypeHelper:IsMultipart(resp:ContentType) 
and type-of(resp:Entity, MultipartEntity)
then
do:
    assign mpEntity = cast(resp:Entity, MultipartEntity)
           cnt      = mpEntity:Size
           .
    do loop = 1 to cnt:
        assign msgPart  = mpEntity:GetPart(loop)
               partBody = msgPart:Body
               .
        // you'll usually get the Content-Disposition header to do stuff with
        // Good info on this header is at https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition 
        if msgPart:Headers:Has('Content-Disposition':u) then
            assign hdr = msgPart:Headers:Get('Content-Disposition':u).
        
        // Work with the part body as you would the response body.
    end.
end.
