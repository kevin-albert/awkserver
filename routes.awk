
#
# each route is a function that calls doResponse() or sendFile() or something
# added to the routes table via addRoute()
#

END {
    addRoute("GET", "/", "home")
}

function home()
{
    sendFile("static/index.html")
}

