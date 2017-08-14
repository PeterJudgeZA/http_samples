/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : multipart_img_json_txt.p
    Author(s)   : pjudge 
    Created     : 2017-08-14
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
using Progress.Json.ObjectModel.JsonObject.
using OpenEdge.Core.String.
using Progress.Json.ObjectModel.JsonArray.

/* ***************************  Session config  *************************** */
/* OPTIONAL FOR DEBUG/TRACING
*/
session:error-stack-trace = true.
session:debug-alert = true.
log-manager:logfile-name  = session:temp-dir + '/multipart_img_json_txt.log'.
log-manager:logging-level = 6.
log-manager:clear-log().

/* ***************************  Main Block  *************************** */
define variable oReq as IHttpRequest no-undo.
define variable oResp as IHttpResponse no-undo.
define variable oClient as IHttpClient no-undo.
define variable oEntity as MultipartEntity no-undo.
define variable oPart as MessagePart no-undo.
define variable mData as memptr no-undo.
define variable oHdr as HttpHeader no-undo.

define variable oJsonData as JsonObject no-undo.
define variable oPic as class Memptr no-undo.
define variable oText as String no-undo.

define temp-table ttData no-undo
    field recordId as character
    field lastUpdate as datetime-tz
    field description as character
    index idx1 as primary unique recordId.


/* Create the multipart entity/body */
assign oEntity = new MultipartEntity()
       oEntity:Boundary = 'tear-down-the-wall'
       .

/** CREATE AND ATTACH THE DATASET AS JSON **/
create ttData.
assign ttData.recordId    = guid
       ttData.lastUpdate  = now
       ttData.description = 'the first record'
       .
        
create ttData.
assign ttData.recordId    = guid
       ttData.lastUpdate  = now
       ttData.description = 'the second record'
       .

assign oJsonData = new JsonObject().
oJsonData:Read(buffer ttData:handle).

assign oPart = new MessagePart('application/json':u, oJsonData).
oEntity:AddPart(oPart).

/** CREATE AND ATTACH THE MANUAL JSON  **/
assign oJsonData = new JsonObject().
oJsonData:Add('firstProperty', now).
oJsonData:AddNull('secondProp').
oJsonData:Add('children', new JsonArray(3)).

assign oPart = new MessagePart('application/json':u, oJsonData).
oEntity:AddPart(oPart).

/** CREATE AND ATTACH THE TEXT PART **/
assign oText = new String("don't worry.~nbe happy")
       oPart = new MessagePart('text/plain':u, oText)
       .
oPart:Headers:Get('Content-Type':u):SetParameterValue('charset', '"utf-8"').

oEntity:AddPart(oPart).

/** CREATE AND ATTACH THE PICTURE PART **/
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
