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
    if (!Port) Port = 3001
    Client = "/inet/tcp/0/proxy/80"
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

        method = $1
        urlPieces[1] = "/"
        split($2, urlPieces, "?")
        endpoint = urlPieces[1]
        contentLength = 0
        if (!endpoint)
        {
            error("wat? (" $0 ")")
            while ($0) 
            {
                HttpService |& getline
            }
            notFound(query)
            close(HttpService)
            continue
        }

        # parse query string
        query = urlPieces[2]
        if (query)
        {
            split(query, queryParts, "&")
            for (i in queryParts)
            {
                split(queryParts[i], p, "=")
                if (p[1])
                    requestParams[p[1]] = p[2] ? p[2] : "true"
            }
        }

        # parse headers
        FS=": *"
        while ($0)
        {
            HttpService |& getline
            if ($1)
                requestHeaders[tolower($1)] = $2
        }
        FS=" "
        contentLength = getHeader("content-length")
        if (!contentLength) contentLength = 0


        # figure out how to handle
        debug("routing")
        route = routes[method][endpoint]

        if (route) 
        {
            debug(method " " endpoint " -> " route)
        }

        # check for file
        if (!route && method == "GET" && endpoint && isInStatic(endpoint) && sendFile("static" endpoint)) 
        {
            debug("static: " endpoint)
            route = "noop"
        }
        # default to 404
        if (!route) {
            route = "notFound"
            debug(method " " endpoint " -> " route)
        }

        @route(query)

        close(HttpService)

        for (i in requestParams)
            delete requestParams[i]
        for (i in requestHeaders)
            delete requestHeaders[i]
        for (i in urlPieces)
            delete urlPieces[i]
    }
}

function getParam(name)
{
    return requestParams[name]
}

function getHeader(name)
{
    return requestHeaders[tolower(name)]
}

function read() {
    if (contentLength <= 0)
        return

    HttpService |& getline
    contentLength -= length($0)
    contentLength -= 2
}

function write(line) {
    print line |& HttpService
}

function doResponse(status, response, headers)
{
    debug("sending response")
    if (getHeader("content-length"))
    {
        debug("flushing request")
        while (read())
        {
            continue
        }
    }

    write("HTTP/1.0 " status)
    headers["Connection"] = "close"
    for (header in headers)
        write(header ": " headers[header])

    if (response)
    {
        write("Content-Length: " length(response ORS))
        write("")
        write(response)
    }

}

function noop(query)
{
    # This request has been handled.
    # do nothing
}

function isInStatic(file)
{
    return !match(file, /\.\./)
}

function sendFile(file, headers)
{
    debug("sendFile(" file ")")
    if (getline line < file != -1)
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
        res = line

        while (getline line < file > 0) 
            res = res ORS line
       
        close(file)
        doResponse("200 OK", res, headers)
        return 1
    }
    else 
    {
        error("file not found: '" + file + "'")
    }

    return 0
}
