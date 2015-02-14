#
# Error pages
#

function notFound()
{
    sendError("404", "you've come to the wong place")
    setResponseBody("Unable to find " getRequestEndpoint() " on this server." ORS \
                    "Try https://www.google.com?q=" urlEncode(getRequestEndpoint()))
}

function badRequest()
{
    sendError("400", "wat?!")
    setResponseBody("Bad request")
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

