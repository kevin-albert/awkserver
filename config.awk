BEGIN {
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
    debug($1 "=" $2)
    return $2
}


