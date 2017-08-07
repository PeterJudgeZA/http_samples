/*------------------------------------------------------------------------
    File        : MockDOH
    Purpose     : Test mock wrapper for the DOH - allows dev to pass in a request
                  and the process the response.
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Wed Oct 26 10:27:38 EDT 2016
    Notes       : * this wrapper makes sure we never use the WEB-CONTEXT or
                    WEB-STREAM
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Web.DataObject.DataObjectHandler.
using OpenEdge.Web.DataObject.MappedOperation.
using OpenEdge.Web.IWebRequest.

class OpenEdge.Test.Mock.MockDOH inherits DataObjectHandler: 
    define public property Response as IHttpResponse no-undo get. protected set.
    
    constructor public MockDOH ():
        super().
        
        Logger = OpenEdge.Logging.LoggerBuilder:GetLogger(get-class(DataObjectHandler)).
        
        message 
        logger:name skip
        logger:loglevel:tostring()
        
        view-as alert-box.    
    end constructor.
    
	method override protected MappedOperation FindOperation(input poRequest as IWebRequest ):
		def var oper as MappedOperation.
		
		oper = super:FindOperation(poRequest).
		
		message
		  'poRequest:PathInfo=' poRequest:PathInfo skip
		  'oper:ServiceName= '	oper:ServiceName skip
		  'oper:ServiceURI= '  oper:ServiceURI skip
		  'oper:Method= '  oper:Method skip(2)
		  'operation ' oper:tostring()
        view-as alert-box.
		
		return oper.
	end method.

	method override public integer HandleRequest( input poRequest as IWebRequest ):
		return super:HandleRequest(input poRequest).
	end method.
	
	method override protected void WriteResponse(input poResponse as IHttpResponse):
	    assign this-object:Response = poResponse.
    end method.
    
end class.
