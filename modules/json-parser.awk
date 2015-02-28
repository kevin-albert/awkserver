#
# Parse a JSON string into a map with and a list of ordered keys. Uses a straight map instead of a tree structure to
# represent a JSON object or array. Access an element of the map directly, iterate through its keys to do a search,
# or iterate through the keys list to access the elements in the order they were provided
#
# example:
# 
# err = parseJson("{\"foo\":\"bar\",\"baz\":[\"zork\",13.6,null],\"fail\":{\"now\":true,\"later\":false}}",
#                 map, 
#                 keys)
# if (err)
# {
#   print err
#   exit
# } 
# else {
#   print "fail now? " map["fail.now"]
#   for (k in keys)
#   {
#     print keys[k] ": " map[keys[k]]
#   }
# }
#
# output:
# fail now? true
# foo: bar
# baz[0]: zork
# baz[1]: 13.6
# baz[2]: null
# fail.now: true
# fail.later: false
#
# @author Kevin Albert | salamander.hammerhead@gmail.com
#


function parseJson(_jInput, _jOutputData, _jOutputKeys) 
{
    delete _jOutputData
    delete _jOutputKeys
    delete _jTypes
    delete _jKeys
    delete _jIndices

    # split into chars
    split(_jInput, _jData, "")
    _jLen = length(_jInput)
    _jSP = 0            # stack pointer
    _jIdx = 1           # char idx
    _jC = ""            # current char
    _jIsEsc = 0         # is current _jC being escaped?
    _jIsKey = 0         # key or value?
    _jIsStr = 0         # string or code?
    _jStrStart = 0      # start of currently parsed string
    _jIndices[0] = 0    # current array index
    _jNKeys = 0         # total number of keys
    _jHasRoot = 0       # ensure that we only parse one root object
    
    while (match(_jData[_jIdx], /[ \t\r\n]/)) _jIdx++

    # Main loop
    while (_jIdx <= _jLen) 
    {
        _jC = _jData[_jIdx]
    
        # if _jSP > 0, then we've started an object or an array and basic parsing rules apply
        if (_jSP) 
        {
            # Escape character
            if (_jC == "\\") 
            {
                if (_jIsStr) 
                {
                    if (_jIsEsc) _jIsEsc = 0
                    else _jIsEsc = 1
                }
                else {
                    return "fail: out of place backslash at index " _jIdx
                }
            } 

            # Double quote
            else if (_jC == "\"" && !_jIsEsc) 
            {
                if (!_jIsStr) 
                {
                    # String start
                    _jStrStart = _jIdx + 1
                    _jIsStr = 1

                    if (!_jIsKey && _jTypes[_jSP] == "object") 
                    {
                        _jIsKey = 1
                    } 
                    else {
                        _jIsKey = 0
                    }
                }
                else {
                    # String end
                    _jValue = substr(_jInput, _jStrStart, _jIdx - _jStrStart)
                    _jIsStr = 0

                    if (_jIsKey) 
                    {
                        _jSP++
                        _jKeys[_jSP] = _jValue
                        _jTypes[_jSP] = "key"
                        _jSkipWhitespace()
                        if (_jData[_jIdx+1] != ":") 
                            return "fail: expecting colon after key " _jValue " at index " (_jIdx+1)

                        _jIdx++
                        _jSkipWhitespace()
                    }
                    else {
                        _jSetValue(_jOutputData, _jOutputKeys)
                    }
                }
            }

            # Everything else
            else if (!_jIsStr) 
            {
                switch(_jC) 
                {
                    case "{":
                        _jIsKey = 0
                        if (_jTypes[_jSP] == "array")
                        {
                            _jKeys[_jSP] = _jIndices[_jSP] "]"
                        }
                        _jPushStack("object")
                        _jSkipWhitespace()
                        break

                    case "}":
                        while (_jTypes[_jSP] == "key") _jSP--
                        if (_jTypes[_jSP] != "object") 
                            return "fail: unexpected end object token at char " _jIdx

                        _jSkipWhitespace()
                        if (_jData[_jIdx+1] == ",") 
                            _jIdx++

                        _jIndices[_jSP]++
                        _jSkipWhitespace()
                        break

                   case "[":
                        _jIsKey = 0
                        if (_jTypes[_jSP] == "array")
                        {
                            _jKeys[_jSP] = _jIndices[_jSP] "]"
                        }
                        _jPushStack("array")
                        _jPushStack("array")
                        _jSkipWhitespace()
                        break

                    case "]":
                        if (_jTypes[_jSP] != "array") 
                            return "fail: unexpected end object token at char " _jIdx

                        _jSP -= 2
                        while (_jTypes[_jSP] == "key") 
                            _jSP--

                        _jSkipWhitespace()

                        if (_jData[_jIdx+1] == ",") 
                            _jIdx++

                        _jIndices[_jSP]++
                        _jSkipWhitespace()
                        break

                    case "t":
                        if ("true" == substr(_jInput, _jIdx, 4)) 
                        {
                            _jValue = "true"
                            _jIdx += 4
                            _jSetValue(_jOutputData, _jOutputKeys)
                        } 
                        else {
                            return "fail: expecting 'true' at char " _jIdx ", got " substr(_jInput, _jIdx, 4)
                        }
                        break

                    case "f":
                        if ("false" == substr(_jInput, _jIdx, 5)) 
                        {
                            _jValue = "false"
                            _jIdx += 5
                            _jSetValue(_jOutputData, _jOutputKeys)
                        } 
                        else {
                            return "fail: expecting 'false' at char " _jIdx ", got " substr(_jInput, _jIdx, 5)
                        }
                        break

                    case "n":
                        if ("null" == substr(_jInput, _jIdx, 4)) 
                        {
                            _jValue = "false"
                            _jIdx += 4
                            _jSetValue(_jOutputData, _jOutputKeys)
                        } 
                        else {
                            return "fail: expecting 'null' at char " _jIdx ", got " substr(_jInput, _jIdx, 4)
                        }
                        break

                    # Parse number
                    default:

                        if (_jC == "0" || _jC == "." || _jC + 0 > 0) 
                        {
                            _jStrStart = _jIdx
                            _jNp = 0
                            while (_jC == "0" || _jC == "." || _jC + 0 > 0) 
                            {
                                if (_jC == "." && ++_jNp > 1)
                                    return "fail: unable to parse number at index " _jIdx
                                
                                _jIdx++
                                _jC = _jData[_jIdx]
                            }
                            _jValue = substr(_jInput, _jStrStart, _jIdx-_jStrStart)
                            _jIdx--
                            _jSetValue(_jOutputData, _jOutputKeys)
                        } 
                        else {
                            return "fail: unexpected character " _jC " at index "  _jIdx
                        }
                    # End of switch
                }
            }
        } 
        
        # Start of input - either an object or an array
        else {
            if (_jHasRoot) 
                return "fail: unexpected character " _jC " at index " _jIdx

            _jHasRoot = 1

            if (_jC == "{") 
            {
                _jPushStack("object")
            }
            else if (_jC == "[") 
            {
                _jSP++
                _jPushStack("array")
                _jKeys[2] = "0]"
            }
            else 
            {
                return "fail: expecting '{' or '[' at index " _jIdx
            }

            _jSkipWhitespace()
        }

        # End of main loop
        _jIdx++
    }
    return 0
}


function _jSkipWhitespace() 
{
    while (match(_jData[_jIdx+1], /[ \t\r\n]/)) 
        _jIdx++
}


function _jPushStack(_jNewType) 
{
    _jSP++
    _jTypes[_jSP] = _jNewType
    _jKeys[_jSP] = _jNewType == "array" ? "[" : "."
    _jIndices[_jSP] = 0
}


function _jSetValue(_jOutputData, _jOutputKeys) 
{
    
    _jKey = _jTypes[2] == "array" ? "[" : ""
    if (_jTypes[_jSP] == "array") {
        _jKeys[_jSP] = _jIndices[_jSP] "]"
    }
    for (_jI = 2; _jI <= _jSP; _jI++) {
        _jKey = _jKey _jKeys[_jI]
    }

    _jOutputData[_jKey] = _jValue
    _jOutputKeys[++_jNKeys] = _jKey

    if (_jTypes[_jSP-1] == "object") _jSP--
    _jIndices[_jSP]++
    _jSkipWhitespace()
    if (_jData[_jIdx+1] == ",") _jIdx++
    _jSkipWhitespace()
    _jIsKey = 0
}

