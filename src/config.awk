BEGIN {
    initLogs()
    LogLevel = LogLevelAll
    debug("reading config settings")
    FS = " "

    Port = 3000
    StaticFiles = "static"
    PidDirectory = "/tmp/awkserver"
}

#
# Read in config settings
#
/^Port/ {
    if (FILENAME)
        Port = parseVariable()
}

/^StaticFiles/ {
    if (FILENAME)
        StaticFiles = parseVariable()
}

/^Logging/ {
    if (FILENAME)
        parseLogLevel(parseVariable())
}

/^PidDirectory/ {
    if (FILENAME)
    {
        PidFile = parseVariable()
        if (!match(PidFile, /\/$/))
            PidFile = PidFile "/"
        PidFile = PidFile "awkserver.pid"
    }
}

function parseVariable()
{
    #debug("read config value [" $1 "]: " $2)
    return $2
}

END {
    pid=PROCINFO["pid"]
    debug("pid is " pid)
    print pid >PidFile
    close(PidFile)
}
