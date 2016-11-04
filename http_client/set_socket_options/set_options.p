/*------------------------------------------------------------------------
    File        : set_options.p
    Description : Illustrates setting options on a socket for use with the 
                  http client
    Author(s)   : pjudge 
    Created     : 2016-11-04
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.LogLevelEnum.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClientLibrary.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.ServerConnection.ClientSocket.

session:error-stack-trace = true.
session:debug-alert = true.
log-manager:logfile-name = session:temp-dir + '/set_options.log'.
log-manager:logging-level = integer(LogLevelEnum:TRACE).
log-manager:clear-log().

/* ********************  Preprocessor Definitions  ******************** */
def var oSocket as ClientSocket.
def var oLib as IHttpClientLibrary.
def var oReq as IHttpRequest.
def var oResp as IHttpResponse.

/* ***************************  Main Block  *************************** */
assign oSocket = new ClientSocket()
       oSocket:ReceiveTimeout = 30
       
       oLib = ClientLibraryBuilder:Build()
                :Option(get-class(ClientSocket):TypeName, oSocket)
                :Library
                
       oReq = RequestBuilder:get('http://localhost')
                    :Request
       .

assign oResp = ClientBuilder:Build()
                    :UsingLibrary(oLib)
                    :Client
                    :Execute(oReq).
            
message 
oResp:StatusCode skip
oResp:ContentLength skip
oResp:ContentType skip
oResp:Entity
view-as alert-box.            
            
                            
catch e as Progress.Lang.Error :
    message 
    e:GetMessage(1) skip
    e:CallStack
    view-as alert-box.
end catch.