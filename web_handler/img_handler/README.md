## Introduction 
The `img_handler` folder contains an example of a WebHandler for returning Employee data (from Sports2000) as well as working with employee images.

There are 2 services in this folder: the first is for returning employee data in JSON format. Each employee has a photo and these are accessed and updated via the second service.
The JSON data returned from the data service contains references to the images inthe `ttEmployee.EmpPhoto` field. These references are stringified JSON and are known as a media link entry.

The Atom Publishing Protocol (RFC5023) defines media resources and media link entries in section 9.6. Atom forms the basis for OData and as such informs and guides this design.  From that RFC,

- Member (or Member Resource) - A Resource whose IRI is listed in a Collection by an atom:link element with a relation of "edit" or "edit-media".  The protocol defines two kinds of Members:
	- Entry Resource - Members of a Collection that are represented as Atom Entry Documents, as defined in RFC4287.
	- Media Resource - Members of a Collection that have representations other than Atom Entry Documents.
- Media Link Entry (MLE) - An Entry Resource that contains metadata about a Media Resource (MR).

The OData protocol describes how media entities should be managed in section 11.4.7 of its protocol spec.

An example employee record is below.


	{ "dsEmployee": {
	    "ttEmployee": [ {
	      "EmpNum": 1,
	      	"LastName": "Koberlein",
		"FirstName": "123*Kelly",
		"Birthdate": null,
		"StartDate": "1997-05-06",
		"EmpPhoto": "{\"src\":\"\\/web\\/img\\/Employee\\/1\",\"edit-media\":	\"\\/web\\/img\\/Employee\\/1\"}"
	},

The de-stringified media link data looks like 

	{
		"src": "/web/img/Employee/1",
		"edit-media": "/web/img/Employee/1"
	}

The `sports.ImageWebHandler`'s `HandleGet` method contains code that inspects the incoming request and decides how to return the image data: as a straight image with a Content-Type of image/png or as a multipart message.

The `HandleException` and `WriteError` methods are an example of how to write an error. In 11.6.3+  much of this work is done in the `OpenEdge.Net.HTTP.Filter.Payload.JsonEntityWriter` calls which provides a standard format for errors. To use this writer you can simply assign the error as the response's Entity.

## Setup / installation
You will need one PASOE instance, 11.6.0 or newer. 11.6.3 if you want to use/play with the new DataObjectHandler. Create the PASOE instance in OE Explorer/Manager or via the `tcman create` CLI tool. Add this server to PDSOE's Servers view.

Create (or use and existing) copy of the sports2000 database in the appropriate version.

Download the code from GitHub. Import the project into an PDSOE workspace via **File > Import > Existing Projects into Workspace**. This will bring all the code, images and configuration files into the project. These files are **not** in the structure required for deployment/use in PASOE.

All code is in the `sports` folder. All images are in the `resources` folder. The EmployeeSvc.gen (data object mapping) and ~.json (Data service catalog) files are in the root folder and are provided in case you don't have 11.6.3+ and want to look over them.

When you add a new ABL Service or an OpenEdge Project (ABL WebApp) you may be asked for an AppServer folder. Change this to `src`. If you don't you'll have to move the ABL code into the folder `AppServer` for publication to PASOE.

### Steps
Create two (2) ABL Services for images and for data
1. Create a new ABL Service for the images and select the WebSpeed (WebHandler) option from the Service Type radio set.
	1. Name it something like `ImageSvc` although the name doesn't really matter
	2. Select an existing WebHandler and specify or select `sports.ImageWebHandler`
	3. Add a Resource URI of `/img/Employee/{EmpNum}`
	4. Click Finish to add the service
2. Create a new ABL Service for the data and select the Data Object (Annotated RPC) option
	1. You must name it `EmployeeSvc`
	2. In 11.6.3+ you have a choice between using a WebHandler and REST RPC. Selecting the WebHandler option means you will use the DataObjectHandler. 
	3. Select sports.EmployeeBE from the next resource
	4. Click Finish to add the service

Make sure you've added the two services and the ABL module to the PASOE server. You can do this by right-clicking the server and selecting **Add and Remove ...** . 

Publish the services and ABL code to the server.

After deployment, your instance structure should look like the below (some stuff removed for clarity). You may need to copy the `resources` folder from PDSOE to the instance. It's also acceptable for the ImageWebHandler to be in the `${CATALINA_BASE}/openedge/sports` folder.

	${CATALINA_BASE}
	+---bin
	+---common
	+---conf
	        openedge.properties
	+---logs
	+---openedge
	|   +---resources
	|   |       emp_1.png  … emp_22.png
	|   |       emp_img_map.json
	|   \---sports
	|           EmployeeBE.cls
	|           employeebe.i
	+---temp
	+---webapps
	|   +---ROOT
	|   |   +---META-INF
	|   |   +---static
	|   |   |   +---auth
	|   |   |   +---error
	|   |   |   +---images
	|   |   \---WEB-INF
	|   |       +---openedge
	|           |   |   EmployeeSvc.gen
	|   |       |   \---sports
	|   |       |           ImageWebHandler.cls
	|   |       \---tlr
	\---work

 
##
