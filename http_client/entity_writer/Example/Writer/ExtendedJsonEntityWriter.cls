/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : ExtendedJsonEntityWriter
    Purpose     : An example of an Entity Write that enhances/extends the existing JsonEntityWriter
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : 2019-01-08
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using Ccs.Common.Support.IDecimalHolder.
using Ccs.Common.Support.IInt64Holder.
using Ccs.Common.Support.IIntegerHolder.
using Ccs.Common.Support.ILogicalHolder.
using OpenEdge.Core.Decimal.
using OpenEdge.Core.LogicalValue.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using OpenEdge.Net.HTTP.Filter.Payload.JsonEntityWriter.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using Progress.Lang.Object.

class Example.Writer.ExtendedJsonEntityWriter inherits MessageWriter: 
    define private variable mJsonWriter as JsonEntityWriter no-undo.
    
    constructor public ExtendedJsonEntityWriter():
        super(get-class(Progress.Lang.Object)).
        
        assign mJsonWriter = new JsonEntityWriter().
    end constructor.
    
    method override public void Open():
        super:Open().
        
        mJsonWriter:Open().
    end method.

    method override public void Close():
        super:Close().
        
        mJsonWriter:Close().
    end method.
    
    method override public void Flush():
        //super:Flush().
        
        mJsonWriter:Flush().
    end method.
    
    method override public int64 Write(input pData as longchar):
        define variable bytesWritten as int64 no-undo.
        define variable unknownValue as character no-undo init ?.
        
        assign bytesWritten = length(pData, 'raw':u).
        
        // the ObjectModelParser handles objects and arrays just fine
        if    pData begins '[':u 
           or pData begins StringConstant:CURLY_OPEN
           // let the parser deal with blanks
           or pData eq '':u
        then
            assign bytesWritten       = mJsonWriter:Write(pData)
                   this-object:Entity = mJsonWriter:Entity
                   .
        else
        if    pData eq ? 
           or pData eq 'null':u
        then
            assign this-object:Entity = new String(unknownValue).
        else
        if    pData eq 'true':u
           or pData eq 'false':u
        then
            assign this-object:Entity = new LogicalValue(logical(pData))
                   cast(this-object:Entity, LogicalValue):Format = 'true/false':u
                   .
        else
        if String:IsQuoted(pData) then
            assign this-object:Entity = new String(pData).
        else
        // any other values should be numberical
            assign this-object:Entity = new Decimal(decimal(pData)).
        
        return bytesWritten.
    end method.
    
    method override public int64 Write(input pData as character):
        define variable jsonData as longchar no-undo.
            
        assign jsonData = pData.
        
        return this-object:Write(jsonData).
    end method.
    
    method override public int64 Write(input pData as memptr):
        define variable jsonData as longchar no-undo.
        
        // JSON _should_ be all character data 
        copy-lob pData to jsonData.
        
        return this-object:Write(jsonData).
    end method.
    
    method override public int64 Write(input pData as Object):
        define variable bytesWritten as int64 no-undo.
        define variable unknownValue as character no-undo init ?.
        
        case true:
            when not valid-object(pData) then
                assign this-object:Entity = new String(unknownValue)
                       bytesWritten       = 0
                       .
            
            when type-of(pData, IDecimalHolder) or
            when type-of(pData, IIntegerHolder) or
            when type-of(pData, IInt64Holder) or
            when type-of(pData, ILogicalHolder) then
                return this-object:Write(string(pData)).
                
           otherwise
                assign bytesWritten       = mJsonWriter:Write(pData)
                       this-object:Entity = mJsonWriter:Entity
                       .
        end case.
        
        return bytesWritten.
    end method.
    
end class.