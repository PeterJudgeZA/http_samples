/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : test_ext_writer.p
    Purpose     : Registers and calls the custom writer
    Author(s)   : pjudge
    Created     : 2019-01-08
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Example.Writer.ExtendedJsonEntityWriter.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterRegistry.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterBuilder.

/* ***************************  Definitions  ************************** */

/* ***************************  Main Block  *************************** */

EntityWriterRegistry:Registry:Put('application/json':u,
                                  get-class(ExtendedJsonEntityWriter) ).


// try writing
define variable inputData as longchar no-undo.
define variable jsonData as Progress.Lang.Object no-undo.
define variable ew as MessageWriter no-undo.

// test values
// STRING
// strings MUST be quoted
inputData = quoter('abcde').
// NUMBER
inputData = '12345.67'.
// NULL
inputData = 'null'.
inputData = ?.
// ARRAY
inputData = '[1]'.
// OBJECT
inputData = '~{"a":123}'.
// BOOLEAN
inputData = 'true'.
inputData = 'false'.


ew = EntityWriterBuilder:Build('application/json':u):Writer.

ew:Open().
ew:Write(inputData).
ew:Close().


jsonData = ew:Entity.

message 
ew:GetClass():TypeName skip //Example.Writer.ExtendedJsonEntityWriter
jsonData skip
jsonData:GetClass():TypeName
view-as alert-box.

catch e as Progress.Lang.Error :
    message 
    e:GetMessage(1)
    view-as alert-box.
        
end catch.
