/** This is free and unencumbered software released into the public domain.
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : MultipartTest
    Description : 
    Author(s)   : pjudge
    Created     : Thu Mar 01 12:27:27 EST 2018
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.String.
using OpenEdge.Net.MessagePart.
using OpenEdge.Net.MultipartEntity.
using Progress.Json.ObjectModel.JsonObject.
using OpenEdge.Core.Memptr.

class MultipartTest: 
    /*  Consumes a multipart entity
        
        @param  MultipartEntity
        @return JsonObject aa 'bounce' of that entity */
    method public JsonObject WriteMultipart (input pData as MultipartEntity):
        define variable data as JsonObject no-undo.
        define variable parts as JsonObject no-undo.
        define variable cnt as integer no-undo.
        
        data = new JsonObject().
        data:Add('size', pData:Size).
        data:Add('boundary', pData:Boundary).
        data:Add('prologue', pData:Prologue).
        parts = new JsonObject().
        data:Add('parts', parts).
        data:Add('epilogue', pData:Epilogue).

        do cnt = 1 to pData:Size:
            parts:Add(string(cnt), pData:GetPart(cnt):ContentType).
        end.
        
        return data.
    end method.
    
    /* Returns a complete multipart entity based on the input size. 
       Parts are added as follows
            <num-parts> modulo 0 : text/plain
            <num-parts> modulo 1 : application/json 
            <num-parts> modulo 2 : image/png
       
       @param integer The number of parts to include
       @param character The intra-part boundary
       @return MultipartEntity  A multipart entity      */
    method public MultipartEntity ReadMultipart (input pNumParts as integer, input pBoundary as character):
        define variable entity as MultipartEntity no-undo.
        define variable msgPart as MessagePart no-undo.
        define variable cnt as integer no-undo.
        define variable jsonBody as JsonObject no-undo.
        define variable mImg as memptr no-undo.
        define variable webAppName as character no-undo.
        
        entity = new MultipartEntity().
        entity:Boundary = pBoundary.
        
        do cnt = 1 to pNumParts:
            case cnt modulo 3:
                when 0 then
                    entity:AddPart(new MessagePart('text/plain', new String("this is part number " + string(cnt)))).
                when 1 then
                do:
                    jsonBody = new JsonObject().
                    jsonBody:Add(string("part-" + string(cnt, '99')), cnt).
                    msgPart = new MessagePart('application/json', jsonBody).
                    entity:AddPart(msgPart).
                end.
                when 2 then
                do on error undo, throw:
                    webAppName = web-context:get-cgi-value('env':u, 'CONTEXT_PATH':u).
                    if webAppName eq '':u then
                        webAppName = 'ROOT':u. 
                    
                    copy-lob file substitute('&1/webapps/&2/static/images/communities.png':u, 
                                        os-getenv('CATALINA_BASE':u),
                                        webAppName)
                             to mImg.
                    
                    msgPart = new MessagePart('image/png', new Memptr(mImg)).
                    entity:AddPart(msgPart).
                    finally:
                        set-size(mImg) = 0.
                    end finally.
                end.
            end case.
        end.
        
        return entity.
    end method. 
    
end class.