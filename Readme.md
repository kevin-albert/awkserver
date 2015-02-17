# awkserver
## A minimal HTTP server that runs in `gawk`
Uses TCP files provided by gawk to implement a basic server that responds to HTTP request, serves files,
and routes requests to user defined functions. Create `hello.awk` like:
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

## How it works
The function `startAwkServer(port)` begins an infinite loop serving all incoming requests on a single thread. Requests are handled by:
- First checking the routing table for a user defined route function (see `addRoute(method, endpoint, callback)` in `src/core.awk`)  
- Then trying to serve the request from the static files directory (see `setStaticDirectory(dir)` above)  
- Then failing with a 404  

After the route is resolved, the response (status, headers, and content) are set. Because of this, routing functions do not need to worry about calling response functions in a particular order or multiple times. Routing functions are just responsible for setting the response *state*. The server will send it afterwards.

