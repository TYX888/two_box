
local lastGetHeightValue = 999.98
local errorRet = "--------"
local currentMode = 0
local job0Cmd = "%EE#RMD3"
local job1Cmd = "%EE#RMD4"
local job0CheckCmd = "%EE#ROA3"
local job1CheckCmd = "%EE#ROA4"
local curCmd = job0Cmd
local curCheckCmd = job0CheckCmd

local _localErrorLog = function(msg) localErrorLog(msg, "") end
local _localDebugLog = function(msg) localDebugLog(msg, "") end
local _localWarnLog = function(msg) localWarnLog(msg, "") end

---@return boolean
function try_get_height() 
    if checkLastTest() == false then
        return false
    end
    local tRet = false
    local tSentStr = getFullCmd()
    --localDebugLog(string.format("%s sent bytes: %s", selfName, Str2HexValueStr(tSentStr)))
    comm_port:wirte(tSentStr)
    gSleep(10)
    local retStr = comm_port:read()
    if string.len(retStr) > 0 then 
        _localDebugLog(selfName .. ": recv from heightSensor: " .. retStr)
        if string.len(retStr) == 21 then
            local retValueSubStr =  string.sub(retStr, 8, -4)
            _localDebugLog("height str: " .. retValueSubStr)
            local retValue = tonumber(retValueSubStr)
            if retValue == nil then
                _localWarnLog("heightSensor recv error ret")
            else
                lastGetHeightValue = retValue
                tRet = true
            end
        else
            _localErrorLog(string.format("recv length != 21; length: %d", string.len(retStr)))
        end

    else
        _localDebugLog("can't recv from heightSensor: " .. selfLinkName)
    end

    return tRet
end

---@return number
function get_last_result()
    return lastGetHeightValue
end

function get_height()
    if try_get_height() then
        return get_last_result()
    else
        return 123456.7
    end
end


---@param modeIndex number
function set_current_mode(modeIndex)
    currentMode = modeIndex
    if currentMode == 0 then
        curCmd = job0Cmd
        curCheckCmd = job0CheckCmd
    else
        curCmd = job1Cmd
        curCheckCmd = job1CheckCmd
    end
end

---@return boolean
function checkLastTest()
    local tRet = false
    local tSentStr = getFullCheckCmd()
    --localDebugLog(string.format("%s sent bytes: %s", selfName, Str2HexValueStr(tSentStr)))
    comm_port:wirte(tSentStr)
    gSleep(10)
    local retStr = comm_port:read()
    if string.len(retStr) > 0 then
        _localDebugLog(selfName .. ": recv from heightSensor: " .. retStr)
        if string.len(retStr) == 15 then 
            local retValueSubStr = string.sub(retStr, 12, 12)
            local retValue = tonumber(retValueSubStr)
            if retValue ~= 0 then
                _gErrorLog(string.format("%s get height value failed", selfName))
            else
                tRet = true
            end
        else
            _localErrorLog("height recv error ret length")
        end
    else
        _localDebugLog("can't recv from heightSensor: " .. selfLinkName)
    end
    return tRet
end

function getFullCmd()
    local tCrcValue = MyAlgo.crc16(curCmd)
--    local tCrcByte = string.pack("I2", tCrcValue)
    local tCrcByte = "**"
    return string.format("%s%s\r\n", curCmd, string.reverse(tCrcByte))
end

function getFullCheckCmd()
    local tCrcValue = MyAlgo.crc16(curCheckCmd)
--    local tCrcByte = string.pack("I2", tCrcValue)
    local tCrcByte = "**"
    return string.format("%s%s\r\n", curCheckCmd, string.reverse(tCrcByte))
end

function Str2HexValueStr(strIn) 
    local ret = ""
    for i = 1, string.len(strIn) do
        ret = string.format("%sox%02X ", ret, string.byte(strIn, i)) 
    end
    return ret
end