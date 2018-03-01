## Introduction 
The `doh_multipart` folder contains examples for reading and writing `multipart/*` messages using the Data Object Handler (DOH). The Data Object Handler is an ABL-based Web Handler that performs generalised routing and mapping from an Http request to ABL code in classes and persistent procedures. The DOH uses JSON configuration files to perform routing and mapping functions, and  was first shipped in 11.6.3.

## Server setup / installation
You will need one PASOE instance, 11.6.3 or newer. You can use an existing PASOE instance, or create one in OE Explorer/Manager or via the `tcman create` CLI tool. Add this server to PDSOE's Servers view.


Download the code from GitHub. Import the project into an PDSOE workspace via **File > Import > Existing Projects into Workspace**. This will bring all the code, images and configuration files into the project. These files are **not** in the structure required for deployment/use in PASOE.


## MultipartTestSvc
The **`MultipartTestSvc`** service passes entire multipart messages (request/response entities) to, and receives from, an ABL Service. As of 11.7.3, the DOH does not support multipart messages with the `FIELD` msgElement. Currently ABL applications wanting to use multipart messages must consume them directly in an ABL Service. This example services illustrates this approach.

The code for this test service is in the `doh_multipart` folder. The service comprises of

1. The `MultipartTest.cls` ABL class that process the multipart entities.
2. The `MultipartTestSvc.map` mapping file that defines the service interfaces into the above. There are two endpoints defined
    1. `GET /MultipartTestSvc/`: This operation returns a body with a `multipart/mixed` body. The vital part here is that the contentType of this operations contains a `boundary` parameter; the base example uses `my-part-bound`.
This operations calls the `ReadMultipart` method in the class, and passes in a number of parts and a boundary. These are set to constant values in the mapping file. Note that the boundary used here **_MUST_** match that of the `contentType` property.
    2. `POST /MultipartTestSvc/`: This operation consumes a multipart message and returns a JSON object with pertinent information about the incoming message (the boundary, the number of parts and their content types).

### Installation
### The (Very) Ugly Way
This approach is good for showing the functionality at work but makes updates/development/fiddling difficult.

1. Copy the `MultipartTest.cls` and `MultipartTestSvc.map` files into a webapp's `WEB-INF/openedge`  folder. 
2. Make sure that the DOH is configured for the webapp above. Make sure that the `conf/openedge.properties` file contains the following. The _N_ in the handler definition must be a contiguous integer value.

>[<abl-app-name>.<web-app-name>.WEB]

>handler_N_=OpenEdge.Web.DataObject.DataObjectHandler : /pdo


#### The Good Way 
Create a new ABL Service for the images and select the WebSpeed (WebHandler) option from the Service Type radio set.
1. Name it something like `MultipartTestSvc` although the name doesn't really matter
2. Select an existing WebHandler and specify or select `OpenEdge.Web.DataObject.DataObjectHandler`
3. Add a Resource URI of `/pdo/`
4. Click Finish to add the service

Copy the code (.cls and .map) from the `doh_multipart` folder into the `PASOEContent/WEB-INF/openedge' folder.

Add the service and the ABL module to the PASOE server. You can do this by right-clicking the server and selecting **Add and Remove ...** . 

Publish the services and ABL code to the server. 

You can now call the service using an HTTP client (various exist, including the ABL HTTP client) or a web browser.

The `test_multipart_test_svc.p` program is an example of ABL to call the service endpoints. Make sure that the URLs are correct.

 
##
