/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : basic_callback_proc.p
    Purpose     : 
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

procedure AuthFilter_HttpCredentialRequestHandler:
    define input parameter poSender    as Object no-undo.
    define input parameter poEventArgs as AuthenticationRequestEventArgs no-undo.
    
    define variable uid as character no-undo    initial 'my-user'.
    define variable pw as character no-undo     initial 'my-passwd'.
    
    // you may get these credentials from another location 
    update 
        uid     label 'User'            format 'x(20)'   
        pw      label 'Password'        format 'x(20)'
    with 1 col.
    
    assign poEventArgs:Credentials = new Credentials('domain', uid, pw).
    
end procedure.

/* ***************************  Main Block  *************************** */
httpClient  = ClientBuilder:Build()
                :Client.

req = RequestBuilder:Get('http://www.httpbin.org/basic-auth/my-user/my-passwd')
        :AuthCallback(this-procedure)
        :Request.

resp = httpClient:Execute(req).

message 
resp:StatusCode
view-as alert-box.

/* eof */