function initLogs() 
{
    LogLevelError   = 2
    LogLevelInfo    = 1
    LogLevelDebug   = 0
    LogLevelAll     = -1
    LogLevel = LogLevelAll

    "which tput" | getline TPut
    close("which tput")

    if (noLogColors)
        disableLogColors()
    else
        enableLogColors()

    _lvlStr[0] = "debug"
    _lvlStr[1] = "info"
    _lvlStr[2] = "error"

    debug("logging started")
}

function parseLogLevel(logLevelStr)
{
    switch (logLevelStr)
    {
        case "Debug":
            LogLevel = LogLevelDebug
            break
        case "Info":
            LogLevel = LogLevelInfo
            break
        case "Error":
            LogLevel = LogLevelError
            break
    }
}


function _log(msg, lvl) {
    if (lvl >= LogLevel) 
    {
        printf(_g "[" _lvlCol[lvl] _lvlStr[lvl] _g "]")
        
        for (i = length(_lvlStr[lvl]); i < 6; i++)
            printf(" ")

        print _G strftime() _g ": " _W msg
    }
}

function enableLogColors() 
{
    if (!TPut)
    {
        error("tput program not found. log colors disabled")
    }
    _R = getColorFlag(1)
    _b = getColorFlag(14)
    _G = getColorFlag(8)
    _g = getColorFlag(15)
    _P = getColorFlag(13)
    _W = getColorFlag(255)
    _lvlCol[0] = _P
    _lvlCol[1] = _b
    _lvlCol[2] = _R
}

function getColorFlag(n)
{
    cmd = "tput setaf " n
    cmd | getline color
    close(cmd)
    return color
}

function disableLogColors()
{
    _R=_b=_G=_g=_P=_W=_lvlCol[0]=_lvlCol[1]=_lvlCol[2]=""
}

function debug(msg)
{
    _log(msg, LogLevelDebug)
}

function info(msg)
{
    _log(msg, LogLevelInfo)
}

function error(msg)
{
    _log(msg, LogLevelError)
}

