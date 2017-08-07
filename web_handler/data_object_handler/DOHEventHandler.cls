/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : DOHEventHandler
    Purpose     : Simple example of event callbacks
    Notes       : * in order to set the callbacks, simply NEW this class
                    in a session start event procedure
                        // will register itself as a handler
                        new DOHEventHandler().
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Web.DataObject.HandlerErrorEventArgs.
using OpenEdge.Web.DataObject.HandlerLoadEntityEventArgs.
using OpenEdge.Web.DataObject.OperationInvocationEventArgs.
using OpenEdge.Web.DataObject.DataObjectHandler.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.ObjectModelParser.

class DOHEventHandler: 
    /* circular dep to cheat death aka GC */
    define variable oCheat as DOHEventHandler no-undo.
    
    constructor public DOHEventHandler():
        oCheat = this-object.
        
        DataObjectHandler:Invoked:Subscribe(InvokedHandler).
    end constructor.

    destructor DOHEventHandler():
        DataObjectHandler:Invoked:Unsubscribe(InvokedHandler).
    end destructor.
    
    /* Event published after the business logic function was called by the handler 
       
       @param Progress.Lang.Object The handler publishing the event
       @param OperationInvocationEventArgs Event args for this event */
    method public void InvokedHandler (input poSender as Progress.Lang.Object,
                                       input poEventArgs as OperationInvocationEventArgs):
        define variable responseData as JsonObject no-undo.
        define variable jsonData as JsonObject no-undo.
        define variable datasetData as JsonObject no-undo.
        define variable propertyName as character extent no-undo.
        define variable dsDecoded as memptr no-undo.
        define variable dsBase64 as longchar no-undo.
        
        if     valid-object(poEventArgs:Response:Entity) 
           and type-of(poEventArgs:Response:Entity, JsonObject) then
        do:
            // the 'response' envelope hasn't yet been added by the DOH
            assign jsonData     = cast(poEventArgs:Response:Entity, JsonObject)
                   propertyName = jsonData:GetNames()
                   .
            
            jsonData:WriteFile(session:temp-dir + 'before.json', yes).
            
            if     extent(propertyName) ge 1 
               and jsonData:GetType(propertyName[1]) eq JsonDataType:STRING 
               then
            do on error undo, throw:
                assign dsBase64  = jsonData:GetLongchar(propertyName[1])
                       dsDecoded = base64-decode(dsBase64)
                       datasetData = cast(new ObjectModelParser():Parse(dsDecoded), JsonObject)
                       .
                // replace the BASE64 string with real JSON 
                jsonData:Set(propertyName[1], datasetData).
                
                finally:
                    set-size(dsDecoded)= 0.
                end finally.
            end.
            
            jsonData:WriteFile(session:temp-dir + 'after.json', yes).
        end.
    end method.
    
end class.