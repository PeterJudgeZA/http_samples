/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/ 
 /*------------------------------------------------------------------------
    File        : MockSocket
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Tue Nov 01 13:35:09 EDT 2016
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.


class OpenEdge.Test.Mock.MockSocket inherits ClientSocket: 

    /** Creates a server object (ie this-object:Server). This is separated
        from the Connect/Disconnect pair of methods so that one server can 
        be connected and disconnected multiple time. */
    method override public void CreateServer():
    end method.

    /** Destroys the server object (ie this-object:Server). This is separated
        from the Connect/Disconnect pair of methods so that one server can 
        be connected and disconnected multiple time. */
    method override public void DestroyServer():
    end method.

    /** Connect to the server specified, based on the ConnectionParameters */
    method override public void Connect():
    end method.
    
    method override protected logical IsConnected():
        return true.
    end method.
    
    /** Disconnect from the server, if connected */    
    method override public void Disconnect():
    end method.

	method override public void WaitForResponse( input piTimeout as integer ):
        define variable oReadEventArgs as SocketReadEventArgs no-undo.
	    define variable mData as memptr no-undo.
	    
	    oReadEventArgs = new SocketReadEventArgs(piTimeout).
	    
	    copy-lob from file session:temp-dir + '/response.data' to mData.
	    
	    assign oReadEventArgs:BytesRead = get-size(mData).
	    
        /* Add this data to the eventargs */
        oReadEventArgs:Data = new Memptr(get-pointer-value(mData),
                                         get-size(mData)).
                
        /* tell any listeners that we have new data */
        OnDataReceived(oReadEventArgs).
	    
	    finally:
	        set-size(mData) = 0.
        end finally.
        
	end method.
	
	method override public void WriteData( input poData as OpenEdge.Core.Memptr ):
	    copy-lob poData:Value to file session:temp-dir + '/request.data'.
	end method.
    
end class.