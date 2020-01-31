## Introduction 
The `content_types` folder contains WebHandlers and other classes that illustrate consuming and producing various content types.

## Examples & usage
To use these examples, make sure they're in PROPATH for the ABL application. This should be one of $CATALINA_BASE/openedge or $CATALINA_BASE/webapps/<current-web-app>/WEB-INF/openedge , although anywhere on PROPATH will do.

The handler needs to be configured for to process a URI ; to do this add an entry in the openedge.properties file either manually or using OpenEdge Explorer/Management.

### PdfHandler
This handler returns a PDF named `README.pdf` in response to a GET request, and reads binary/PDF data from a PUT request. The PDF does not exist, so this example will not run as-is.
