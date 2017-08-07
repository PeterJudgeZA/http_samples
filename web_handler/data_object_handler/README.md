## Introduction 
The `data_object_handler` folder contains examples for using and extending the Data Object Handler (DOH). The Data Object Handler is an ABL-based Web Handler that performs generalised routing and mapping from an Http request to ABL code in classes and persistent procedures.

The DOH uses JSON configuration files to perform routing and mapping functions, and  was first shipped in 11.6.3.



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
