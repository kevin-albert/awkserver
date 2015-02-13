END {
    _startHttpService()
}

function getRequestParam(name)
{
    return _requestParams[name]
}

function getRequestHeader(name)
{
    return _requestHeaders[tolower(name)]
}

function getRequestBody()
{
    return _requestBody
}

function setResponseStatus(status)
{
    _responseStatus = status
}

function setResponseHeader(name, value)
{
    _responseHeaders[name] = value
}

function setResponseBody(body)
{
    _responseBody = body
}

function noop(query)
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
    _contents = ""
    while (getline line < file > 0)
    {
        if (_contents) _contents = contents ORS
        _contents = _contents line
    }
    if (_contents)
    {
        close(file)
    }
    return _contents
}

function sendFile(file, headers)
{
    _contents = getFile(file)
    if (_contents)
    {
        _contentType = "text/plain" 
        switch(file) {
            case /\.html$/:
                _contentType = "text/html; charset=utf-8"
                break
            
            case /\.css$/:
                _contentType = "text/css"
                break

            case /\.js$/:
                _contentType = "application/javascript"
                break

            case /\.jpg$/:
            case /\.jpeg$/:
                _contentType = "image/jpeg"
                break
            
            case /\.png$/:
                _contentType = "image/png"
                break

            case /\.gif$/:
                _contentType = "image/gif"
                break
        
        }

        setResponseHeader("Pragma", "no-cache")
        setResponseHeader("Content-Type", _contentType)
        setResponseBody(_contents)
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

function addRoute(method, endpoint, dest)
{
    info("adding route: " method " " endpoint " -> " dest)
    _routes[method][endpoint] = dest
}


#
# Actual server code
#
function _startHttpService()
{
    _httpService = "/inet/tcp/" _port "/0/0"
    info("http server listening on port " _port)
    RS = ORS = "\r\n"

    _listen()
}

#
# This is where it gets tricky
#
function _listen()
{
    while (1)
    {
        # Loop until we have input
        while ((_httpService |& getline) == -1 || !$0)
        {
            continue
        }

        _method = $1
        _urlPieces[1] = "/"
        split($2, _urlPieces, "?")
        _endpoint = _urlPieces[1]
        _contentLength = 0
        _requestBody = ""

        _responseStatus = "200 OK"
        _responseBody = ""
        setResponseHeader("X-Powered-By", "awk")
        setResponseHeader("Connection", "close")
        setResponseHeader("Content-Type", "text/plain")

        if (!_endpoint)
        {
            error("wat? '" $0 "'") 
            while (!(_httpService |& getline) != -1) {}
            close(_httpService)
            continue
        }

        # Parse query string
        _query = _urlPieces[2]
        if (_query)
        {
            split(_query, _queryParts, "&")
            for (i in _queryParts)
            {
                split(_queryParts[i], p, "=")
                if (p[1])
                    _requestParams[urlDecode(p[1])] = 2 in p ? urlDecode(p[2]) : "true"
            }
        }

        # Parse request headers
        FS=": *"
        while ($0)
        {
            _httpService |& getline
            if ($1)
                _requestHeaders[tolower($1)] = $2
        }
        FS=" "

        # Read all but the last byte of the request body. This is due to how awk splits records - with an open http
        # stream, there is not NULL byte at the end of the body, and we don't know what to use for RS because we don't
        # know what the last character is. So, we set RS to ".{contentLength-1}" so it matches the first N-1 characters
        # and lose the last byte.
        _contentLength = getRequestHeader("content-length")
        if (_contentLength)
        {
            RS = ".{" (_contentLength - 1) "}"
            _httpService |& getline
            _requestBody = RT
            RS = "\r\n"
        }


        # Figure out how to handle this request
        _route = _routes[_method][_endpoint]

        if (_route) 
        {
            debug(_method " " _endpoint " -> " _route)
        }

        # Check for file
        if (!_route && _method == "GET" && _endpoint && shouldSendFile(_endpoint) && sendFile(_staticFiles _endpoint)) 
        {
            debug("static: " _endpoint)
            _route = "noop"
        }
        # Default to 404
        if (!_route) {
            _route = "notFound"
            debug(_method " " _endpoint " -> " route)
        }

        # Call the routing function
        @_route()

        # Write the response headers
        _writeToSocket("HTTP/1.0 " _responseStatus)
        for (_header in _responseHeaders)
        {
            _writeToSocket(_header ": " _responseHeaders[header])
        }
    
        # Write the response body
        if (_responseBody)
        {
            _writeToSocket("Content-Length: " length(_responseBody ORS))
            _writeToSocket("")
            _writeToSocket(_responseBody)
        }

        # Close the socket and get ready for the next connection
        close(_httpService)

        # Clear these arrays for next time
        delete _requestParams
        delete _requestHeaders
        delete _urlPieces
        delete _responseHeaders
    }
}

function _writeToSocket(line) {
    print line |& _httpService
}

