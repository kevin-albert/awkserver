#
# each route is a function that gets called during an inbound request.
# it can get request data with calls to getHeader(), getParam(), and read()
# call doResponse() to send the response when you're done (or sendFile() to serve a static file)
#

END {
    addRoute("GET", "/", "home")
    addRoute("POST", "/login", "login")
}

function home()
{
    sendFile("static/index.html")
}

function login()
{
    body = getBody()
    split(body, form, "&")
    res = ""
    for (i in form) 
    {
        split(form[i], param, "=")
        if (param[1] != "xxx")
            res = res param[1] ": " param[2] "\r\n"
    }
    headers["content-type"] = "text/plain"
    doResponse("200 OK", res, headers)
}
