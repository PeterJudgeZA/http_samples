This repo contains samples and doc describing how to work with the OpenEdge HTTP Client and Web Handler features.

API doc for both is at [https://documentation.progress.com/output/oehttpclient/](https://documentation.progress.com/output/oehttpclient/)  

The HTTP client and the Web Handlers share a common approach and set of interfaces for working with HTTP messages. 

## HTTP Client
An ABL-based HTTP client was added to OE in 11.5.1. This client is intended for use as an API client to call REST and other HTTP-based services from ABL. 

## Web Handler
In OE 11.6.0 the PASOE server added the ability to accept 'plain old' HTTP requests over the WEB transport. Application and other developers are expected to write ABL code to handle the incoming requests, call business logic and return a response.    


## Prerequisites
In order to compile/use this ABL code you MUST ensure that the OpenEdge.Net.pl procedure library appears in PROPATH. It can be found in `$DLC/tty/netlib`, `$DLC/gui/netlib` and `$DLC/src/netlib` , with the first two being r-code and the latter source code. 

## Contributions
Pull requests are happily accepted. Each example/sample should be in its own folder under `http_client` or `web_handler` unless you find bugs and/or want to extend those examples. You MUST provide a README.md in the sample folder to be considered for inclusion.
