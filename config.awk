@include "log.awk"

BEGIN {
    initLogs()
    LogLevel = LogLevelAll
    debug("reading config settings")
    FS = " "

    Port = 3000
    StaticFiles = "static"
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

function parseVariable()
{
    debug("read config value: " $1 "=" $2)
    return $2
}


