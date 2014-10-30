# awkserver
## A minimal HTTP server that runs in `gawk`
Uses special TCP files provided by gawk to implement a basic server that responds to HTTP request, serves files,
and provides an interface for custom request handling and routing. The server runs a single thread which handles
all requests. You can add your own request handling logic to `routes.awk` like:
```
END {
    ...
    addRoute("GET", "/myRoute", "myRoute")
}

...

function myRoute()
{
    info("request to /myRoute")
    doResponse("200 OK", "Hello!")
}
```
The port, static files directory and log level are set in `settings.conf`. There are some builtin functions to help
with common tasks:
### Routing functions
- `doResponse(status, response)` sends a plain text response to the current request
- `doResponse(status, response, headers)` sends a response with the specified headers
- `sendFile(filename)` sends a file as the response
- `notFound()` returns a 404
- `badRequest()` returns a 400
- `redirect(location)` sends a redirect

### Accessing a request
- `getHeader(name)` returns a header (name is case-insensitive)
- `getParam(name)` returns a param from the url query
- `getBody()` returns the request body, minus the last byte. Sorry, that's just the way it is :)

### Other functions
- `getFile(filename)` returns the contents of a file
- `info(msg)` logs an info message to stdout
- `error(msg)` logs an error message to stdout
- `debug(msg)` logs a debug message to stdout

