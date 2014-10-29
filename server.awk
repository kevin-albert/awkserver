BEGIN {
    info("starting http server")
}

@include "log.awk"
@include "config.awk"
@include "routes.awk"

END {
    startServer()
}

function startServer()
{
    if (!Port) Port = 3001
    Client = "/inet/tcp/0/proxy/80"
    Server = "/inet/tcp/" Port "/0/0"
    info("http server listening on port " Port)
    RS = ORS = "\r\n"

    listen()
}

function listen()
{
    while (1)
    {
        Server |& getline

        method = $1
        urlPieces[0] = "/"
        split($2, urlPieces, "?")
        endPoint = urlPieces[1]
        if (!endPoint)
        {
            error("wat? " $0)
            notFound(query)
            close(Server)
            continue
        }

        query = urlPieces[2]
        route = routes[method][endPoint]

        # check for file
        if (!route && endPoint) 
        {
            if (method == "GET" && serveFile("static" endPoint))
            {
                debug("static: " endPoint)
                route = "noop"
            }
        }
        if (!route)
        {
            route = "notFound"
        }
        
        if (route != "noop")
            debug(endPoint " -> " route)

        @route(query)
        close(Server)
    }
}


function doResponse(status, response, headers)
{
    while ($0) {
        Server |& getline
    }
    debug("flushed server")

    print "HTTP/1.0 " status |& Server
    headers["Connection"] = "close"
    for (header in headers)
        print header ": " headers[header] |& Server

    if (response)
    {
        print "Content-Length: " length(response ORS) |& Server
        print |& Server
        print response |& Server
    }
}

function noop(query)
{
    # This request has been handled.
    # do nothing
}

function serveFile(file, headers)
{
    if (!match(file, /\.\./) && getline < file != -1)
    {
        contentType = "text/plain" 
        switch(file) {
            case /\.html$/:
                contentType = "text/html; charset=utf-8"
                break;
            
            case /\.css$/:
                contentType = "text/css"
                break;

            case /\.js$/:
                contentType = "application/javascript"
                break;

            case /\.jpg$/:
            case /\.jpeg$/:
                contentType = "image/jpeg"
                break;
            
            case /\.png$/:
                contentType = "image/png"
                break;

            case /\.gif$/:
                contentType = "image/gif"
                break;
        
        }

        headers["Content-Type"] = contentType
        res = $0

        while (getline < file) 
            res = res ORS $0
       
        doResponse("200 OK", res, headers)
        return 1
    }

    return 0
}
