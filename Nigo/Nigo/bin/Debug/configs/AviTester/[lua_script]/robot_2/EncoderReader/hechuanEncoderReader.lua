local json = require("json")

local stationId = 1

function set_config(cfg)
    local jsonObj = json.decode(cfg)
    stationId = jsonObj["station_id"]
end

---@return number
function get_encoder_pos() 
    comm_port:occupy()
    local sendStr = string.pack("BBBBBB", stationId, 0x03, 0x15, 0x07, 0x00, 0x02)
    local tCrcValue = MyAlgo.crc16(sendStr)
    local tCrcByte = string.pack("I2", tCrcValue)
    sendStr = sendStr..string.reverse(tCrcByte)
    gInfoLog("send to comm: " .. Str2HexValueStr(sendStr),"")
    comm_port:write_with_wait(sendStr)
    gSleep(200)
    local readStr = comm_port:read()
    gInfoLog("recv from comm: " .. Str2HexValueStr(readStr),"")
	if #readStr ~= 9 then 
		gErrorLog("encoderReader: " .. selfName .. " can't recv right data! ","")
        lastRunRetStr = "error"
        comm_port:release_ctrl()
		return 0xFFFFFFFF
    end
    
    local a, b, c, d = string.unpack("I1I1I1I1", readStr, 4)
    local posStr = string.pack("BBBB", c, d, a, b)
    local realpos = string.unpack(">i4", posStr, 1)
    comm_port:release_ctrl()
    return realpos
end

function Str2HexValueStr(strIn) 
    local ret = ""
    for i = 1, string.len(strIn) do
        ret = string.format("%sox%02X ", ret, string.byte(strIn, i)) 
    end
    return ret
end