/** This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.  **/
/*------------------------------------------------------------------------
    File        : pasoe_form_auth.p
    Description : 
    Author(s)   :  pjudge
    Created     : 2015-08-12
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
block-level on error undo, throw.

using OpenEdge.Core.Collections.IStringStringMap.
using OpenEdge.Core.Collections.StringStringMap.
using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.Cookie.
using OpenEdge.Net.HTTP.CookieJarBuilder.
using OpenEdge.Net.HTTP.ICookieJar.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using OpenEdge.Core.String.

/* ********************  Preprocessor Definitions  ******************** */
/* optional logging; can turn off in prod */
session:debug-alert = true.
session:error-stack-trace  = true.
log-manager:logfile-name = session:temp-dir + 'pasoe_form_auth.log'.
log-manager:logging-level = 6.

/* ***************************  Main Block  *************************** */
def var oClient as IHttpClient.
def var oReq as IHttpRequest.
def var oResp as IHttpResponse.
def var oForm as IStringStringMap.
def var oString as String.
def var oCJ as ICookieJar.
def var oCookies as Cookie extent.
def var iLoop as int.

/* You can use a cookie jar [JAR] or manually manage [MAN].
   Both should work */
   
/* [JAR] */
oCJ = CookieJarBuilder:Build():CookieJar.

oClient = ClientBuilder:Build()
/*  [JAR]           :KeepCookies(oCJ)*/
            :Client.
                        
/* 11.6.0 */
oForm = new StringStringMap().
oForm:Put('j_username', 'restuser').
oForm:Put('j_password', 'password').

oReq = RequestBuilder:Post('http://oelxdev06:11621/static/auth/j_spring_security_check', oForm)
            :Request.

/* 11.5.x 
oString = new String('j_username=restuser&j_password=password').

oReq = RequestBuilder:Post('http://oelxdev06:11621/static/auth/j_spring_security_check', oString)
            :ContentType('application/x-www-form-urlencoded')
            :Request.
*/                        

oResp = oClient:Execute(oReq).

/* [MAN] */
oResp:GetCookies(output oCookies).

oReq = RequestBuilder
            :Get('http://oelxdev06:11621/web/examples/web/status.p')
            :Request.

/* [MAN] */
do iLoop = extent(oCookies) to 1 by -1:
    oReq:SetCookie(oCookies[iLoop]).
end. 
 
oResp = oClient:Execute(oReq).

message 
oResp:StatusCode skip
oResp:ContentLength skip
oResp:Entity:GetClass():TypeName skip
/*cast(oResp:Entity, String):Size skip*/
view-as alert-box.

catch e as Progress.Lang.Error :
    
    message 
    e:GetMessage(1) skip(2)
    e:CallStack
    view-as alert-box.
        
end catch.
