#
# Configuration functions
# These are meant to be exposed to users to configure their server in code.
#
function setStaticDirectory(dir)
{
    debug("static files directory set to " dir)
    _staticFiles = dir
}


function setLogLevel(level)
{
    info("setting log level to " level)
    err = _parseLogLevel(level)
    if (err)
    {
        error(err)
    }
}
    

# this gets called when the server starts
function _initConfig() 
{
    if (!_staticFiles) _staticFiles = "static"
    info("serving static files from '" _staticFiles "'")

    _pid=PROCINFO["pid"]
    debug("pid is " _pid)
    print _pid >"awkserver.pid"
    close("awkserver.pid")
}

