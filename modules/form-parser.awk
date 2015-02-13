#
# Parse standard URI encoded forms:
#   key1=some%20value
#   key2=some+other+value
# etc
#

function parseForm(_fData, _fOutputData) 
{
    split(_fData, _fEntries, "&")
    for (_fI in _fEntries)
    {
        split(_fEntries[_fI], _fParam, "=")
        _fOutputData[urlDecode(_fParam[1])] = urlDecode(_fParam[2])
    }
}

