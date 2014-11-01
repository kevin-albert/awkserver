BEGIN {
    info("starting http server")
    print PROCINFO["pid"] > "awkserver.pid"
    close("awkserver.pid")
}

END {
    close(FILENAME)
    startHttpService()
}

function startHttpService()
{
    HttpService = "/inet/tcp/" Port "/0/0"
    info("http server listening on port " Port)
    RS = ORS = "\r\n"

    listen()
}

function listen()
{
    while (1)
    {
        # Loop until we have input
        while ((HttpService |& getline) == -1 || !$0)
        {
            continue
        }

        Method = $1
        urlPieces[1] = "/"
        split($2, urlPieces, "?")
        Endpoint = urlPieces[1]
        ContentLength = 0
        RequestBody = ""
        HasFormData = 0
        FormData["x"] = "x"
        delete FormData
        hasFormData = 0

        ResponseStatus = "200 OK"
        ResponseBody = ""
        setResponseHeader("X-Powered-By", "awk")
        setResponseHeader("Connection", "close")
        setResponseHeader("Content-Type", "text/plain")

        if (!Endpoint)
        {
            error("wat? '" $0 "'") 
            while (!(HttpService |& getline) != -1) {}
            close(HttpService)
            continue
        }

        # Parse Query string
        Query = urlPieces[2]
        if (Query)
        {
            split(Query, queryParts, "&")
            for (i in queryParts)
            {
                split(queryParts[i], p, "=")
                if (p[1])
                    RequestParams[urlDecode(p[1])] = 2 in p ? urlDecode(p[2]) : "true"
            }
        }

        # Parse request headers
        FS=": *"
        while ($0)
        {
            HttpService |& getline
            if ($1)
                RequestHeaders[tolower($1)] = $2
        }
        FS=" "

        # Read all but the last byte of the request body. This is due to how awk splits records - with an open http
        # stream, there is not NULL byte at the end of the body, and we don't know what to use for RS because we don't
        # know what the last character is. So, we set RS to ".{contentLength-1}" so it matches the first N-1 characters
        # and lose the last byte.
        ContentLength = getRequestHeader("content-length")
        if (ContentLength)
        {
            RS = ".{" (ContentLength - 1) "}"
            HttpService |& getline
            RequestBody = RT
            RS = "\r\n"
        }


        # Figure out how to handle this request
        route = routes[Method][Endpoint]

        if (route) 
        {
            debug(Method " " Endpoint " -> " route)
        }

        # Check for file
        if (!route && Method == "GET" && Endpoint && shouldSendFile(Endpoint) && sendFile(StaticFiles Endpoint)) 
        {
            debug("static: " Endpoint)
            route = "noop"
        }
        # Default to 404
        if (!route) {
            route = "notFound"
            debug(Method " " Endpoint " -> " route)
        }

        # Call the routing function
        @route()

        # Write the response headers
        writeToSocket("HTTP/1.0 " ResponseStatus)
        for (header in ResponseHeaders)
        {
            writeToSocket(header ": " ResponseHeaders[header])
        }
    
        # Write the response body
        if (ResponseBody)
        {
            writeToSocket("Content-Length: " length(ResponseBody ORS))
            writeToSocket("")
            writeToSocket(ResponseBody)
        }

        # Close the socket and get ready for the next connection
        close(HttpService)

        # Clear these arrays for next time
        delete RequestParams
        delete RequestHeaders
        delete urlPieces
        delete ResponseHeaders
    }
}

function getRequestParam(name)
{
    return RequestParams[name]
}

function getRequestHeader(name)
{
    return RequestHeaders[tolower(name)]
}

function getRequestBody()
{
    return RequestBody
}

function parseForm()
{
    delete FormData
    split(getRequestBody(), entries, "&")
    for (i in entries)
    {
        split(entries[i], XX, "=")
        FormData[urlDecode(XX[1])] = urlDecode(XX[2])
    }
}

function getFormParam(name)
{
    if (!hasFormData)
    {
        parseForm()
        hasFormData = 1
    }
    return FormData[name]
}

function setResponseStatus(status)
{
    ResponseStatus = status
}

function setResponseHeader(name, value)
{
    ResponseHeaders[name] = value
}

function setResponseBody(body)
{
    ResponseBody = body
}

function writeToSocket(line) {
    print line |& HttpService
}

function noop(Query)
{
    # This request has been handled.
    # do nothing
}

function shouldSendFile(file)
{
    return !match(file, /\.\./)
}

function getFile(file)
{
    contents = ""
    while (getline line < file > 0)
    {
        if (contents) contents = contents ORS
        contents = contents line
    }
    if (contents)
    {
        close(file)
    }
    return contents
}

function sendFile(file, headers)
{
    contents = getFile(file)
    if (contents)
    {
        contentType = "text/plain" 
        switch(file) {
            case /\.html$/:
                contentType = "text/html; charset=utf-8"
                break
            
            case /\.css$/:
                contentType = "text/css"
                break

            case /\.js$/:
                contentType = "application/javascript"
                break

            case /\.jpg$/:
            case /\.jpeg$/:
                contentType = "image/jpeg"
                break
            
            case /\.png$/:
                contentType = "image/png"
                break

            case /\.gif$/:
                contentType = "image/gif"
                break
        
        }

        setResponseHeader("Pragma", "no-cache")
        setResponseHeader("Content-Type", contentType)
        setResponseBody(contents)
        return 1
    }

    return 0
}

function notFound()
{
    sendError("404", "you've come to the wong place")
}

function badRequest()
{
    sendError("400", "wat?!")
}

function sendError(code, status)
{
    setResponseStatus(code " " status)
}

function redirect(location)
{
    setResponseHeader("Location", location)
    setResponseStatus("303 redirect")
}

function addRoute(Method, Endpoint, dest)
{
    info("adding route: " Method " " Endpoint " -> " dest)
    routes[Method][Endpoint] = dest
}


