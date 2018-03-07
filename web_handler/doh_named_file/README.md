## Introduction 
The `doh_named_file` folder contains examples for reading and writing imaged using the Data Object Handler (DOH). The Data Object Handler is an ABL-based Web Handler that performs generalised routing and mapping from an Http request to ABL code in classes and persistent procedures. The DOH uses JSON configuration files to perform routing and mapping functions, and  was first shipped in 11.6.3.

## Server setup / installation
You will need one PASOE instance, 11.6.3 or newer. You can use an existing PASOE instance, or create one in OE Explorer/Manager or via the `tcman create` CLI tool. Add this server to PDSOE's Servers view.


Download the code from GitHub. Import the project into an PDSOE workspace via **File > Import > Existing Projects into Workspace**. This will bring all the code, images and configuration files into the project. These files are **not** in the structure required for deployment/use in PASOE.


## NamedFileSvc
The **`NamedFileSvc`** service passes image messages (request/response entities) to, and receives from, an ABL Service. Images have a content (MIME) type of `image/png` or `image/jpeg` or similar; client often expect to know the name of the image. This example services illustrates this approach. Note that while this example shows images, it can easily be changed to work with other types of files too: just change the `contentType` property.

The code for this test service is in the `doh_named_file` folder. The service comprises of

1. The `NamedFile.cls` ABL class that process the multipart entities.
2. The `NamedFileSvc.map` mapping file that defines the service interfaces into the above. There are three endpoints defined
    1. `GET /NamedFileSvc/bytes`: This operation returns a message with a `image/png` body and a name of `communities.png`. 
This operations calls the `ReadNamedImage` method in the class, and receives a Content-Disposition header object and the image file in binary form (an `OpenEdge.Core.Memptr` object).
    2. `GET /NamedFileSvc/stream`: This operation returns a message with a `image/png` body  and a name of `communities.png`. 
This operations calls the `ReadNamedStream` method in the class, and receives a Content-Disposition header object and the image file in the form of a `Progress.IO.FileInputStream` object. **NOTE: This will only work with 11.7.2 and later**
    3. `GET /NamedFileSvc/bytes/charHeader`: This operation returns a message with a `image/png` body and a name of `communities.png`. 
This operations calls the `ReadNamedImage` method in the class, and receives the value of the Content-Disposition as a character value, and the image file in binary form (an `OpenEdge.Core.Memptr` object). This is basically the same as the first operation, without the service having to worry about how to create the header object.



### Installation
### The (Very) Ugly Way
This approach is good for showing the functionality at work but makes updates/development/fiddling difficult.

1. Copy the `NamedFile.cls` and `NamedFileSvc.map` files into a webapp's `WEB-INF/openedge`  folder. 
2. Make sure that the DOH is configured for the webapp above. Make sure that the `conf/openedge.properties` file contains the following. The _N_ in the handler definition must be a contiguous integer value.

>[<abl-app-name>.<web-app-name>.WEB]

>handler_N_=OpenEdge.Web.DataObject.DataObjectHandler : /pdo


#### The Good Way 
Create a new ABL Service for the images and select the WebSpeed (WebHandler) option from the Service Type radio set.
1. Name it something like `NamedFileSvc` although the name doesn't really matter
2. Select an existing WebHandler and specify or select `OpenEdge.Web.DataObject.DataObjectHandler`
3. Add a Resource URI of `/pdo/`
4. Click Finish to add the service

Copy the code (.cls and .map) from the `doh_named_file` folder into the `PASOEContent/WEB-INF/openedge' folder.

Add the service and the ABL module to the PASOE server. You can do this by right-clicking the server and selecting **Add and Remove ...** . 

Publish the services and ABL code to the server. 

You can now call the service using an HTTP client (various exist, including the ABL HTTP client) or a web browser.

The `test_multipart_test_svc.p` program is an example of ABL to call the service endpoints. Make sure that the URLs are correct.

 
##
