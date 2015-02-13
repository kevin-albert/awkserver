BEGIN {
    _initLogs()
    _LogLevel = LogLevelAll
    debug("reading config settings")
    FS = " "

    _port = 3000
    _staticFiles = "static"
    _pidDirectory = "/tmp/awkserver"
}

#
# Read in config settings
#
/^port/ {
    if (FILENAME)
        _port = _parseVariable()
}

/^staticFiles/ {
    if (FILENAME)
        _staticFiles = _parseVariable()
}

/^logLevel/ {
    if (FILENAME)
        _parseLogLevel(_parseVariable())
}

/^pidDirectory/ {
    if (FILENAME)
    {
        _pidFile = _parseVariable()
        if (!match(_pidFile, /\/$/))
            _pidFile = _pidFile "/"
        _pidFile = _pidFile "awkserver.pid"
    }
}

function _parseVariable()
{
    #debug("read config value [" $1 "]: " $2)
    return $2
}

END {
    _pid=PROCINFO["pid"]
    debug("pid is " _pid)
    print _pid >_pidFile
    close(_pidFile)
}
