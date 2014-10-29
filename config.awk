@include "log.awk"

BEGIN {
    initLogs()
    LogLevel = LogLevelAll
    debug("reading config settings")
    FS = " "
}

#
# Read in config settings
#
/^[pP]ort/ {
    if (FILENAME)
        Port = parseVariable()
}

function parseVariable()
{
    debug("read config value: " $1 "=" $2)
    return $2
}


