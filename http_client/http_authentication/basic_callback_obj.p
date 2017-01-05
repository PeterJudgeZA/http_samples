/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : basic_callback_obj.p
    Purpose     : Illustrates 
    Description : 
    Author(s)   : pjudge
    Created     : 2017-01-05
    Notes       : * Equivalent of curl -X GET -v http://www.httpbin.org/basic-auth/my-user/my-passwd -u my-user:my-passwd
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.AuthenticationRequestEventArgs.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.URI.
using Progress.Lang.Object.

/* ***************************  Definitions  ************************** */
define variable req as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.
define variable uri as URI no-undo.
define variable httpClient as IHttpClient no-undo.

/* ***************************  Main Block  *************************** */
httpClient  = ClientBuilder:Build()
                :Client.

req = RequestBuilder:Get('http://www.httpbin.org/basic-auth/my-user/my-passwd')
        :AuthCallback(new SimpleAuthCallback())
        :Request.

resp = httpClient:Execute(req).

message 
resp:StatusCode
view-as alert-box.

/* eof */