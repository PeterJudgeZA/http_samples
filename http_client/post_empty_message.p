/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : post_empty_message.p
    Purpose     : Sends an empty (no) body on a POST request
    Author(s)   : pjudge 
    Created     : 2017-08-07
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.String.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.HTTP.IHttpResponse.

/* ***************************  Definitions  ************************** */
define variable httpClient as IHttpClient no-undo.
define variable emptyReq as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.

/* ********************  Logging etc ******************** */
/*
log-manager:logfile-name = session:temp-dir + '/post_empty_message.log'.
log-manager:logging-level = 6.
log-manager:clear-log().
*/

/* ***************************  Main Block  *************************** */
httpClient = ClientBuilder:Build():Client.

emptyReq = RequestBuilder:Post('http://httpbin.org/post', String:Empty())
                :Request.
// Remove the entity (since there's a bug preventing it from being used) 
emptyReq:Entity = ?.
// Remove the auto-added ContentType value (from the RequestBuilder call)
emptyReq:RemoveHeader('Content-Type').
                
resp = httpClient:Execute(emptyReq).

message 
resp:StatusCode
view-as alert-box.

catch e as Progress.Lang.Error :    
    message e:GetMessage(1) skip(2)
    e:CallStack
    view-as alert-box.
        
end catch.    
    
    
    

