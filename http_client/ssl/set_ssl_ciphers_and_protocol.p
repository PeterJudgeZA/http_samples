/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : set_ssl_ciphers_and_protocol.p
    Description : 
    Author(s)   : pjudge
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpClientLibrary.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.

/* ***************************  Main Block  *************************** */
define variable httpLib  as IHttpClientLibrary no-undo.
define variable httpClient as IHttpClient no-undo.
define variable sslProto as character extent no-undo.
define variable sslCipher as character extent no-undo.

// the size and values of the SSL protocols and ciphers depend on the server
extent(sslProto) = 2.
extent(sslCipher) = 10.


// Supported ciphers and protocols at https://documentation.progress.com/output/ua/OpenEdge_latest/gscsv/supported-protocols,-ciphers,-and-certificates-f.html# 
assign sslProto[1] = 'TLSv1.2'
       sslProto[2] = 'TLSv1.1'
       
       sslCipher[1]  = 'AES128-SHA256'
       sslCipher[2]  = 'DHE-RSA-AES128-SHA256'
       sslCipher[3]  = 'AES128-GCM-SHA256' 
       sslCipher[4]  = 'DHE-RSA-AES128-GCM-SHA256'
       sslCipher[5]  = 'ADH-AES128-SHA256'
       sslCipher[6]  = 'ADH-AES128-GCM-SHA256'
       sslCipher[7]  = 'ADH-AES256-SHA256'
       sslCipher[8]  = 'AES256-SHA256' 
       sslCipher[9]  = 'DHE-RSA-AES256-SHA256'
       sslCipher[10] = 'AES128-SHA'
       .
httpLib = ClientLibraryBuilder:Build()
                    :SetSslProtocols(sslProto)
                    :SetSslCiphers(sslCipher)
                    :Library.
                    
httpClient = ClientBuilder:Build()
                :UsingLibrary(httpLib)
                :Client.

// Build and call the request
