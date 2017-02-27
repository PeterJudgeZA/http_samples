## Introduction 
The `redirect` folder contains classes that illustrate returning redirects from the PASOE WEB transport.

## Examples & usage
To use these examples, make sure they're in PROPATH for the ABL application. This should be one of $CATALINA_BASE/openedge or $CATALINA_BASE/webapps/<current-web-app>/WEB-INF/openedge , although anywhere on PROPATH will do.

The handler needs to be configured for to process a URI ; to do this add an entry in the openedge.properties file either manually or using OpenEdge Explorer/Management.

### RedirectWebHandler
This handler builds a response to return a 302/Found status and a Location header set to the www.example.com/ + the Path and Query strings from the incoming URI.

This handler redirects all requests. A more sophisticated handler might onl redirect GET requests or those with certain ContentType values.
