#
# Error pages
#

function noop(query)
{
    # This request has been handled.
    # do nothing
}


function notFound()
{
    setResponseStatus("404 you've come to the wong place")
    setResponseHeader("Content-Type", "text/html")
    setResponseBody("<html><head><title>fail</title></head><body>" \
                    "<p>Unable to find " getRequestEndpoint() " on this server.</p>" \
                    "<p>Try <a href='https://www.google.com?q=" urlEncode(getRequestEndpoint()) "'>google</a>" \
                    "</p></body></html>")
}


function badRequest()
{
    setResponseStatus("400 wat")
    setResponseBody("Bad request")
}


function redirect(location)
{
    setResponseHeader("Location", location)
    setResponseStatus("303 redirect")
}

