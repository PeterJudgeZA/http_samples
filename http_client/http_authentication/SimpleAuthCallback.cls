/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : SimpleAuthCallback
    Purpose     : Illustrative authentication callback in object form
    Author(s)   : pjudge
    Created     : 2017-01-05
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.AuthenticationRequestEventArgs.
using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.Filter.Auth.IAuthFilterEventHandler.
using Progress.Lang.Object.

class SimpleAuthCallback implements IAuthFilterEventHandler:
    
    constructor public SimpleAuthCallback():
    end constructor.
      
	method public void AuthFilter_HttpCredentialRequestHandler(input poSender as Object, 
	                                                           input poEventArgs as AuthenticationRequestEventArgs ):
        message 
            'In AuthFilter_HttpCredentialRequestHandler callback in ' this-object:GetClass():TypeName  skip
            'Using my-user/my-passwd'
        view-as alert-box info.
        
        assign poEventArgs:Credentials = new Credentials('domain', 'my-user', 'my-passwd').
	end method.
	
end class.