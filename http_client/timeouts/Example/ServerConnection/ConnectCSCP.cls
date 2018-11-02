/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
 /*------------------------------------------------------------------------
    File        : ConnectCSCP
    Description : Connection Parameters with the Connect Timeout 
    Author(s)   : pjudge
    Created     : 2018-11-02
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Assert.
using OpenEdge.Net.ServerConnection.ClientSocketConnectionParameters.
using OpenEdge.Net.URI.

class Example.ServerConnection.ConnectCSCP inherits ClientSocketConnectionParameters:
    /* The timeout for the socket CONNECT, in milliseconds */
    define public property ConnectTimeout as integer no-undo
        get.
        set(input pTimeout as integer):
            Assert:NotNull(pTimeout, 'Connect timeout').
            assign this-object:ConnectTimeout = pTimeout.
        end set.
    
    constructor public ConnectCSCP (  ):
        super ().
    end constructor.
    
    constructor public ConnectCSCP ( input pScheme as character, input pHost as character, input pPort as integer ):
        super (input pScheme, input pHost, input pPort).
    end constructor.
        
    constructor public ConnectCSCP ( input poURI as URI ):
        super (input poURI).
    end constructor.

    method override public character GetConnectionString():
        define variable connectionParams as character no-undo.
        
        assign connectionParams = super:GetConnectionString().
        if this-object:ConnectTimeout gt 0 then
            assign connectionParams = substitute('&1 -clientConnectTimeout &2':u,
                                                connectionParams, ConnectTimeout).
        
        return connectionParams.
    end method.    

end class.