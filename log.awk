function initLogs() 
{
    LogLevelError   = 2
    LogLevelInfo    = 1
    LogLevelDebug   = 0
    LogLevelAll     = -1
    LogLevel = LogLevelAll

    if (noLogColors)
        disableLogColors()
    else
        enableLogColors()

    _lvlStr[0] = "debug"
    _lvlStr[1] = "info"
    _lvlStr[2] = "error"
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
        printf(_gr "[" _lvlCol[lvl] _lvlStr[lvl] _gr "]")
        
        for (i = length(_lvlStr[lvl]); i < 6; i++)
            printf(" ")

        print _Gr strftime() _gr ": " _X msg
    }
}

function enableLogColors() 
{
    _R="\033[0;31m"
    _Y="\033[0;33m"
    _G="\033[0;32m"
    _B="\033[0;34m"
    _r="\033[1;31m"
    _g="\033[1;32m"
    _b="\033[0;36m"
    _Gr="\033[2;37m"
    _gr="\033[1;37m"
    _P="\033[1;35m"
    _X="\033[0m"
    _lvlCol[0] = _P
    _lvlCol[1] = _b
    _lvlCol[2] = _R
}

function disableLogColors()
{
    printf(_X)
    _R=_Y=_G=_B=_r=_g=_b=_Gr=_gr=_P=_X=_lvlCol[0]=_lvlCol[1]=_lvlCol[2]=""
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

