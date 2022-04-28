---@type XyzuPlatform
local curXyzu = xyzu_platform

lastRunRetStr = ""

local squareFindParam = {
    stopDelay = 50,
    stepLength = 0.02,
    minCount = 3,
    heightDiffTol = 0.012
}

function try_get_avg_height(jsonParam)
    local startPos = curXyzu:get_pos()
    local allTempRet = {}
    if selfHeightSensor:try_get_height() then
        allTempRet[5] = selfHeightSensor:get_last_result()
    end

    for x = 0, 2 do
        for y = 0, 2 do
            local index = x * 3 + y + 1
            if index ~= 5 then
                curXyzu:move_xy_with_wait(
                    startPos.x_pos + (x - 1) * squareFindParam.stepLength,
                    startPos.y_pos + (y - 1) * squareFindParam.stepLength
                )
                gSleep(squareFindParam.stopDelay)
                if selfHeightSensor:try_get_height() then
                    allTempRet[index] = selfHeightSensor:get_last_result()
                end
            end
        end
    end

    validate_result(allTempRet)
end

function validate_result(allTempRet)
    local tCount = 0
    local tTotal = 0
    local tMin, tMax = 100, -100
    for i = 1, 9 do
        if allTempRet[i] ~= nil then
            tCount = tCount + 1
            tTotal = tTotal + allTempRet[i]
            if allTempRet[i] < tMin then
                tMin = allTempRet[i]
            end
            if allTempRet[i] > tMax then
                tMax = allTempRet[i]
            end
        end
    end

    if tCount < squareFindParam.minCount then
        localErrorLog(string.format("get value count < %d", squareFindParam.minCount))
        lastRunRetStr = "error"
        return
    end

    if tMax - tMin > squareFindParam.heightDiffTol then
        localErrorLog(string.format("maxValue - minValue > %.3f", squareFindParam.heightDiffTol))
        lastRunRetStr = "error"
        return
    end

    lastRunRetStr = tostring(tTotal / tCount)
    return
end
