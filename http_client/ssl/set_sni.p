/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : set_sni.p
    Description : 
    Author(s)   : pjudge
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpClientLibrary.
using OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.

/* ***************************  Main Block  *************************** */
define variable httpLib  as IHttpClientLibrary no-undo.
define variable httpClient as IHttpClient no-undo.
define variable sni as character no-undo.
define variable verifyHost as logical no-undo.

httpLib = ClientLibraryBuilder:Build()
                    :ServerNameIndicator(sni)
                    :SslVerifyHost(verifyHost)
                    :Library.
                    
httpClient = ClientBuilder:Build()
                :UsingLibrary(httpLib)
                :Client.

// Build and call the request
