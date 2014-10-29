#
# each route is a function that calls doResponse() or sendFile() or something
# added to the routes table via addRoute()
#
END {
    addRoute("GET", "/", "home")
}

function home(Query)
{
    debug("sending home page")
   sendFile("static/index.html")
}

function notFound(Query)
{
    headers["Content-Type"] = "text/plain"
    doResponse("404 Not Found", "you've come to the wong place", headers)
}

function addRoute(method, endpoint, dest)
{
    info("adding route: " method " " endpoint " -> " dest)
    routes[method][endpoint] = dest
}

