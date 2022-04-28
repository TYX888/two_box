lastRunRetStr = ""

function readEncoder(jsonParamn)
   selfAxis:stop()
   selfAxis:wait_stop()
   
    local sendStr = string.pack("BBBBBBBB", 0x01, 0x03, 0x0b, 0x07, 0x00, 0x02, 0x77, 0xee)
 --	gInfoLog("sendStr: " .. string.byte( readStr, 1, #readStr))
	encoderReader:write_with_wait(sendStr)
	gSleep(400)
	local readStr = encoderReader:read()
	if #readStr ~= 9 then 
		gErrorLog("axis: " .. selfName .. " read encoder can't recv right data! ")
		lastRunRetStr = "error"
		return false
	end
	
	local a, b, c, d = string.unpack("I1I1I1I1", readStr, 4)
	local posStr = string.pack("BBBB", c, d, a, b)
--	print(string.byte(posStr, 1, -1))
	local realpos = string.unpack(">i4", posStr, 1)
	gInfoLog("axis: " .. selfName .. " read abs encoder value: " .. realpos)
	selfAxis:reset_cmd_pos(realpos * pulse2mm)
	selfAxis:reset_act_pos(realpos * pulse2mm)
	lastRunRetStr =  "ok"
	return true;
end