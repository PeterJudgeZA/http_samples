/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : create_multipart_form_data.p
    Author(s)   : pjudge 
    Created     : 2018-02-12
    Notes       : * illustrates the use of a multipart message for form-data
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.HttpHeaderBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MultipartEntity.
using OpenEdge.Net.URI.

/* ***************************  Session config  *************************** */
/* OPTIONAL FOR DEBUG/TRACING
*/
session:error-stack-trace = true.
session:debug-alert = true.

log-manager:logfile-name  = session:temp-dir + '/create_multipart_form_data.log'.
log-manager:logging-level = 6.
log-manager:clear-log().

/* ***************************  Main Block  *************************** */
define variable oReq as IHttpRequest no-undo.
define variable oResp as IHttpResponse no-undo.
define variable oClient as IHttpClient no-undo.
define variable multipartBody as MultipartEntity no-undo.
define variable msgPart as MessagePart no-undo.
define variable oHdr as HttpHeader no-undo.

/* Create the multipart entity/body */
assign multipartBody          = new MultipartEntity()
       multipartBody:Boundary = 'tear-down-the-wall'
       .
// First form-data 'field'
assign msgPart = new MessagePart()
       msgPart:Body = new OpenEdge.Core.String('Base64')
       .
msgPart:Headers:Put(HttpHeaderBuilder:Build('Content-Disposition':u)
                        :Value('form-data; name="BodyJSON"')
                        :Header   ).
multipartBody:AddPart(msgPart).

// Second form-data 'field'
assign msgPart      = new MessagePart()
       msgPart:Body = new OpenEdge.Core.String('Yes')
       .
msgPart:Headers:Put(HttpHeaderBuilder:Build('Content-Disposition':u)
                        :Value('form-data; name="debug"')
                        :Header   ).
multipartBody:AddPart(msgPart).

/* Build the request
   
   Note that we add the MultipartEntity to the request */
assign oReq = RequestBuilder:Post('http://httpbin.org/post':u)
                    // WithData() as an alternative to passing into the Post() method
                    :WithData(multipartBody, 'multipart/form-data':u)
                    :Request
       
       oClient = ClientBuilder:Build():Client
       
       /* Run the request */
       oResp = oClient:Execute(oReq)
       .
message 
oResp:StatusCode
view-as alert-box.

catch e as Progress.Lang.Error :
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.      
end catch.
