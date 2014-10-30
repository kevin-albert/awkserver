BEGIN {
    info("starting http server")
}

@include "log.awk"
@include "config.awk"
@include "routes.awk"

END {
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
        HttpService |& getline

        Method = $1
        urlPieces[1] = "/"
        split($2, urlPieces, "?")
        Endpoint = urlPieces[1]
        ContentLength = 0
        Body = ""
        if (!Endpoint)
        {
            error("wat? request: '" $0 "'") 
            while ($0) 
            {
                HttpService |& getline
            }
            notFound()
            close(HttpService)
            continue
        }

        # parse Query string
        Query = urlPieces[2]
        if (Query)
        {
            split(Query, queryParts, "&")
            for (i in queryParts)
            {
                split(queryParts[i], p, "=")
                if (p[1])
                    RequestParams[p[1]] = 2 in p ? p[2] : "true"
            }
        }

        # parse headers
        FS=": *"
        while ($0)
        {
            HttpService |& getline
            if ($1)
                RequestHeaders[tolower($1)] = $2
        }
        FS=" "

        ContentLength = getHeader("content-length")
        if (ContentLength)
        {
            RS = ".{" (ContentLength - 1) "}"
            HttpService |& getline
            Body = RT
            RS = "\r\n"
        }

        # figure out how to handle
        route = routes[Method][Endpoint]

        if (route) 
        {
            debug(Method " " Endpoint " -> " route)
        }

        # check for file
        if (!route && Method == "GET" && Endpoint && shouldSendFile(Endpoint) && sendFile(StaticFiles Endpoint)) 
        {
            debug("static: " Endpoint)
            route = "noop"
        }
        # default to 404
        if (!route) {
            route = "notFound"
            debug(Method " " Endpoint " -> " route)
        }

        # call the routing function
        @route()

        close(HttpService)

        for (i in RequestParams)
            delete RequestParams[i]
        for (i in RequestHeaders)
            delete RequestHeaders[i]
        for (i in urlPieces)
            delete urlPieces[i]
    }
}

function getParam(name)
{
    return RequestParams[name]
}

function getHeader(name)
{
    return RequestHeaders[tolower(name)]
}

function getBody()
{
    return Body
}

function write(line) {
    print line |& HttpService
}

function doResponse(status, response, headers)
{
    write("HTTP/1.0 " status)
    headers["Connection"] = "close"
    for (header in headers)
    {
        write(header ": " headers[header])
        delete headers[header]
    }

    if (response)
    {
        write("Content-Length: " length(response ORS))
        write("")
        write(response)
    }
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

        headers["Content-Type"] = contentType
        doResponse("200 OK", contents, headers)
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
    sendError("400", "wat?!", headers)
}

function sendError(code, status)
{
    headers["Connection"] = "close"
    doResponse(code " " status, "", headers)
}

function redirect(location)
{
    headers["Location"] = location
    doResponse("303 redirect", "", headers)
}

function addRoute(Method, Endpoint, dest)
{
    info("adding route: " Method " " Endpoint " -> " dest)
    routes[Method][Endpoint] = dest
}


