/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : MockWebRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Fri Jul 24 13:39:17 EDT 2015
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Test.Mock.MockWebRequest.

class OpenEdge.Test.Mock.MockWebRequest inherits HttpRequest implements IWebRequest: 
    define private temp-table ttKeyValue no-undo
        field KeyType as character
        field KeyName as character
        field KeyValue as character
        index idx1 as primary unique KeyType KeyName.
         
	define public property DefaultCookieDomain as character no-undo   get.  set. 

	define public property DefaultCookiePath as character no-undo   get.  set. 

	define public property LocalAddress as character no-undo   get.  set. 

	define public property LocalHost as character no-undo   get.  set. 

	define public property LocalPort as integer no-undo   get.  set. 

	define public property PathInfo as character no-undo   get.  set. 

	define public property PathParameterNames as character no-undo   get.  set. 

	define public property RemoteAddress as character no-undo   get.  set. 

	define public property RemoteHost as character no-undo   get.  set. 

	define public property RemotePort as integer no-undo   get.  set. 

	define public property RemoteUser as character no-undo   get.  set. 

	define public property ResolvedTransportPath as character no-undo   get.  set. 

	define public property ServerSoftware as character no-undo   get.  set. 

	define public property TransportPath as character no-undo   get.  set. 

	define public property WebAppPath as character no-undo   get.  set.

    define public property ContextNames as character no-undo get. set.	
	
	/* Returns the URI template used to find the handler for this request. May be empty */ 
    define public property UriTemplate as character no-undo initial ?
        get():
            return this-object:UriTemplate.
        end get.
        set.
        	
	constructor public MockWebRequest(input pcPathInfo as char,
	                                  input pcMethod as char,
	                                  input pcWebAppPath as char):
	    PathInfo = pcPathInfo.
	    method = pcMethod.
	    WebAppPath = pcWebAppPath.
    end method.
    
    method public void SetPathParameter(input pcName as character ,
                                        input pcValue as character):
        define buffer keyValue for ttKeyValue.
        
        Assert:NotNullOrEmpty(pcName, 'path parameter name').
        find keyValue where
             keyValue.KeyType eq 'pathParam':u and
             keyValue.KeyName eq pcName
             no-error.
        if not available keyValue then
        do:
            create keyValue.
            assign keyValue.KeyType = 'pathParam':u 
                   keyValue.KeyName = pcName.
        end.
        
        assign keyValue.KeyType = pcValue.
    end method.
    
	method public character GetPathParameter( input pcName as character ):
	    define buffer keyValue for ttKeyValue.
        
        Assert:NotNullOrEmpty(pcName, 'path parameter name').
        find keyValue where
             keyValue.KeyType eq 'pathParam':u and
             keyValue.KeyName eq pcName
             no-error.
        if available keyValue then
            return string(keyValue.KeyValue).
	end method.

    method public void SetContextValue(input pcName as character,
                                       input pcValue as longchar):
        define buffer keyValue for ttKeyValue.
        
        Assert:NotNullOrEmpty(pcName, 'context name').
        find keyValue where
             keyValue.KeyType eq 'ctxValue':u and
             keyValue.KeyName eq pcName
             no-error.
        if not available keyValue then
        do:
            create keyValue.
            assign keyValue.KeyType = 'ctxValue':u 
                   keyValue.KeyName = pcName.
        end.
           
        assign keyValue.KeyType = string(pcValue).
    end method.
	
    method public longchar GetContextValue(pcName as character):
        define buffer keyValue for ttKeyValue.
        
        Assert:NotNullOrEmpty(pcName, 'path parameter name').
        find keyValue where
             keyValue.KeyType eq 'ctxValue':u and
             keyValue.KeyName eq pcName
             no-error.
        if available keyValue then
            return keyValue.KeyValue.
    end method.
    
end class.