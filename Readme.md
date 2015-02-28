# awkserver
## An HTTP server that runs in awk
Basic HTTP server implementation using the TCP stack provided by gawk. Example:
```awk
#
# hello.awk
# usage:
# - gawk -f hello.awk
# - open up localhost:3001 in your browser
#

@include "src/awkserver.awk"

function hello()
{
    setResponseBody("Hello!")
}

BEGIN {
    addRoute("GET", "/", "hello")   # route requests on "/" to the function "hello()"
    startAwkServer(3001)            # start listening. this function never exits
}
```

This just sends a plain text response "Hello!". To accomplish more, look at the API:

### Routing functions
- `setResponseStatus(statusLine)` sets the returned status string
- `setResponseHeader(name, value)` sets an outgoing response header
- `setResponseBody(body)` sets the outgoing response body
- `sendFile(filename)` sends a file as the response
- `notFound()` returns a 404
- `badRequest()` returns a 400
- `redirect(location)` sends a redirect
- `addRoute(method, endpoint, callback)` when `endpoint` is called with the given method, then `callback()` is invoked with no parameters. Only one callback function per method/endpoint pair.

All routing functions are in `src/core.awk`

### Accessing a request
- `getRequestHeader(name)` returns a header (name is case-insensitive)
- `getRequestParam(name)` returns a param from the url query
- `getRequestBody()` returns the request body, minus the last byte
- `getRequestEndpoint()` returns the incoming request endpoint

All request functions are also in `src/core.awk`

### Other functions
- `getFile(filename)` returns the contents of a file (`src/core.awk`)
- `info(msg)`, `error(msg)`, `debug(msg)` print formatted logs (`src/log.awk`)
- `setStaticDirectory(dir)` choose the directory to serve static files from. defaults to "static" (`src/config.awk`)
- `setLogLevel(level)` set the log level ("debug", "info", "error") (`src/log.awk`)
- **NEW!** `parseJson(input, mapRef, keysRef)` parses the contents of a JSON string (`modules/json-parser.awk`)

## Purpose
This goal of this project is to provide users with the ability to bring up a very basic HTTP server with minimal effort. It does not do templating, security, or encryption, and no matter what you do the last character of every incoming request body will be dropped (due to how awk splits records). You have been warned.

## How it works
The function `startAwkServer(port)` begins an infinite loop serving all incoming requests on a single thread. Requests are handled in this fashion:
- Incoming request headers, query params, and endpoint are parsed.   
- Request body is buffered in memory.  
- Routing function lookup:
  - The server checks the routing table for a user defined route function (see `addRoute(method, endpoint, callback)` in `src/core.awk`)  
  - If no route exists, the server then tries to resolve the endpoint to a file in the static files directory (see `setStaticDirectory(dir)` above)  
  - If that fails, the route is resolved to a 404 error.
- The routing function is called. It is assumed that the routing function will set the response headers / status / body
- The response is compiled and sent.
- Now we are ready to handle another request.

This request handling code can be found in `src/http.awk`

## Requirements
- GNU Awk 4.0.0 or later
- Patience
