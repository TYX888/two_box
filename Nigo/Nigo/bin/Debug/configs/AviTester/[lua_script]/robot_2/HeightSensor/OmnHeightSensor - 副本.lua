
local lastGetHeightValue = 999.98
local errorRet = "--------"
local currentMode = 0
---@return boolean
function try_get_height() 
    local tRet = false
	comm_port:wirte(string.format("MS %d\r\n", currentMode))
    --comm_port:wirte("MS 0\r\n")
    gSleep(10)
    local retStr = comm_port:read()
    if string.len(retStr) > 0 then 
        localDebugLog("recv from heightSensor: " .. retStr)
		local retValue = tonumber(retStr)
        if retValue == nil then
            localWarnLog("heightSensor recv error ret")
        else
            lastGetHeightValue = retValue / 1000000
			tRet = true
        end
    else
        localDebugLog("can't recv from heightSensor: " .. selfLinkName)
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
end
