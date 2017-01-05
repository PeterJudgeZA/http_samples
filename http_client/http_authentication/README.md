## Introduction
These examples show how to use HTTP authentication with the HTTP client. 

The HTTP client uses a `OpenEdge.Net.HTTP.Credentials` object to provide user details for a request. This object contains just three properties:

    /** The domain (or realm) to which the user belongs */
    define public property Domain as character no-undo get. set.
    
    /** The user name */
    define public property UserName as character no-undo get. set.
    
    /** The user's password for this domain */
    define public property Password as character no-undo get. set.


There are two mechanisms provided for specifying credentials on a request: pre-emptive and callback.

## Preemptive authentication
Pre-emptive authentication is used when the the developer knows that credentials are required before the request is made.

Credentials can be added to a request using the `UsingBasicAuthentication()`, `UsingDigestAuthentication()` and `UsingCredentials()` methods. The first two methods will result result in a `Authorization` header to be added to the request; the latter will hold the credentials until they're asked for by the server. Credentials are added in response to a 401/Unauthorized status code, and a second request is made.


## Callbacks
Callbacks allow a developer to provide a place to provide credentials if they are requested by the server and have not yet been provided. Callbacks are triggered by a 401/Unauthorized response status code and result in a second request with credentials.

Callbacks are added to a request via the `AuthCallback()` method on the RequestBuilder.

Callbacks can be in classes or procedures and must implement the following interface. If procedures are used, an internal procedure named `AuthFilter_HttpCredentialRequestHandler` must exist with the signature .

	interface OpenEdge.Net.HTTP.Filter.Auth.IAuthFilterEventHandler:
	    /** Event handler for the HttpCredentialRequest event.
        
	        @param Object The filter object that publishes the event.
	        @param AuthenticationRequestEventArgs The event args for the event */
	    method public void AuthFilter_HttpCredentialRequestHandler(
	                                input poSender as Object,
	                                input poEventArgs as AuthenticationRequestEventArgs).    
	
	end interface.


## Examples
| Program | Purpose |
| ---- | ---- | 
| basic_preemptive.p | Illustrates adding credentials before making a request. The server expects credentials using the basic authentication method per per http://tools.ietf.org/html/rfc2617 |
| basic_callback_proc.p | Illustrates adding credentials via a callback procedure. The server expects credentials using the basic authentication method per per http://tools.ietf.org/html/rfc2617  | 
| basic_callback_obj.p | Illustrates adding credentials via a callback object. The server expects credentials using the basic authentication method per per http://tools.ietf.org/html/rfc2617  | 
| SimpleAuthCallback | Class implementing IAuthFilterEventHandler that is used as a callback handler by basic_callback_obj.p |
