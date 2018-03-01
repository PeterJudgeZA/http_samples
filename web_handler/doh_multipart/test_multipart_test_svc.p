/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : test_multipart_test_svc.p
    Purpose     : Test the Service using ABL   
    Author(s)   : pjudge
    Created     : Thu Mar 01 14:27:59 EST 2018
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.MultipartEntity.
using Progress.Json.ObjectModel.JsonObject.

/* ***************************  Main Block  *************************** */
define variable hc as IHttpClient no-undo.
define variable req as IHttpRequest no-undo.
define variable res as IHttpResponse no-undo.
define variable mpEntity as MultipartEntity no-undo.
define variable jsonEntity as JsonObject no-undo.

hc = ClientBuilder:Build():Client.

// 1. Get an entity from the test service
req = RequestBuilder:Get('http://localhost:8830/web/pdo/MultipartTestSvc/':u)
        :Request.

res = hc:Execute(req).

if     res:ContentType eq 'multipart/mixed' 
   and type-of(res:Entity, MultipartEntity)
then
    assign mpEntity = cast(res:Entity, MultipartEntity).
    
message 
'num parts=' mpEntity:Size
view-as alert-box.

// 2. Send an entity to the test services
req = RequestBuilder:Post('http://localhost:8830/web/pdo/MultipartTestSvc/':u, mpEntity)
        :Request.

res = hc:Execute(req).

if     res:ContentType eq 'application/json' 
   and type-of(res:Entity, JsonObject)
then
    cast(res:Entity, JsonObject):WriteFile(session:temp-dir + 'multipart_test.json', yes).
    
catch e as Progress.Lang.Error :
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
        
end catch.
