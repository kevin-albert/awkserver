#
# Actual server code
# Starts an infinite loop listening for incoming requests
# To handle requests, add a route (see /routes/routes.awk)
#

function startAwkServer(port)
{
    _port = port
    _initConfig()
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
        if (!_route && _method == "GET" && _endpoint)
        {
            if (_fileInStaticDirectory(_endpoint)) 
            {
                if (sendFile(_staticFiles _endpoint)) 
                {
                    debug("static: " _endpoint)
                    _route = "noop"
                }
                else {
                    debug("file not found: " _endpoint)
                }
            }
            else {
                # They tried to request a file outside the static resources directory by putting '../'s in the path
                _route = "noop"
                sendError(403, "access to " _endpoint " is not allowed")
                debug("block unauthorized access to: " _endpoint)
            }
        }
        # Default to 404
        if (!_route) {
            _route = "notFound"
            debug(_method " " _endpoint " -> " _route)
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
        else {
            _writeToSocket("Content-Length: 0" ORS)
            _writeToSocket("")
            #_writeToSocket("")
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

#
# A security check for static file routing
#
function _fileInStaticDirectory(file)
{
    split(file, _fPath, "/")
    _fIsInStatic = 1
    _fDepth = 0
    for (_fI in _fPath)
    {
        if (_fPath[_fI] == "..") _fDepth--
        else (_fDepth++)
        if (_fDepth < 0)
        {
            error("request for unauthorized file: " file)
            return 0
        }
    }
    return 1
}

