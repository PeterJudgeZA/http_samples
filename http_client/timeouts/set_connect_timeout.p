/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : set_connect_timeout.p
    Purpose     : Shows how to set a timeout for the HTTP Client's CONNECT 
    Author(s)   : pjudge
    Created     : 2018-11-02
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Example.ServerConnection.ConnectCSCP.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpClientLibrary.
using OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Net.ServerConnection.ClientSocket.
using OpenEdge.Net.ServerConnection.ClientSocketConnectionParameters.

/* ***************************  Settings *************************** */
session:error-stack-trace = true.

log-manager:logfile-name = session:temp-dir + 'set_connect_timeout.log'.
log-manager:logging-level = 5.
log-manager:clear-log().

/* ***************************  Main Block  *************************** */
define variable httpClient as IHttpClient no-undo.
define variable clientLib as IHttpClientLibrary no-undo.
define variable socket as ClientSocket no-undo.
define variable cscp as ConnectCSCP no-undo.

       // create a custom connection param with connect-timeout
assign cscp                = new ConnectCSCP()
       cscp:ConnectTimeout = 100
       
       // tell the abl-socket-library to use the new connection params
       clientLib = ClientLibraryBuilder:Build()
                        // use the custom ConnectionParameters 
                        :Option(get-class(ClientSocketConnectionParameters):TypeName,
                                cscp)
                   :Library
       
       // tell the client to use the custom library
       httpClient = ClientBuilder:Build()
                        :UsingLibrary(clientLib)
                    :Client
       .
// there's no server here
httpClient:Execute(RequestBuilder:Get('http://localhost:9999'):Request).

catch e as Progress.Lang.Error :
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
end catch.