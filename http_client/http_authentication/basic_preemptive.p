/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : basic_preemptive.p
    Purpose     : Illustrates adding credentials before making a request
    Author(s)   : pjudge
    Created     : 2017-01-05
    Notes       : * Equivalent of curl -X GET -v http://www.httpbin.org/basic-auth/my-user/my-passwd -u my-user:my-passwd 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.Filter.Auth.IAuthFilterEventHandler.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.URI.
using OpenEdge.Net.HTTP.ClientBuilder.

/* ***************************  Definitions  ************************** */
define variable req as IHttpRequest no-undo.
define variable resp as IHttpResponse no-undo.
define variable uri as URI no-undo.
define variable httpClient as IHttpClient no-undo.
define variable creds as Credentials no-undo.

/* ***************************  Main Block  *************************** */
httpClient  = ClientBuilder:Build()
                :Client.

// Create credentials
creds = new Credentials('some-domain', 'my-user', 'my-passwd').

req = RequestBuilder:Get('http://www.httpbin.org/basic-auth/my-user/my-passwd')
        // Add credentials to the request
        :UsingBasicAuthentication(creds)
        :Request.

resp = httpClient:Execute(req).

message 
'HTTP status code: ' resp:StatusCode skip
view-as alert-box.

/* eof */