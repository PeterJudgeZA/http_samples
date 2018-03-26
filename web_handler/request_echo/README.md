## Introduction 
The `request_echo` folder contains examples of a Web Handler that returns the incoming request (and associated data) as JSON. This is useful for testing HTTP clients.


## Response format
The request is returned as JSON data, comprising a set of properties with associated data. If no data is available for a top-levle proeprty, then an empty JSON object is returned. The only exception to this is when there are errors processing the request. In that case, some of the top-level proeprties may be missing or incomplete.

### Top-level properties   
**`method`** : A string containing the HTTP method (verb)

**`uri`** : A string containing the complete URL for the request

**`origin`** : A string containing the IP address of machine making the request.

**`pathParameters`** : A JSON object with string properties representing the path parameter. The response will always contain at least one property, `TEMPLATE`. If path parameters are used, a property named `FINAL_MATCH_GROUP` will exist in addition to the path parameters as specified in the `openedge.properties` file.

**`args`** : A JSON object containing string properties representing the query string/parameters. This data is analogous to the `cgi.QUERY` data but is read from the OOABL request object.

**`headers`** : A JSON object containing string properties representing all the request headers. Note that these header names are all upper-cased. This is due to the way in which they are passed into the AVM.

**`cookies`** :  A JSON object containing string properties representing all the request cookies. 

**`data`** : A string containing the request body, if any. The handler will try to strigify the request body in the following way: It first tries using the StringEntityWriter; if that fails, then it tries to base64-encode a binary version. If that fails, an error is thrown. If base64-encoded data is used, the entity is encoded using https://en.wikipedia.org/wiki/Data_URI_scheme which results in a string with the format of `data:<content-type>;base64,<base64-encoded-data>`

**`form`** : If the request contains multipart data (ie a content type of multipart/mixed, multipart/form-data or similar), then a JSON object property is written per part. Each part has 2 properties: `headers` and `data`, both of which are described above. If the part - and thus property - name cannot be determined from the part's `Content-Disposition` header, then a name of `part.<part-number>` is used.

**`cgi.ENV`**, **`cgi.QUERY`**, **`cgi.FORM`** :  Name/value pairs of the CGI variables available via the `WEB-CONTEXT`'s `GET-CGI-LIST()` method. CGI variables are only returned when a query parameter named `debug` is sent (a value for the parameter is not required).

For FORM values that contain files, the value is a JSON object containing the fileName and the number of bytes received. 

### Errors 
Any errors that are raised during the preparation of the response are written into an `errors` property, which is a JSON representation of the error raised. This property is appended to the existing JSON response (if any). Depending on where the error was raised, certain of the properties described above will not be written into the response.


## Installation
### Server setup 
You will need one PASOE instance. You can use an existing PASOE instance, or create one in OE Explorer/Manager or via the `tcman create` CLI tool. Add this server to PDSOE's Servers view.


Download the code from GitHub. Import the project into an PDSOE workspace via **File > Import > Existing Projects into Workspace**. This will bring all the code, images and configuration files into the project. These files are **not** in the structure required for deployment/use in PASOE.


### The (Very) Ugly Way
This approach is good for showing the functionality at work but makes updates/development/fiddling difficult.

1. Copy the `RequestEchoHandler.cls` file into a webapp's `WEB-INF/openedge`  folder, or into the instance's `openedge/' folder.
2. Make sure that the handler is configured for at least one webapp. Make sure that the `conf/openedge.properties` file contains the following. The _N_ in the handler definition must be a contiguous integer value. You can use any relative URI for the handlerm, with or without path parameters.

>[<abl-app-name>.<web-app-name>.WEB]

>handler_N_=RequestEchoHandler : /echo



#### The Good Way 
Create a new ABL Service for the images and select the WebSpeed (WebHandler) option from the Service Type radio set.
1. Name it something like `RequestEchoSvc` although the name doesn't really matter
2. Select an existing WebHandler and specify or select `RequestEchoHandler`
3. Add a Resource URI of `/echo/`
4. Click Finish to add the service

Copy the code (.cls) from the `request_echo` folder into the `PASOEContent/WEB-INF/openedge' folder.

Add the service and the ABL module to the PASOE server. You can do this by right-clicking the server and selecting **Add and Remove ...** . 

Publish the services and ABL code to the server. 

You can now call the service using an HTTP client (various exist, including the ABL HTTP client) or a web browser.

 
##
