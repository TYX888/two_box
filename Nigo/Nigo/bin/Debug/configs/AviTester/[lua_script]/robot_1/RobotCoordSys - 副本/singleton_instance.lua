
local sMachine = require("statemachine")
local json = require("json")
--@RefType [luaIde.motionIoManagerApi#motion_io_manager]
local gMotIoMan = motion_io_manager.get_instance()
local curPlatform = gMotIoMan:get_xyzu_platform("default")
local xyzu_axis = {
	x_axis = 0,
	y_axis = 1,
	z_axis = 2,
	u_axis = 3
}

local TransformType =  {
    enXYErrorMap = 0,
	enXYDisperseMap = 1,
	enFixedCamera = 2,
	enMovedCamera = 3,
	enLinearAxis = 4,
	enRotateAxis = 5,
	enTrayCoord = 6,
	enScara = 7,
	enToolInScaraArm2 = 8,
	enToolInU = 9
}

local DistXYTable = {
    nextPos = 1,
    allPos = {}
}
function DistXYTable:CreateAllPos(centerX, centerY, scale, stepLenX, stepLenY) 
    self.nextPos = 1
    self.allPos = {}
    for i = 0, scale-1 do
        for j = 0, scale-1 do 
            table.insert(self.allPos,  {x = centerX + (i-(scale-1)/2)*stepLenX,
                                        y = centerY + (j-(scale-1)/2)*stepLenY})
        end
       
    end
end

function DistXYTable:GetNextDist()
    if self.nextPos > #self.allPos then
        return false
    else
        local tPos = self.nextPos
        self.nextPos = tPos +1
        return true, self.allPos[tPos].x, self.allPos[tPos].y
    end
end

function testFunc(jsonParam) 
    if(jsonParam == "0") then
        CaliStep0Init(jsonParam)
    end
    -- localInfoLog(ExecutCmd("testCmdType","testJsonParam"))
end

function GetSingleVisionResult(vppName) 
    gSleep(600) --每次视觉检测前  延时足够
    local tRetJson = ExecutCmd("GetVisionResult", vppName)
    local jsonobj = json.decode(tRetJson)
    local tRet = jsonobj["_pipRetVec"]

    if not tRet[1]["_bPassed"] then 
        gErrorLog(string.format( "GetSingleVisionResult: %s, failed", vppName))
    end
    return tRet[1]["_bPassed"], tRet[1]["_dXpos"], tRet[1]["_dYpos"], tRet[1]["_dApos"]
end

--@return [luaIde.RobotCoordSysApi#TwoDimPos]
function GetSingleVisionResult2TDPRet(vppName) 
    local tPass, tX, tY, tA = GetSingleVisionResult(vppName)

    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local tRet = TwoDimPos.new()
    tRet._tfPos._fX = tX
    tRet._tfPos._fY = tY
    tRet._fAngle = tA
    return tPass, tRet
end
--[[
    @twoFloat_inspectPos [luaIde.RobotCoordSysApi#TwoFloat]
    @return  [luaIde.RobotCoordSysApi#TwoDimPos]
]]
function GetPosFromDwnCam(twoDimPos_pixelPos, twoFloat_inspectPos)
    local tTrans = curStation:GetTransByName("dwnCamMarkPos")
    tTrans:SetInputParam(twoFloat_inspectPos._fX, twoFloat_inspectPos._fY, 0.0)
    return curStation:RunSolver(twoDimPos_pixelPos, "GetPosFromDwnCam")
end

curStation = selfCoordSys:GetStationCoordSys("Machine1")

function CaliStep0Init(jsonParam)
    localInfoLog("start CaliStep0Init")
    selfCoordSys:ClearAllStationAndInfo()
    selfCoordSys:CreateStation("Machine1")
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    curStation:CreateTrans("RbtMtn2dwnCam",TransformType.enMovedCamera)
    curStation:CreateTrans("dwnCamMarkPos", TransformType.enLinearAxis)
    curStation:CreateSolverInfo("GetPosFromDwnCam")
    curStation:InsertTransInfoInSolverInfo("RbtMtn2dwnCam", "GetPosFromDwnCam", false)
    curStation:InsertTransInfoInSolverInfo("dwnCamMarkPos", "GetPosFromDwnCam", false)

    -- curStation:CreateTrans("nozzle0RotCentOffset2DwnCam", TransformType.enLinearAxis)
    -- curStation:CreateTrans("nozzle1RotCentOffset2DwnCam", TransformType.enLinearAxis)
    -- curStation:CreateTrans("nozzle2RotCentOffset2DwnCam", TransformType.enLinearAxis)
    -- curStation:CreateTrans("nozzle3RotCentOffset2DwnCam", TransformType.enLinearAxis)

    curStation:CreateTrans("nozzle0RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle1RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle2RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle3RotatePixelCenter",TransformType.enRotateAxis)
    
    -- curStation:CreateTrans("nozzle0UpCamToDwnCam", TransformType.enXYDisperseMap)
    -- curStation:CreateTrans("nozzle1UpCamToDwnCam", TransformType.enXYDisperseMap)
    -- curStation:CreateTrans("nozzle2UpCamToDwnCam", TransformType.enXYDisperseMap)
    -- curStation:CreateTrans("nozzle3UpCamToDwnCam", TransformType.enXYDisperseMap)

    --通过帖放的方式  可以知道下相机到机器人坐标的映射  
    curStation:CreateTrans("Nozzle0RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle1RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle2RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle3RbtMtn2UpCam", TransformType.enFixedCamera)

    curStation:CreateTrans("nozzle0UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle1UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle2UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle3UpCamTakePicPos", TransformType.enLinearAxis)

    curStation:CreateTrans("nozzle0UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle1UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle2UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle3UpCamUNormalPixelPos", TransformType.enLinearAxis)

    curStation:CreateTrans("tempTray",TransformType.enTrayCoord)
    selfCoordSys:Save()
    lastRunRetStr = "ok"
end

local fsm = {}
local nextEvent = ""
local eventMsg = {}

function RunFsmToEnd() 
    while nextEvent ~= "" do
        if(localNeedStop()) then 
            gWarnLog("recv stop cmd! will stop the statemachine!")
            nextEvent = "quit"
        end
        if(fsm[nextEvent] == nil) then 
            gErrorLog("RunFsmToEndError!: no such event: " .. nextEvent)
            nextEvent = ""
        else
            if fsm:can(nextEvent) then
                fsm[nextEvent](fsm)
            else
                gErrorLog("RunFsmToEndError!: can't do event in current state! event: "
                     .. nextEvent .. " curState: " .. fsm.current)
                nextEvent = ""
            end
        end
    end

    gInfoLog(string.format("stateMachine stoped at state: %s", fsm.current))
end


function CaliStep1ForDwnCam(jsonParam)
    fsm = sMachine.create({
        initial = "startStep1",
        events = {
            {name = "runStep1", from = "startStep1", to = "step1Init"},
    
            {name = "quit", from = {"step1Init", "testDwnCamInspectMark", "updataDistTable",
                "move2Next", "dwnCamInspectMark"}, to = "abort"},
    
            {name = "fail", from = {"step1Init", "testDwnCamInspectMark", "updataDistTable",
                "move2Next", "dwnCamInspectMark"}, to = "errorRet"},
            
    
            {name = "success", from = "step1Init", to = "testDwnCamInspectMark"},
    
            {name = "success", from = "testDwnCamInspectMark", to = "updataDistTable"},
    
            {name = "success", from = "updataDistTable", to = "move2Next"},
    
            {name = "success", from = "move2Next", to = "dwnCamInspectMark"},
    
            {name = "success", from = "dwnCamInspectMark", to = "move2Next"},

            {name = "tempFinished", from = "move2Next", to = "updataDistTable"},
            {name = "finished", from = "move2Next", to = "successRet"} 
        },
        callbacks = {
            --state的callback
            onstep1Init = onStep1Init,
            ontestDwnCamInspectMark = onTestDwnCamInspectMark,
            onabort= onAbort,
            onsuccessRet = onSuccessRet,
            onerrorRet = onErrorRet,
            onupdataDistTable = onUpdataDistTable,
            onmove2Next = onMove2Next,
            ondwnCamInspectMark = onDwnCamInspectMark,

            --event的callback
            onsuccess = onSuccess,
            onfail = onFail
        }
    })

    nextEvent = "runStep1"
    RunFsmToEnd()
    gInfoLog(string.format("calibration step1 run to state: %s", fsm.current))
end

local CaliStep1Param = {
    dwnCamCenter = {x = 640.0, y = 480,0},
    stepLen = 3.0,
    scale = 5,
    
    -- 临时参数用于流程之间的交互
    tempParam = {
        tempMappingFinished = false,  --此参数因为mapping 要走两遍 因为需要第2遍的时候机器人大致能将mark大致对准相机中心
    }
}
--@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
local _tdpDwnCamCenter = TwoDimPos.new()
_tdpDwnCamCenter._tfPos._fX = CaliStep1Param.dwnCamCenter.x
_tdpDwnCamCenter._tfPos._fY = CaliStep1Param.dwnCamCenter.y


function onStep1Init(self, event, from, to)
    gInfoLog("in onstep1Init")
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    dwnCamTrans = curStation:GetTransByName("RbtMtn2dwnCam")
    dwnCamTrans:ClearData()
    CaliStep1Param.tempParam.tempMappingFinished = false
    nextEvent = "success"
end

function onTestDwnCamInspectMark(self, event, from, to)
    gInfoLog("in testDwnCam")
    local passed, _, _ = GetSingleVisionResult("dwnCamInspectMark")
    if not passed then
        nextEvent = "fail"
    else
        nextEvent = "success"
    end
end

function onAbort(self, event, from, to)
    gInfoLog("in onsuccessRet")
    lastRunRetStr = "abort"
    nextEvent = ""
end

function onSuccessRet(self, event, from, to)
    gInfoLog("in onsuccessRet")
    selfCoordSys:Save()
    selfCoordSys:Init("")
    lastRunRetStr = "ok"
    nextEvent = ""
end

function onErrorRet(self, event, from, to)
    gInfoLog("in onerrorRet")
    lastRunRetStr = "fail"
    nextEvent = ""
end

function onSuccess(self, event, from, to, msg)
    gInfoLog("Fire event: success: from: " .. from .. " to: " .. to)
end

function onFail(self, event, from, to, msg)
    gInfoLog("Fire event: fail: from: " .. from .. " to: " .. to)
end

function onUpdataDistTable(self, event, from, to)
    if CaliStep1Param.tempParam.tempMappingFinished then
        local downMarkPos = dwnCamTrans:FromTargetToSource(_tdpDwnCamCenter) 
        dwnCamTrans:ClearData()
        DistXYTable:CreateAllPos(downMarkPos._tfPos._fX, downMarkPos._tfPos._fY,
                CaliStep1Param.scale, CaliStep1Param.stepLen * 1.2, CaliStep1Param.stepLen)
    else
        local tPos = curPlatform:get_pos()
        DistXYTable:CreateAllPos(tPos.x_pos, tPos.y_pos, 3, 
                                    CaliStep1Param.stepLen * 1.2, CaliStep1Param.stepLen)
    end
    nextEvent = "success"
end

function onMove2Next(self, event, from, to)
    local notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
    if notFinished then 
        if curPlatform:move_xy_with_wait(nextPosX, nextPosY) then
            nextEvent = "success"
        else
            nextEvent = "fail"
        end
    else
        if CaliStep1Param.tempParam.tempMappingFinished then
            local downMarkPos = dwnCamTrans:FromTargetToSource(_tdpDwnCamCenter) 
            local tTrans = curStation:GetTransByName("dwnCamMarkPos")
            tTrans:SetInnerParam(downMarkPos._tfPos._fX, downMarkPos._tfPos._fY, 0.0)
            nextEvent = "finished"
        else
            CaliStep1Param.tempParam.tempMappingFinished = true
            selfCoordSys:Save()
            nextEvent = "tempFinished"
        end
    end
end

function onDwnCamInspectMark(self, event, from, to)
    local passed, pixelX, pixelY = GetSingleVisionResult("dwnCamInspectMark")
    if not passed then
        nextEvent = "fail"
        return 
    end
    local inpsectPos = curPlatform:get_pos()
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local source = TwoDimPos.new()
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local target = TwoDimPos.new()
    source._tfPos._fX = inpsectPos.x_pos
    source._tfPos._fY = inpsectPos.y_pos
    target._tfPos._fX = pixelX
    target._tfPos._fY = pixelY
    dwnCamTrans:SetOnePairData(source,target)
    nextEvent = "success"
end




local CaliStep2Info = {
    _upCamTakePicPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _dwnCamTakePicPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _pickupPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _nozzleId = 0
}

function CaliStep2ForUpCam(jsonParam)
    CaliStep2Info = json.decode(jsonParam)
    fsm = sMachine.create({
        initial = "startStep2",
        events = {
            {name = "runStep2", from = "startStep2", to = "step2Init"},

            {name = "quit", from = {"startStep2","step2Init","testAll","findNozzleRotCenterByDwnCam",
            "updataPickPlaceTable","findNozzleRotCenterByUpCam","moveNozzleNextPos","pickupAndInspectByUpCam",
            "placeDownToSamePlace", "recheckPartPos"}, to = "abort"},

            {name = "fail", from = {"startStep2","step2Init","testAll","findNozzleRotCenterByDwnCam",
            "updataPickPlaceTable","findNozzleRotCenterByUpCam","moveNozzleNextPos","pickupAndInspectByUpCam",
            "placeDownToSamePlace", "recheckPartPos"}, to = "errorRet"},

            {name = "success", from = "step2Init", to = "testAll"},
            
            {name = "success", from = "testAll", to = "findNozzleRotCenterByUpCam"}, 

            --[[-吸嘴旋转中心和上相机的偏差并不重要 如果知道在下相机拍照位置吸嘴捅下去后物料的位置  
                那么就能知道需要移动多少offset 就能贴到目标位置]]
            -- {name = "success", from = "findNozzleRotCenterByDwnCam", to = "updataPickPlaceTable"}, 

            {name = "success", from = "findNozzleRotCenterByUpCam", to = "updataPickPlaceTable"},

            {name = "success", from = "updataPickPlaceTable", to = "moveNozzleNextPos"},

            {name = "success", from = "moveNozzleNextPos", to = "pickupAndInspectByUpCam"},
            {name = "tempFinished", from = "moveNozzleNextPos", to = "updataPickPlaceTable"},
            {name = "finished", from = "moveNozzleNextPos", to = "successRet"},

            {name = "success", from = "pickupAndInspectByUpCam", to = "placeDownToSamePlace"},

            {name = "success", from = "placeDownToSamePlace", to = "recheckPartPos"},

            {name = "success", from = "recheckPartPos", to = "moveNozzleNextPos"},
        },
        callbacks = {
            --state的callback
            onstep2Init = onStep2Init,
            onabort= onAbort,
            onsuccessRet = onSuccessRet,
            onerrorRet = onErrorRet,

            ontestAll = onTestAll,
            onfindNozzleRotCenterByUpCam = onFindNozzleRotCenterByUpCam,
            onupdataPickPlaceTable = onUpdataPickPlaceTable,
            onmoveNozzleNextPos = onMoveNozzleNextPos,
            onpickupAndInspectByUpCam = onPickupAndInspectByUpCam,
            onplaceDownToSamePlace = onPlaceDownToSamePlace,
            onrecheckPartPos = onRecheckPartPos,

            --event的callback
            onsuccess = onSuccess,
            onfail = onFail
        }
    })

    nextEvent = "runStep2"
    RunFsmToEnd()
    gInfoLog(string.format("calibration step1 run to state: %s", fsm.current))
end


local CaliStep2Param = {
    upCamCenter = {x = 640.0, y = 480,0},
    stepLen = 1.6,
    scale = 5, --标定玻片内径是9mm 应该不会走出去

    -- 临时参数用于流程之间的交互
    tempParam = {
        curNozzleIndex = 0,
        lastTimeNozzlePickupPartPos = {x = 0, y = 0},
        offsetNeedPlusToPickup = {x = 0, y = 0, a = 0},--因为pick place一次 玻璃片要动  所以这个补偿要用上
        --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
        partPosBeforePickup = TwoDimPos.new(),
        tempMappingFinished = false,
        --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
        lastTimeUpCamInspectPartResult = TwoDimPos.new(),
        --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
        curNozzleCenterOffset2DwnCam = {},
        --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
        nozzlePixelPosInUpCam = TwoDimPos.new() --缓存住 当前吸嘴在下相机的位置
    }
}
--@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
local _tdpCamUpCenter = TwoDimPos.new()
_tdpCamUpCenter._tfPos._fX = CaliStep2Param.upCamCenter.x
_tdpCamUpCenter._tfPos._fY = CaliStep2Param.upCamCenter.y

function onStep2Init(self, event, from, to)
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    CaliStep2Param.tempParam.curNozzleIndex = CaliStep2Info._nozzleId
    curWorkHead = curPlatform:get_work_head(CaliStep2Param.tempParam.curNozzleIndex)
    curPlatform:set_cur_work_head(CaliStep2Info._nozzleId)
    curPlatform:close_all_output()
    CaliStep2Param.tempParam.tempMappingFinished = false
    nextEvent = "success"
end

function NozzlePickup(nozzleId, zPos)
    curPlatform:set_cur_work_head(nozzleId)
    local tWorkhead = curPlatform:get_work_head(nozzleId)

    local tRet = curPlatform:move_single_with_wait(xyzu_axis.z_axis, zPos)
    gSleep(100)
    tWorkhead:vacuum_open_with_delay(300)
    tRet = tRet and curWorkHead:get_z_u():z_2_normal_with_wait()
    return tRet
end

function NozzlePutdown(nozzleId, zPos)
    curPlatform:set_cur_work_head(nozzleId)
    local tWorkhead = curPlatform:get_work_head(nozzleId)

    local tRet = curPlatform:move_single_with_wait(xyzu_axis.z_axis, zPos)
    tWorkhead:vacuum_close()
    gSleep(100)
    tWorkhead:vacuum_break()
    gSleep(300)
    tWorkhead:vacuum_break_close()
    gSleep(300)
    tRet = tRet and curWorkHead:get_z_u():z_2_normal_with_wait()
    return tRet
end

function PlatformToNomal()
    local tRet = curPlatform:all_work_head_2_normal_with_wait()
    return tRet
end

function onTestAll(self, event, from, to)
    --测试下 上相机能否被看到
    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
                                                CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    local partPos = {x = tVisionRetPos._tfPos._fX, y = tVisionRetPos._tfPos._fY, a = tVisionRetPos._fAngle}
    --取起来 移到下相机下测一下  看能否通过检测
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
                    CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to pickupPos!")  
        return 
    end

    NozzlePickup(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)
    
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
                    CaliStep2Info._upCamTakePicPos._yPos, CaliStep2Info._upCamTakePicPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to upCamTakePicPos!")  
        return 
    end
    tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectPart")
    if not tVsnRetPass then
        nextEvent = "fail"
        return
    end

    --扔回原来的地方  复原现场
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
                    CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to pickupPos!")  
        return 
    end
    NozzlePutdown(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)

    --复检下物料的位置是否移动  
    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
    CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    local xOffset = tVisionRetPos._tfPos._fX - partPos.x
    local yOffset = tVisionRetPos._tfPos._fY - partPos.y
    local aOffset = tVisionRetPos._fAngle - partPos.a
    gInfoLog(string.format( "part moved in upCam: x: %.2f, y: %.3f, a: %.3f", xOffset, yOffset, aOffset))
    if(math.abs(xOffset) > 1 or math.abs(yOffset) > 1 or math.abs(aOffset) > 0.3) then 
        gErrorLog("parts moved too much during the pick and place ")
        nextEvent = "fail"
        return
    end
    local inspectPos = TwoFloat.new()
    inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    local tPartPos = GetPosFromDwnCam(tVisionRetPos, inspectPos)
    CaliStep2Param.tempParam.partPosBeforePickup = tPartPos
    -- 最后测试下吸嘴能否被检测 并将结果存起来  
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
        CaliStep2Info._upCamTakePicPos._yPos, CaliStep2Info._upCamTakePicPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to upCamTakePicPos!")  
        return 
    end
    tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectNozzle")
    if not tVsnRetPass then
        nextEvent = "fail"
        return
    end
    --相关结果 存好
    CaliStep2Param.tempParam.nozzlePixelPosInUpCam = tVisionRetPos
    local tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamUNormalPixelPos", CaliStep2Info._nozzleId))
    tTrans:SetInnerParam(tVisionRetPos._tfPos._fX, 
                        tVisionRetPos._tfPos._fY, tVisionRetPos._fAngle)
    tTrans:Save()
    tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamTakePicPos", CaliStep2Info._nozzleId))
    tTrans:SetInnerParam(CaliStep2Info._upCamTakePicPos._xPos, CaliStep2Info._upCamTakePicPos._yPos, CaliStep2Info._upCamTakePicPos._uPos)
    tTrans:Save()
    -- --@RefType [luaIde.RobotCoordSysApi#TwoFloat]
    -- local inspectPos = TwoFloat.new()
    -- inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    -- inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    -- CaliStep2Param.tempParam.markPos = GetPosFromDwnCam(tVisionRetPos, inspectPos)
    nextEvent = "success"
end

function onFindNozzleRotCenterByDwnCam(self, event, from, to)
    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
    CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
        if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    --@RefType [luaIde.RobotCoordSysApi#TwoFloat]
    local inspectPos = TwoFloat.new()
    inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    local tPos = GetPosFromDwnCam(tVisionRetPos, inspectPos)

    --取起来  再旋转180扔下去
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
    CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to pickupPos!")  
        return 
    end
    NozzlePickup(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)
    tRet = curPlatform:move_single(xyzu_axis.u_axis, CaliStep2Info._pickupPos._uPos + 180)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to rotate!")  
        return 
    end
    NozzlePutdown(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)

    --再检测一次结果
    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
    CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
        if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    --@RefType [luaIde.RobotCoordSysApi#TwoFloat]
    local inspectPos = TwoFloat.new()
    inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    local tPos2 = GetPosFromDwnCam(tVisionRetPos, inspectPos)

    --计算 并塞入结果
    local xOffset = CaliStep2Info._dwnCamTakePicPos._xPos - (tPos._tfPos._fX + tPos2._tfPos._fX) / 2
    local yOffset = CaliStep2Info._dwnCamTakePicPos._yPos - (tPos._tfPos._fY + tPos2._tfPos._fY) / 2
    gInfoLog(string.format( "nozzle %d rotate center offset to dwnCamCent: x: %.3f, y: %.3f",
            CaliStep2Info._nozzleId, xOffset, yOffset))
    local tTrans = curStation:GetTransByName(string.format("nozzle%dRotCentOffset2DwnCam", CaliStep2Info._nozzleId))
    tTrans:SetInnerParam(xOffset, yOffset, 0.0)
    CaliStep2Param.tempParam.curNozzleCenterOffset2DwnCam = tTrans:GetInnerParamWithTDP()

    --扔回 原来的位置  并检测具体位置
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
    CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos + 180)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to pickupPos!")  
        return 
    end
    NozzlePickup(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)
    tRet = curPlatform:move_single(xyzu_axis.u_axis, CaliStep2Info._pickupPos._uPos)
    NozzlePutdown(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)

    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
    CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
        if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    --@RefType [luaIde.RobotCoordSysApi#TwoFloat]
    inspectPos = TwoFloat.new()
    inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    CaliStep2Param.tempParam.partPosBeforePickup = GetPosFromDwnCam(tVisionRetPos, inspectPos) --存下位置 为mapping做准备
    
    nextEvent = "success"
end

function onFindNozzleRotCenterByUpCam(self, event, from, to)
    local tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
                CaliStep2Info._upCamTakePicPos._yPos, 0)   
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local tVisionRetPos, tVisionRetPos2 = {}   
    local tVsnRetPass = false
    tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectNozzle") 
    if(tRet and tVsnRetPass) then 
        tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
                                CaliStep2Info._upCamTakePicPos._yPos, 180) 
        tVsnRetPass, tVisionRetPos2 = GetSingleVisionResult2TDPRet("upCamInspectNozzle") 
        if(tRet and tVsnRetPass) then 
            local tTransName = string.format("nozzle%dRotatePixelCenter", CaliStep2Param.tempParam.curNozzleIndex)
            local tTrans = curStation:GetTransByName(tTransName)
            tTrans:SetInnerParam((tVisionRetPos2._tfPos._fX + tVisionRetPos._tfPos._fX) / 2,
            (tVisionRetPos2._tfPos._fY + tVisionRetPos._tfPos._fY) / 2, 0)
            nextEvent = "success"
            return 
        end
    end
    nextEvent = "fail"
    return
end

function onUpdataPickPlaceTable(self, event, from, to)
    local tTrans = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", CaliStep2Info._nozzleId))
    if CaliStep2Param.tempParam.tempMappingFinished then
        local tTrans = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", CaliStep2Info._nozzleId))
        tTrans:Save()

        -- local pos2Pickup = MoveNozzleToPos(CaliStep2Info._nozzleId, CaliStep2Param.tempParam.partPosBeforePickup,
        --                                     CaliStep2Param.tempParam.nozzlePixelPosInUpCam)

        --需要确保U不能转动 所以填入的物料的角度要讲究 保证就是
        local pos2Pickup = MoveNozzleToPosWithSetU(CaliStep2Info._nozzleId, CaliStep2Param.tempParam.partPosBeforePickup,
        CaliStep2Param.tempParam.nozzlePixelPosInUpCam, CaliStep2Info._pickupPos._uPos)
        CaliStep2Info._pickupPos._xPos = pos2Pickup._tfPos._fX
        CaliStep2Info._pickupPos._yPos = pos2Pickup._tfPos._fY
        CaliStep2Info._pickupPos._uPos = pos2Pickup._fAngle  
        --取料的U角度变了 但应该不影响 因为贴片导致的offset 仍然起效 只需将拍照位置和取料的U保持一致即可
        CaliStep2Info._upCamTakePicPos._uPos = pos2Pickup._fAngle  
   
        tTrans:ClearData()
        --此时_pickupPos已经被初步试教数据来精准对准  
        DistXYTable:CreateAllPos(CaliStep2Info._pickupPos._xPos, CaliStep2Info._pickupPos._yPos,
                CaliStep2Param.scale, CaliStep2Param.stepLen, CaliStep2Param.stepLen)
    else
        --开始临时校准  使用3*3的规模
        tTrans:ClearData()
        DistXYTable:CreateAllPos(CaliStep2Info._pickupPos._xPos, CaliStep2Info._pickupPos._yPos,
                                3, CaliStep2Param.stepLen, CaliStep2Param.stepLen)                       
    end
    
    nextEvent = "success"
end

function onMoveNozzleNextPos(self, event, from, to) 
    local notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
    if notFinished then
        nextPosX = nextPosX + CaliStep2Param.tempParam.offsetNeedPlusToPickup.x
        nextPosY = nextPosY + CaliStep2Param.tempParam.offsetNeedPlusToPickup.y
        local nextPosA = CaliStep2Info._pickupPos._uPos --角度的补偿就不做了
        CaliStep2Param.tempParam.offsetNeedPlusToPickup = {x = 0, y = 0, a = 0}
        local tRet = curPlatform:move_xyu_with_wait(nextPosX, nextPosY, nextPosA)
        CaliStep2Param.tempParam.lastTimeNozzlePickupPartPos.x = nextPosX
        CaliStep2Param.tempParam.lastTimeNozzlePickupPartPos.y = nextPosY
        if not tRet then
            nextEvent = "fail" 
            return
        end
        -- NozzlePickup(CaliStep2Info._nozzleId, CaliStep2Info._pickupPos._zPos)
        nextEvent = "success"
    else
        if CaliStep2Param.tempParam.tempMappingFinished then 
            nextEvent = "finished"
        else 
            CaliStep2Param.tempParam.tempMappingFinished = true
            nextEvent = "tempFinished"
        end
    end
end

function onPickupAndInspectByUpCam(self, event, from, to) 
    --拾取并移动到下相机检测位置
    NozzlePickup(CaliStep2Info._nozzleId, CaliStep2Info._pickupPos._zPos)
    local tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
    CaliStep2Info._upCamTakePicPos._yPos, CaliStep2Info._upCamTakePicPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to upCamTakePicPos!")  
        return 
    end

    --检测 并把结果存起来
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectPart")
    if not tVsnRetPass then
        nextEvent = "fail"
        return
    else
        CaliStep2Param.tempParam.lastTimeUpCamInspectPartResult = tVisionRetPos
    end
    nextEvent = "success"
end

function onPlaceDownToSamePlace(self, event, from, to)
    local tRet = curPlatform:move_xyu_with_wait(CaliStep2Param.tempParam.lastTimeNozzlePickupPartPos.x,
    CaliStep2Param.tempParam.lastTimeNozzlePickupPartPos.y, CaliStep2Info._upCamTakePicPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        gErrorLog("failed to move to upCamTakePicPos!")  
        return 
    end
    NozzlePutdown(CaliStep2Info._nozzleId, CaliStep2Info._pickupPos._zPos)
    nextEvent = "success"
end

function onRecheckPartPos(self, event, from, to)
    local tRet = curPlatform:move_xy_with_wait(CaliStep2Info._dwnCamTakePicPos._xPos, 
                                                CaliStep2Info._dwnCamTakePicPos._yPos)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = "fail"
        return
    end
    --@RefType [luaIde.RobotCoordSysApi#TwoFloat]
    local inspectPos = TwoFloat.new()
    inspectPos._fX = CaliStep2Info._dwnCamTakePicPos._xPos
    inspectPos._fY = CaliStep2Info._dwnCamTakePicPos._yPos
    local tPartPos = GetPosFromDwnCam(tVisionRetPos, inspectPos)
    local xOffset = tPartPos._tfPos._fX - CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fX
    local yOffset = tPartPos._tfPos._fY - CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fY
    local aOffset = tPartPos._fAngle - CaliStep2Param.tempParam.partPosBeforePickup._fAngle
    CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fX = tPartPos._tfPos._fX
    CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fY = tPartPos._tfPos._fY
    CaliStep2Param.tempParam.partPosBeforePickup._fAngle = tPartPos._fAngle
    gWarnLog(string.format("parts offset after pick and place : x:%.3f, y:%.3f, a:%.3f", xOffset, yOffset, aOffset))
    -- if(math.abs(xOffset) > 0.03 or math.abs(yOffset) > 0.03 or math.abs(aOffset) > 0.1) then
    if(math.abs(xOffset) > 0.1 or math.abs(yOffset) > 0.1 or math.abs(aOffset) > 0.1) then -- 只能放宽 目前丢下去有动
        gErrorLog("parts moved too far. error!")
        nextEvent = "fail"
        return 
    end
    CaliStep2Param.tempParam.offsetNeedPlusToPickup.x = xOffset
    CaliStep2Param.tempParam.offsetNeedPlusToPickup.y = yOffset
    CaliStep2Param.tempParam.offsetNeedPlusToPickup.a = aOffset
    --将数据填入 下相机的映射表内
    local tParam = CaliStep2Param.tempParam
    local tTrans = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", CaliStep2Info._nozzleId))
    --[[
        计算思路: 
        实际取料位置 - 下相机拍照位置 = 实际移动偏移位置
        物料的实际位置 - 实际偏移位置 = 如果不放料 直接在下相机拍照的地方 放下吸嘴 会把物料丢到哪
        把上面的数据 和 像素坐标丢到下相机表里  下次往某个位置贴装 就只需要在 在拍照位置 叠加 (贴装位置 - 查表的结果即可)
    ]]
    local xPosInRbt = tParam.partPosBeforePickup._tfPos._fX - (tParam.lastTimeNozzlePickupPartPos.x - CaliStep2Info._upCamTakePicPos._xPos)
    local yPosInRbt = tParam.partPosBeforePickup._tfPos._fY - (tParam.lastTimeNozzlePickupPartPos.y - CaliStep2Info._upCamTakePicPos._yPos)
    local source = TwoDimPos.new()
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local target = tParam.lastTimeUpCamInspectPartResult
    source._tfPos._fX = xPosInRbt
    source._tfPos._fY = yPosInRbt
    tTrans:SetOnePairData(source,target)
    nextEvent = "success"
end

--[[
    @distPos: [luaIde.RobotCoordSysApi#TwoDimPos]
    @pixelPosInUpCam: [luaIde.RobotCoordSysApi#TwoDimPos]
    @return [luaIde.RobotCoordSysApi#TwoDimPos]
]]
function MoveNozzleToPos(nozzleId, distPos, pixelPosInUpCam) 
    --先计算需要旋转的角度
    local tRotTrans = curStation:GetTransByName(string.format("nozzle%dRotatePixelCenter", nozzleId))
    local tRbt2Pixel = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", nozzleId))
    local tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamTakePicPos", nozzleId))
    local tTakePicPos = tTrans:GetInnerParamWithTDP()
    local tAglInRbt = tRbt2Pixel:AglFromTargetToSource(pixelPosInUpCam._fAngle)
    tRotTrans:SetInputParam(distPos._fAngle - tAglInRbt, 0, 0)
    local tPixelPos = tRotTrans:FromSourceToTarget(pixelPosInUpCam)
    local tRbtPos = tRbt2Pixel:FromTargetToSource(tPixelPos)
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local ret = TwoDimPos.new()
    ret._fAngle = tTakePicPos._fAngle + (distPos._fAngle - tAglInRbt)
    ret._tfPos._fX = tTakePicPos._tfPos._fX + (distPos._tfPos._fX - tRbtPos._tfPos._fX)
    ret._tfPos._fY = tTakePicPos._tfPos._fY + (distPos._tfPos._fY - tRbtPos._tfPos._fY)
    return ret
end

function MoveNozzleToPosWithSetU(nozzleId, distPos, pixelPosInUpCam, u)
    local tRotTrans = curStation:GetTransByName(string.format("nozzle%dRotatePixelCenter", nozzleId))
    local tRbt2Pixel = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", nozzleId))
    local tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamTakePicPos", nozzleId))
    local tTakePicPos = tTrans:GetInnerParamWithTDP()
    tRotTrans:SetInputParam(u - tTakePicPos._fAngle, 0, 0)
    local tPixelPos = tRotTrans:FromSourceToTarget(pixelPosInUpCam)
    local tRbtPos = tRbt2Pixel:FromTargetToSource(tPixelPos)
    --@RefType [luaIde.RobotCoordSysApi#TwoDimPos]
    local ret = TwoDimPos.new()
    ret._fAngle = u
    ret._tfPos._fX = tTakePicPos._tfPos._fX + (distPos._tfPos._fX - tRbtPos._tfPos._fX)
    ret._tfPos._fY = tTakePicPos._tfPos._fY + (distPos._tfPos._fY - tRbtPos._tfPos._fY)
    return ret

end