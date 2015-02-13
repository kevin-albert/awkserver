function _initLogs() 
{
    LogLevelError   = 2
    LogLevelInfo    = 1
    LogLevelDebug   = 0
    LogLevelAll     = -1
    LogLevel = LogLevelAll

    "which tput" | getline _TPut
    close("which tput")

    if (noLogColors)
        _disableLogColors()
    else
        _enableLogColors()

    _lvlStr[0] = "debug"
    _lvlStr[1] = "info"
    _lvlStr[2] = "error"

    debug("logging started")
}

function _parseLogLevel(logLevelStr)
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

function _enableLogColors() 
{
    if (!_TPut)
    {
        error("tput program not found. log colors disabled")
    }
    _R = _getColorFlag(1)
    _b = _getColorFlag(14)
    _G = _getColorFlag(8)
    _g = _getColorFlag(15)
    _P = _getColorFlag(13)
    _W = _getColorFlag(255)
    _lvlCol[0] = _P
    _lvlCol[1] = _b
    _lvlCol[2] = _R
}

function _getColorFlag(n)
{
    _cmd = "tput setaf " n
    _cmd | getline color
    close(_cmd)
    return color
}

function _disableLogColors()
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

