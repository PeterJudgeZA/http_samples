/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : post_form_name_value.p
    Purpose     : POST a form-encoded message based on a series of name-value paris
    Author(s)   : pjudge
    Created     : 2018-08-17
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Collections.IStringStringMap.
using OpenEdge.Core.Collections.StringStringMap.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using Progress.Json.ObjectModel.JsonObject.

/* ***************************  Definitions  ************************** */
define variable hc as IHttpClient no-undo.
define variable req as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.
define variable creds as Credentials no-undo.
define variable tokenEndpoint as character no-undo.
define variable clientId as character no-undo.
define variable clientSecret as character no-undo.
define variable jsonData as JsonObject no-undo.

/* ***************************  Main Block  *************************** */
assign hc    = ClientBuilder:Build():Client
       // the first param is a realm you can leave blank
       creds = new Credentials('':u, clientId, clientSecret)
       .
// build the request
req = RequestBuilder:Post(tokenEndpoint,
                          // prior to 11.7.3 you had to pass in a valid object here. in 11.7.3+ you can not
                          new StringStringMap() )
        :AddFormData('client_id', 'oidc_ovf_conf')
        :AddFormData('grant_type','authorization_code')
        :UsingBasicAuthentication(creds)
        :Request.

// make the request
resp = hc:Execute(req).

// process the response
message 
resp:StatusCode         skip   // 200 is all went well
resp:ContentType        skip   // something like application/json or application/x-www-form-urlencoded
resp:ContentLength      skip   // number of bytes, if you care
view-as alert-box.

// this Entity property is DEFINED as Progress.Lang.Object
// but the actual class/type will be something else; typically something that matches the ContentType 
// now get the response data in  a nice, strongly-typed Object form
// We can either decide what to do based on the ContentType or on the object's type

// approach 1
case resp:ContentType:
    when 'application/json':u then
        assign jsonData = cast(resp:Entity, JsonObject).
    // other types    
end case.

// approach 2
case true:
    when type-of(respData, JsonObject) then
        assign jsonData = cast(resp:Entity, JsonObject).    
    // other types
end case.

// do what you need to with the response data


catch e as Progress.Lang.Error :
    message e
    view-as alert-box.
        
end catch.