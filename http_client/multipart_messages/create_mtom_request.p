/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : create_mtom_request.p
    Author(s)   : pjudge 
    Created     : Mon Nov 14 10:11:09 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Memptr.
using OpenEdge.Core.WidgetHandle.
using OpenEdge.Net.HTTP.HttpHeaderBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MultipartEntity.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Filter.Writer.BodyWriterRegistry.
using OpenEdge.Net.HTTP.Filter.Payload.XmlBodyWriter.

/* ***************************  Session config  *************************** */
/* OPTIONAL FOR DEBUG/TRACING
session:error-stack-trace = true.
session:debug-alert = true.
log-manager:logfile-name  = session:temp-dir + '/create_mtom_request.log'.
log-manager:logging-level = 6.
log-manager:clear-log().
*/

/* ***************************  Main Block  *************************** */
define variable oReq as IHttpRequest no-undo.
define variable oResp as IHttpResponse no-undo.
define variable oClient as IHttpClient no-undo.
define variable oEntity as MultipartEntity no-undo.
define variable oPart as MessagePart no-undo.
define variable hSoapDocument as handle no-undo.
define variable oSoapDoc as class Memptr no-undo.
define variable oPic as class Memptr no-undo.
define variable mData as memptr no-undo.
define variable oHdr as HttpHeader no-undo.

/* Create the multipart entity/body */
assign oEntity = new MultipartEntity()
       oEntity:Boundary = guid  // can use anything here or leave it out for a GUID
       .

/* Create and attach the SOAP/XML part 
   
   This example uses dummy XML - it is not a SOAP message */
create x-document hSoapDocument.
hSoapDocument:load('file':u, 'http_client/multipart_messages/soap.xml':u, false /* validate */ ).
hSoapDocument:Save('memptr':u, mData).
 
/* It should be possible to use a WidgetHandle() to hold the part here, but there's an 
   issue with the XML writer prior to 11.7.0 ; issue ref is PSC00351988 */
assign oSoapDoc = new Memptr(mData)
       oPart    = new MessagePart('application/soap+xml':u, oSoapDoc)
       oPart:ContentId = '<claim@insurance.com>':u
       .
oEntity:AddPart(oPart).

/* Create and attach the Picture part */
set-size(mData) = 0.
copy-lob from file 'http_client/multipart_messages/smile.png' to mData.

assign oPic  = new Memptr(mData)
       oPart = new MessagePart('image/png':u, oPic)
       oPart:ContentId = '<image@insurance.com>':u
       .
oEntity:AddPart(oPart).

/* Build the request
   
   Note that we add the MultipartEntity to the request */
assign oReq = RequestBuilder:Post('http://httpbin.org/post', oEntity)
                :ContentType('multipart/related':u)
                :Request
       oHdr = oReq:GetHeader('Content-Type':u)
       .
// update the Content-Type header with the type and start parameters       
oHdr:SetParameterValue('type':u,  'application/soap+xml':u).
oHdr:SetParameterValue('start':u, '<claim@insurance.com>':u).

/* Run the request */
oClient = ClientBuilder:Build():Client.
oResp = oClient:Execute(oReq).

message 
oResp:StatusCode
view-as alert-box.

catch e as Progress.Lang.Error :
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.		
end catch.
finally:
    // clean up our memptr 
    set-size(mData) = 0.
end finally.        
