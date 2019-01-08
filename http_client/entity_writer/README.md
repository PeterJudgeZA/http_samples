## Introduction
This folder contains examples of creating entity writer objects, that are responsible for reading HTTP message bodies and creating 'strongly typed' objects. So a HTTP message with a Content-Type of `multipart/form-data` uses a `MultipartEntityWriter` to create an instance of a `OpenEdge.Net.MultipartEntity` class based on a character or memptr representation.

There may be cases where you have custom content types or the shipped writers are buggy. In this case, you can create a new, or override an existing, EntityWriter. These must be instances of `OpenEdge.Net.HTTP.Filter.Payload.MessageWriter`.


## Registering writers

In your code, add the entity writer to the appropriate registry. This only needs to be done once per session, so it's recommended to do this duriung session startup.

````

using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterRegistry.
using Example.Writer.ExtendedJsonEntityWriter.

// The HTTP client (and certain webhandlers) will now use the ExtendedJsonEntityWriter 
// for all JSON content
EntityWriterRegistry:Registry:Put('application/json':u,
                                  get-class(ExtendedJsonEntityWriter) ).

````

The Registry property is an instance of the `OpenEdge.Core.Util.BuilderRegistry` type, which is a map of characters (keys) and `Progress.Lang.Class` instances (values). There are `Get`, `Put`, `Remove` and `Clear` methods, as well `Has` and a `Size` property for registry inspection.
    
## Examples

| File name | Description | Comments |
| ----- | ------ |  ------ | 
| `Example.Writer.ExtendedJsonEntityWriter` | Writes JSON as `Progress.ObjectModel.JsonConstruct` and certain primitive types |  |
| `test_ext_writer.p` | Example of registering the writer and calling it | |
