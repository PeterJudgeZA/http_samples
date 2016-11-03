/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : get_applications.p
    Purpose     : Returns the list of applications from a PASOE server
    Author(s)   : pjudge 
    Created     : Thu Oct 13 09:17:32 EDT 2016
    Notes       : * this is the equivalent of curl -X GET -v http://localhost:16680/oemanager/applications/ -u tomcat:tomcat
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.URI.
using OpenEdge.Net.HTTP.IHttpResponse.
using Progress.Json.ObjectModel.JsonObject.

/* ***************************  Session config  *************************** */
/* OPTIONAL FOR DEBUG/TRACING

session:error-stack-trace = true.
log-manager:logging-level = 6.
log-manager:logfile-name = session:temp-dir + 'get_applications.log'.
log-manager:clear-log().

*/

/* ***************************  Main Block  *************************** */
define variable oClient as IHttpClient no-undo.
define variable oUri as URI no-undo.
define variable oReq as IHttpRequest no-undo.
define variable oResp as IHttpResponse no-undo.
define variable oCreds as Credentials no-undo.
define variable oJson as JsonObject no-undo.

oClient = ClientBuilder:Build():Client.

oCreds = new Credentials('', 'tomcat', 'tomcat').

oUri = new URI('http', 'localhost', 16680).
oUri:Path = '/oemanager/applications/'.
     
oReq = RequestBuilder:Get(oUri)
            :UsingCredentials(oCreds)
            :Request.
            
oResp = oClient:Execute(oReq).

if type-of(oResp:Entity, JsonObject) then
    assign oJson = cast(oResp:Entity, JsonObject).
    
/* do what you need to with the JSON here */    

catch oError as Progress.Lang.Error :
    message 
        oError:GetMessage(1) skip(2)
        oError:CallStack
    view-as alert-box.		
end catch.
