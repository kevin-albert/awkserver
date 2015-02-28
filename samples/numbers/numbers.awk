#
# Confusing number translator, borrowed from https://github.com/54kevinalbert/number
# usage: cd ../../ && gawk -f samples/numbers/numbers.awk
#

@include "src/awkserver.awk"

function home()
{
    sendFile("samples/numbers/static/index.html")
}


BEGIN {
    info("adding routes for sample app")
    addRoute("GET", "/", "home")
    setStaticDirectory("samples/numbers/static")
    startAwkServer("3001")
}
