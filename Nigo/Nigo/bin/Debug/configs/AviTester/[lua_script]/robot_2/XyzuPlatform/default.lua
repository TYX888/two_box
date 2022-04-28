lastRunRetStr = ""

local man = motion_io_manager.get_instance()
function testFunc_backup(jsonParamn)
    gInfoLog("start test with param: " .. jsonParamn)
    local xAxis = selfXyzuPlatform:get_axis(0)
    local yAxis = selfXyzuPlatform:get_axis(1)
    --local xPos = xAxis:get_act_pos()
    --local yPos = yAxis:get_act_pos()
	local xPos = 50
	local yPos = 50
    if not selfXyzuPlatform:move_xy_with_wait(0, 0) then 
        gInfoLog("motion to zero pos failed!")
        return false
    end
    if not selfXyzuPlatform:move_xy_with_wait(xPos, yPos) then 
        gInfoLog("motion to pos " .. xPos .. " " .. yPos .. " " .. "failed!")
        return false
    end
end

function testFunc2(jsonParam) 
	gInfoLog("jsonParam:" .. jsonParam)
	selfXyzuPlatform:set_cur_work_head(0)
    local curWorkHead = selfXyzuPlatform:get_work_head(0)
    local curAxis = selfXyzuPlatform:get_axis(2)
    gInfoLog("positive limit is on? : " .. string.format("%s", curAxis:is_pos_limit_on()))
    gInfoLog("negative limit is on? : " .. string.format("%s", curAxis:is_neg_limit_on()))
    curAxis:start_axis_home_default_mode() 
    -- gSleep(100)
    curAxis:wait_axis_home_finished()
    -- selfXyzuPlatform:home_all_axis()
    -- for i = 1, 10 do 
    --     selfXyzuPlatform:move_single_z_with_wait(0, -15)
    --     gSleep(500)
    --     selfXyzuPlatform:move_single_z_with_wait(0, 0)
    -- end

    -- agingTest()
end

function testFunc2(jsonParam) 
    local tOutput = man:get_output("test")
    tOutput:turn_on()
end

function agingTest()
    for i=1,100 do 
        for headId = 0, 3 do 
            selfXyzuPlatform:move_single_z_with_wait(headId, -15)
            selfXyzuPlatform:move_single_z_with_wait(headId, 0)
            selfXyzuPlatform:move_single_u(headId, 180)
            selfXyzuPlatform:move_single_u(headId, 0)
        end
    end
end

function testFunc(jsonParam)
    selfXyzuPlatform:set_velocity_related_2_percent(30)
end