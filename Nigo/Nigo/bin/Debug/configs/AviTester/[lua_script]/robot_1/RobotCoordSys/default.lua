local sMachine = require("statemachine")
local json = require("json")

local ExecutCmd = function(cmdType, cmdArg) 
    return vision:execute_special_cmd(cmdType, cmdArg)
end

local _gErrorLog = function(msg) gErrorLog(msg, "") end
local _localInfoLog = function(msg) localInfoLog(msg, "") end
local _gWarnLog = function(msg) gWarnLog(msg, "") end
local _gInfoLog = function(msg) gInfoLog(msg, "") end

local gMotIoMan = man

local selfCoordSys = selfRobotCoordSys
local curPlatform = gMotIoMan:get_xyzu_platform("default")

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
local xyzu_axis = {
	x_axis = 0,
	y_axis = 1,
	z_axis = 2,
	u_axis = 3
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
    -- _localInfoLog(ExecutCmd("testCmdType","testJsonParam"))
end

function GetSingleVisionResult(vppName) 
    gSleep(200) --每次视觉检测前  延时足够
    local tRetJson = ExecutCmd("GetVisionResult", vppName)
    local jsonobj = json.decode(tRetJson)
    local tRet = jsonobj["_pipRetVec"]

    if not tRet[1]["_bPassed"] then 
        _gErrorLog(string.format( "GetSingleVisionResult: %s, failed", vppName))
    end
    return tRet[1]["_bPassed"], tRet[1]["_dXpos"], tRet[1]["_dYpos"], tRet[1]["_dApos"]
end


local CaliStep2Info = {
    _upCamTakePicPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _dwnCamTakePicPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _pickupPos = {_xPos = 0.0, _yPos = 0.0, _zPos = 0.0, _uPos = 0.0},
    _nozzleId = 0
}

--@return [luaIde.RobotCoordSysApi#TwoDimPos]
function GetSingleVisionResult2TDPRet(vppName) 
    local tNeedMoveZ = false
    if vppName == "upCamInspectPart" or
     vppName == "upCamInspectNozzle"  then 
        tNeedMoveZ = true
    end
    if tNeedMoveZ then
        curPlatform:move_single_z_with_wait(0, CaliStep2Info._upCamTakePicPos._zPos)
    end
    local tPass, tX, tY, tA = GetSingleVisionResult(vppName)
    if tNeedMoveZ then
        curPlatform:all_work_head_2_normal_with_wait()
    end
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
    local tTrans = curStation:GetTransByName("orgPos")
    tTrans:SetInputParam(twoFloat_inspectPos._fX, twoFloat_inspectPos._fY, 0.0)
    return curStation:RunSolver(twoDimPos_pixelPos, "GetPosFromDwnCam")
end

curStation = selfCoordSys:GetStationCoordSys("Machine1")

function CaliStep0Init(jsonParam)
    _localInfoLog("start CaliStep0Init")
    selfCoordSys:ClearAllStationAndInfo()
    selfCoordSys:CreateStation("Machine1")
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    curStation:CreateTrans("RbtMtn2dwnCam",TransformType.enMovedCamera)
    curStation:CreateTrans("dwnCamMarkPos", TransformType.enLinearAxis)
    curStation:CreateTrans("orgPos", TransformType.enLinearAxis)
    curStation:CreateSolverInfo("GetPosFromDwnCam")
    curStation:InsertTransInfoInSolverInfo("RbtMtn2dwnCam", "GetPosFromDwnCam", false)
    --curStation:InsertTransInfoInSolverInfo("dwnCamMarkPos", "GetPosFromDwnCam", false)
    curStation:InsertTransInfoInSolverInfo("orgPos", "GetPosFromDwnCam", false)

    curStation:CreateTrans("nozzle0RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle1RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle2RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle3RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle4RotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle5RotatePixelCenter",TransformType.enRotateAxis)

    --通过帖放的方式  可以知道下相机到机器人坐标的映射  
    curStation:CreateTrans("Nozzle0RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle1RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle2RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle3RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle4RbtMtn2UpCam", TransformType.enFixedCamera)
    curStation:CreateTrans("Nozzle5RbtMtn2UpCam", TransformType.enFixedCamera)

    curStation:CreateTrans("nozzle0UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle1UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle2UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle3UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle4UpCamTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle5UpCamTakePicPos", TransformType.enLinearAxis)

    curStation:CreateTrans("nozzle0UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle1UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle2UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle3UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle4UpCamUNormalPixelPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzle5UpCamUNormalPixelPos", TransformType.enLinearAxis)

    curStation:CreateTrans("nz0G0EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz1G0EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz2G0EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz3G0EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz4G0EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz5G0EMPos2RealPos",  TransformType.enXYDisperseMap)

    curStation:CreateTrans("nz0G1EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz1G1EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz2G1EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz3G1EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz4G1EMPos2RealPos",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("nz5G1EMPos2RealPos",  TransformType.enXYDisperseMap)

    curStation:CreateTrans("global2Glass0",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("global2Glass1",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("topCam2Glass",  TransformType.enXYDisperseMap)

    curStation:CreateTrans("anotherGantryToThis",  TransformType.enXYDisperseMap)

    curStation:CreateTrans("anotherGantryToThis",  TransformType.enXYDisperseMap)
    local tTrans = curStation:GetTransByName("anotherGantryToThis")
    tTrans:SetMethod(1)
    curStation:CreateTrans("topCamToGlobal",  TransformType.enXYDisperseMap)
    curStation:CreateTrans("tempTray", TransformType.enTrayCoord)
    selfCoordSys:Save()
    lastRunRetStr = "ok"
end

local fsm = {}
local nextEvent = ""
local eventMsg = {}

function RunFsmToEnd() 
    while nextEvent ~= "" do
        if(localNeedStop()) then 
            _gWarnLog("recv stop cmd! will stop the statemachine!")
            nextEvent = "quit"
        end
        if(fsm[nextEvent] == nil) then 
            _gErrorLog("RunFsmToEndError!: no such event: " .. nextEvent)
            nextEvent = ""
        else
            if fsm:can(nextEvent) then
                fsm[nextEvent](fsm)
            else
                _gErrorLog("RunFsmToEndError!: can't do event in current state! event: "
                     .. nextEvent .. " curState: " .. fsm.current)
                nextEvent = ""
            end
        end
    end

    _gInfoLog(string.format("stateMachine stoped at state: %s", fsm.current))
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
            {name = "finished", from = "move2Next", to = "calOrigin"},

            {name = "success", from = "calOrigin", to = "successRet"} 
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
            oncalOrigin = onCalOrigin,
            --event的callback
            onsuccess = onSuccess,
            onfail = onFail
        }
    })

    nextEvent = "runStep1"
    RunFsmToEnd()
    _gInfoLog(string.format("calibration step1 run to state: %s", fsm.current))
end

local CaliStep1Param = {
    dwnCamCenter = {x = 640.0, y = 480.0},
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
    _gInfoLog("in onstep1Init")
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    dwnCamTrans = curStation:GetTransByName("RbtMtn2dwnCam")
    dwnCamTrans:ClearData()
    CaliStep1Param.tempParam.tempMappingFinished = false
    nextEvent = "success"
end

function onTestDwnCamInspectMark(self, event, from, to)
    _gInfoLog("in testDwnCam")
    local passed, _, _ = GetSingleVisionResult("dwnCamInspectMark")
    if not passed then
        nextEvent = "fail"
    else
        nextEvent = "success"
    end
end

function onAbort(self, event, from, to)
    _gInfoLog("in onsuccessRet")
    lastRunRetStr = "abort"
    nextEvent = ""
end

function onSuccessRet(self, event, from, to)
    _gInfoLog("in onsuccessRet")
    selfCoordSys:Save()
    selfCoordSys:Init("")
    lastRunRetStr = "ok"
    nextEvent = ""
end

function onErrorRet(self, event, from, to)
    _gInfoLog("in onerrorRet")
    lastRunRetStr = "fail"
    nextEvent = ""
end

function onSuccess(self, event, from, to, msg)
    _gInfoLog("Fire event: success: from: " .. from .. " to: " .. to)
end

function onFail(self, event, from, to, msg)
    _gInfoLog("Fire event: fail: from: " .. from .. " to: " .. to)
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

function onCalOrigin(self, event, from, to) --把原点在机器人坐标系的位置找出来
    nextEvent = "success"
end

function CaliStep2ForUpCam(jsonParam)
    CaliStep2Info = json.decode(jsonParam)
    fsm = sMachine.create({
        initial = "startStep2",
        events = {
            {name = "runStep2", from = "startStep2", to = "step2Init"},

            {name = "quit", from = {"startStep2","step2Init","testAll","findNozzleRotCenterByDwnCam",
            "updataPickPlaceTable","findNozzleRotCenterByUpCam","moveNozzleNextPos","pickupAndInspectByUpCam",
            "placeDownToSamePlace", "recheckPartPos", "moveAndPickUp", "moveNozzleNextPosOnUpCam"}, to = "abort"},

            {name = "fail", from = {"startStep2","step2Init","testAll","findNozzleRotCenterByDwnCam",
            "updataPickPlaceTable","findNozzleRotCenterByUpCam","moveNozzleNextPos","pickupAndInspectByUpCam",
            "placeDownToSamePlace", "recheckPartPos", "moveAndPickUp", "moveNozzleNextPosOnUpCam"}, to = "errorRet"},

            {name = "success", from = "step2Init", to = "testAll"},
            
            {name = "success", from = "testAll", to = "findNozzleRotCenterByUpCam"}, 

            --[[-吸嘴旋转中心和上相机的偏差并不重要 如果知道在下相机拍照位置吸嘴捅下去后物料的位置  
                那么就能知道需要移动多少offset 就能贴到目标位置]]
            -- {name = "success", from = "findNozzleRotCenterByDwnCam", to = "updataPickPlaceTable"}, 

            {name = "success", from = "findNozzleRotCenterByUpCam", to = "updataPickPlaceTable"},

            {name = "success", from = "updataPickPlaceTable", to = "moveNozzleNextPos"},
            {name = "startMappingOnUpCam", from = "updataPickPlaceTable", to ="moveAndPickUp"},

            {name = "success", from = "moveNozzleNextPos", to = "pickupAndInspectByUpCam"},
            {name = "tempFinished", from = "moveNozzleNextPos", to = "updataPickPlaceTable"},
            {name = "finished", from = "moveNozzleNextPos", to = "successRet"},

            {name = "success", from = "pickupAndInspectByUpCam", to = "placeDownToSamePlace"},

            {name = "success", from = "placeDownToSamePlace", to = "recheckPartPos"},

            {name = "success", from = "recheckPartPos", to = "moveNozzleNextPos"},

            {name = "success", from = "moveAndPickUp", to = "moveNozzleNextPosOnUpCam"},

            {name = "success", from = "moveNozzleNextPosOnUpCam", to = "skip"},
            {name = "finished", from = "moveNozzleNextPosOnUpCam", to = "successRet"},
			{name = "success", from = "skip", to = "moveNozzleNextPosOnUpCam"},
			startMappingOnUpCam
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

            onmoveAndPickUp = onMoveAndPickUp,
            onmoveNozzleNextPosOnUpCam = onMoveNozzleNextPosOnUpCam,
			
			onskip = function(self, event, from, to) nextEvent = "success" end,
            --event的callback
            onsuccess = onSuccess,
            onfail = onFail
        }
    })

    nextEvent = "runStep2"
    RunFsmToEnd()
    _gInfoLog(string.format("calibration step1 run to state: %s", fsm.current))
end


local CaliStep2Param = {
    upCamCenter = {x = 640.0, y = 480.0},
    stepLen = 1.2,
--	stepLen = 1.5, 1.5 * 2,
    scale = 5, --标定玻片内径是9mm 应该不会走出去
    isFixedUpCam = false, --true固定的下相机可以不使用来回贴放建表的方式 而是直接吸住标定片在视野中移动即可

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
	if tRet ~= true then
		_gErrorLog("motion error  retry...")
		tRet = curPlatform:move_single_with_wait(xyzu_axis.z_axis, zPos) 
	end
	if tRet ~=true then
		return tRet
	end
    gSleep(100)
    tWorkhead:vacuum_open_with_delay(300)
    tRet = curWorkHead:get_z_u():z_2_normal_with_wait()
    if tRet == false then
        _gErrorLog("motion error  retry...")
        tRet = curWorkHead:get_z_u():z_2_normal_with_wait()
    end
    return tRet
end

function NozzlePutdown(nozzleId, zPos)
    curPlatform:set_cur_work_head(nozzleId)
    local tWorkhead = curPlatform:get_work_head(nozzleId)

    local tRet = curPlatform:move_single_with_wait(xyzu_axis.z_axis, zPos)
		if tRet ~= true then
		_gErrorLog("motion error  retry...")
		tRet = curPlatform:move_single_with_wait(xyzu_axis.z_axis, zPos) 
	end
	if tRet ~=true then
		return tRet
	end
    tWorkhead:vacuum_close()
    gSleep(100)
    tWorkhead:vacuum_break()
    gSleep(100)
    tWorkhead:vacuum_break_close()
    gSleep(300)
    tRet = curWorkHead:get_z_u():z_2_normal_with_wait()
    if tRet == false then
        _gErrorLog("motion error  retry...")
        tRet = curWorkHead:get_z_u():z_2_normal_with_wait()
    end
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
        _gErrorLog("failed to move to pickupPos!")  
        return 
    end

    NozzlePickup(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)
    
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._upCamTakePicPos._xPos,
                    CaliStep2Info._upCamTakePicPos._yPos, CaliStep2Info._upCamTakePicPos._uPos)
    if not tRet then 
        nextEvent = "fail" 
        _gErrorLog("failed to move to upCamTakePicPos!")  
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
        _gErrorLog("failed to move to pickupPos!")  
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
    _gWarnLog(string.format( "part moved in dwnCam: x: %.2f, y: %.3f, a: %.3f", xOffset, yOffset, aOffset))
    if(math.abs(xOffset) > 3 or math.abs(yOffset) > 3 or math.abs(aOffset) > 1) then 
        _gErrorLog("parts moved too much during the pick and place ")
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
        _gErrorLog("failed to move to upCamTakePicPos!")  
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
        _gErrorLog("failed to move to pickupPos!")  
        return 
    end
    NozzlePickup(CaliStep2Param.tempParam.curNozzleIndex, CaliStep2Info._pickupPos._zPos)
    tRet = curPlatform:move_single_with_wait(xyzu_axis.u_axis, CaliStep2Info._pickupPos._uPos + 180)
    if not tRet then 
        nextEvent = "fail" 
        _gErrorLog("failed to move to rotate!")  
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
    _gInfoLog(string.format( "nozzle %d rotate center offset to dwnCamCent: x: %.3f, y: %.3f",
            CaliStep2Info._nozzleId, xOffset, yOffset))
    local tTrans = curStation:GetTransByName(string.format("nozzle%dRotCentOffset2DwnCam", CaliStep2Info._nozzleId))
    tTrans:SetInnerParam(xOffset, yOffset, 0.0)
    CaliStep2Param.tempParam.curNozzleCenterOffset2DwnCam = tTrans:GetInnerParamWithTDP()

    --扔回 原来的位置  并检测具体位置
    tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
    CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos + 180)
    if not tRet then 
        nextEvent = "fail" 
        _gErrorLog("failed to move to pickupPos!")  
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

        if CaliStep2Param.isFixedUpCam then --如果是固定相机 则直接在下相机的拍照位置移动建表
            DistXYTable:CreateAllPos(CaliStep2Info._upCamTakePicPos._xPos, CaliStep2Info._upCamTakePicPos._yPos,
                CaliStep2Param.scale, CaliStep2Param.stepLen, CaliStep2Param.stepLen)
            nextEvent = "startMappingOnUpCam"
			return
        end

        --此时_pickupPos已经被初步试教数据来精准对准  
        DistXYTable:CreateAllPos(CaliStep2Info._pickupPos._xPos, CaliStep2Info._pickupPos._yPos,
                CaliStep2Param.scale, CaliStep2Param.stepLen, CaliStep2Param.stepLen)
    else
        --开始临时校准  使用2*2的规模
        tTrans:ClearData()
        DistXYTable:CreateAllPos(CaliStep2Info._pickupPos._xPos, CaliStep2Info._pickupPos._yPos,
                                2, CaliStep2Param.stepLen / 2, CaliStep2Param.stepLen / 2)                       
    end
    
    nextEvent = "success"
end

function onMoveAndPickUp(self, event, from, to)
    local tRet = curPlatform:move_xyu_with_wait(CaliStep2Info._pickupPos._xPos, 
            CaliStep2Info._pickupPos._yPos, CaliStep2Info._pickupPos._uPos)
            
    tRet = tRet and NozzlePickup(CaliStep2Info._nozzleId, CaliStep2Info._pickupPos._zPos)
    if tRet then
        nextEvent = "success"
    else
        nextEvent = "fail"
    end
end

function onMoveNozzleNextPosOnUpCam(self, event, from, to)
    local tTrans = curStation:GetTransByName(string.format("Nozzle%dRbtMtn2UpCam", CaliStep2Info._nozzleId))
    local notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
    if notFinished then
        local tRet = curPlatform:move_xyu_with_wait(nextPosX, nextPosY, 
                CaliStep2Info._pickupPos._uPos)
        if not tRet then
            nextEvent = "fail"
            return
        end

        local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectPart")
        if not tVsnRetPass then
            nextEvent = "fail"
            return
        end

        ---存表方式同贴装法 source坐标为 标定片全局位置 + (下相机拍照位置 - 取料位置)
        local tX = CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fX +
           nextPosX - CaliStep2Info._pickupPos._xPos
        local tY = CaliStep2Param.tempParam.partPosBeforePickup._tfPos._fY +
           nextPosY - CaliStep2Info._pickupPos._yPos
        tTrans:SetOnePairData(TwoDimPos.newCustom(tX, tY, 0), tVisionRetPos)
        nextEvent = "success"
    else
        nextEvent = "finished"
    end
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
        _gErrorLog("failed to move to upCamTakePicPos!")  
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
        _gErrorLog("failed to move to upCamTakePicPos!")  
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
    _gWarnLog(string.format("parts offset after pick and place : x:%.3f, y:%.3f, a:%.3f", xOffset, yOffset, aOffset))
    -- if(math.abs(xOffset) > 0.03 or math.abs(yOffset) > 0.03 or math.abs(aOffset) > 0.1) then
    if(math.abs(xOffset) > 0.1 or math.abs(yOffset) > 0.1 or math.abs(aOffset) > 1) then -- 只能放宽 目前丢下去有动
        _gErrorLog("parts moved too far. error!")
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



--------------------------------recheck station----------------------------------------

function RecheckStationInit(jsonParam)
    _localInfoLog("start RecheckStationInit")
    selfCoordSys:CreateStation("Recheck")
    curStation = selfCoordSys:GetStationCoordSys("Recheck")
    curStation:CreateTrans("RbtMtn2dwnCam",TransformType.enMovedCamera)
    curStation:CreateTrans("dwnCamMarkPos", TransformType.enLinearAxis)
    curStation:CreateSolverInfo("GetPosFromDwnCam")
    curStation:InsertTransInfoInSolverInfo("RbtMtn2dwnCam", "GetPosFromDwnCam", false)
    curStation:InsertTransInfoInSolverInfo("dwnCamMarkPos", "GetPosFromDwnCam", false)

    selfCoordSys:Save()
    lastRunRetStr = "ok"
end

function RecheckCaliStep1ForDwnCam(jsonParam) 
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
            onstep1Init = onRecheckStep1Init,
            ontestDwnCamInspectMark = onTestDwnRecheckCamInspectMark,
            onabort= onAbort,
            onsuccessRet = onSuccessRet,
            onerrorRet = onErrorRet,
            onupdataDistTable = onUpdataDistTable,
            onmove2Next = onMove2Next,
            ondwnCamInspectMark = onDwnRecheckCamInspectMark,

            --event的callback
            onsuccess = onSuccess,
            onfail = onFail
        }
    })

    nextEvent = "runStep1"
    RunFsmToEnd()
    _gInfoLog(string.format("calibration step1 run to state: %s", fsm.current))
end

function onRecheckStep1Init(self, event, from, to)
    _gInfoLog("in onReStep1Init")
    curStation = selfCoordSys:GetStationCoordSys("Recheck")
    dwnCamTrans = curStation:GetTransByName("RbtMtn2dwnCam")
    curPlatform = gMotIoMan:get_xyzu_platform("recheck")
    dwnCamTrans:ClearData()
    CaliStep1Param.tempParam.tempMappingFinished = false
    ---TODO 有可能需要重新改写 CaliStep1Param.dwnCamCenter 的坐标
    nextEvent = "success"
end

function onTestDwnRecheckCamInspectMark(self, event, from, to)
    _gInfoLog("in testDwnCam")
    local passed, _, _ = GetSingleVisionResult("dwnRecheckCamInspectMark")
    if not passed then
        nextEvent = "fail"
    else
        nextEvent = "success"
    end
end

function onDwnRecheckCamInspectMark(self, event, from, to)
    local passed, pixelX, pixelY = GetSingleVisionResult("dwnRecheckCamInspectMark")
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


---------------error mapping for nozzle----------------
local emCallback = {}
local emParam = {
--    startPos = {x = 0, y = 0}, endPos0 = {x = 0, y = 0}, endPos1 = {x = 0, y = 0},
--    stepX = 11, stepY = 8
    nozzleId = 0,
    gantryId = 0,
    pickUpZ = -1.0
}
local emStates = {
    abort = "abort", successRet = "successRet", errorRet = "errorRet",

    init = "init",
    pickUp = "pickUp",
    moveToPickupPlace = "moveToPickupPlace",
    placeDown = "placeDown",
    moveToPlacePos = "moveToPlacePos",
    moveToUpCamInspectPlace = "moveToUpCamInspectPlace",
    moveToDwnCamInspectPlace = "moveToDwnCamInspectPlace",
    upCamInspect = "upCamInspect",
    dwnCamInspect = "dwnCamInspect",
    getNext = "getNext",

    recheckInit = "recheckInit",
}
local emEventNames = {
    quit = "quit",
    fail = "fail",
    success = "success",
    finished = "finished",
    start = "start"
}
local emEvents = {
    {   
        name = emEventNames.fail, 
        from = {emStates.init, emStates.pickUp, emStates.moveToDwnCamInspectPlace, emStates.getNext,
        emStates.moveToUpCamInspectPlace, emStates.upCamInspect, emStates.dwnCamInspect},
        to = emStates.errorRet 
    },
    {   
        name = emEventNames.quit, 
        from = {emStates.init, emStates.pickUp, emStates.moveToDwnCamInspectPlace, emStates.getNext,
        emStates.moveToUpCamInspectPlace, emStates.upCamInspect, emStates.dwnCamInspect},
        to = emStates.abort
    },
    {name = emEventNames.start, from = "Start", to = emStates.init},

    {name = emEventNames.success, from = emStates.init, to = emStates.dwnCamInspect},
    {name = emEventNames.success, from = emStates.dwnCamInspect, to = emStates.getNext},
    {name = emEventNames.success, from = emStates.getNext, to = emStates.moveToPickupPlace},
    {name = emEventNames.success, from = emStates.moveToPickupPlace, to = emStates.pickUp},
    {name = emEventNames.success, from = emStates.pickUp, to = emStates.moveToUpCamInspectPlace},
    {name = emEventNames.success, from = emStates.moveToUpCamInspectPlace, to = emStates.upCamInspect},
    {name = emEventNames.success, from = emStates.upCamInspect, to = emStates.moveToPlacePos},
    {name = emEventNames.success, from = emStates.moveToPlacePos, to = emStates.placeDown},
    {name = emEventNames.success, from = emStates.placeDown, to = emStates.moveToDwnCamInspectPlace},
    {name = emEventNames.success, from = emStates.moveToDwnCamInspectPlace, to = emStates.dwnCamInspect},

    {name = emEventNames.finished, from = emStates.getNext, to = emStates.successRet},
}
local emBlackboard = {
    lastUpCamInspectRet = TwoDimPos.newCustom(0, 0, 0),
    lastPlacePartDstPos = TwoDimPos.newCustom(0, 0, 0),
    lastPickUpPartDstPos = TwoDimPos.newCustom(0, 0, 0),
    ---@type TwoDimCoordTrans
    curTrans =  {},

    saveError2Trans = true,
    pickOffsetX = 0, pickOffsetY = 0, pickOffsetA = 0,
    report = "",
    
    placeUseCompansation = false,
}

emCallback.onsuccess = onSuccess
emCallback.onfail = onFail
emCallback.onabort = onAbort
emCallback.onsuccessRet = function(self, event, from, to)
    _gInfoLog("in onsuccessRet")
 --   selfCoordSys:Save()
 --   selfCoordSys:Init("")
    lastRunRetStr = "ok"
    nextEvent = ""
end
emCallback.onerrorRet = onErrorRet

local pointsForEmOnGlass = {
    {
        mask = { --标志为1 对应0轨玻璃板上的点为需要做placeErrorMapping的 反之则跳过 共 15 * 12
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
        },
        fixOffsetForEachPoint = {x = 0, y = 0},
        startIndex = 1, endIndex = 15 * 12, xStep = 8, yStep = 6, --不同于前面的mask 这是另一种计算贴放位置的参数
    },
    {
        mask = { --标志为1 对应0轨玻璃板上的点为需要做placeErrorMapping的 反之则跳过 共 15 * 12
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
            1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
        },
        fixOffsetForEachPoint = {x = 0, y = 0},
        startIndex = 1, endIndex = 15 * 12, xStep = 8, yStep = 6, 
    }
}
function DistXYTable:CreateFromListWithMask(pointsList)
    local pointsCount = #pointsList
    self.nextPos = 1
    self.allPos = {}
    local tCount = 0
    local tTable = pointsForEmOnGlass[emParam.gantryId + 1]
    for i = 1, pointsCount do
		if tTable.mask[i] ~= 0 then
            table.insert(self.allPos, { x = pointsList[i]._dX + tTable.fixOffsetForEachPoint.x, 
                                        y = pointsList[i]._dY + tTable.fixOffsetForEachPoint.y})
            tCount = tCount + 1
		end
    end
    _gInfoLog("create a place table for " .. tCount .. " points")
end
function DistXYTable:CreateFromListWithParam(pointsList)
    self.nextPos = 1
    self.allPos = {}
    local tCount = 0
    local tTable = pointsForEmOnGlass[emParam.gantryId + 1]
    local xGapLen = (pointsList[tTable.endIndex]._dX - pointsList[tTable.startIndex]._dX) / (tTable.xStep - 1)
    local yGapLen = (pointsList[tTable.endIndex]._dY - pointsList[tTable.startIndex]._dY) / (tTable.yStep - 1)
    for j = 1, tTable.yStep do
        for i = 1, tTable.xStep do
            table.insert(self.allPos, { x = pointsList[tTable.startIndex]._dX + (i - 1) * xGapLen,
                                        y = pointsList[tTable.startIndex]._dY + (j - 1) * yGapLen})
            tCount = tCount + 1
        end
    end
    _gInfoLog("create a place table for " .. tCount .. " points")
end

function emCallback:oninit(event, from, to)
    --创建需要贴放的表格 从指定文件读出来
    local filePath = curPath .. string.format(
        "../../../robot_%d/RobotCoordSys/default/machine1/global2Glass%d.json", emParam.gantryId + 1, emParam.gantryId) 
	--local filePath = string.format("D:/PPBin/PP02/configs/AutoPP02Test/robot_%d/RobotCoordSys/default/machine1/global2Glass%d.json", emParam.gantryId + 1, emParam.gantryId)
    _gInfoLog("read place table from: " .. filePath)
    local jsonFile = io.open(filePath, "r")
    local jsonStr = jsonFile:read("*a")
    jsonFile:close()
    local jsonObj = json.decode(jsonStr)
    local points = jsonObj["_posSourceVec"]
    if #points == #pointsForEmOnGlass[emParam.gantryId + 1].mask then
        nextEvent = emEventNames.success
    else
        _gErrorLog(string.format("points count not match, pintsInGlassCount = %d, maskCount = %d",
                    #points, #pointsForEmOnGlass[emParam.gantryId + 1].mask))
        nextEvent = emEventNames.fail
    end
    --DistXYTable:CreateFromListWithMask(points)
    DistXYTable:CreateFromListWithParam(points)
    curPlatform:set_velocity_related_2_percent(60)
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    curWorkHead = curPlatform:get_work_head(emParam.nozzleId)
    
    emBlackboard.saveError2Trans = true
    emBlackboard.curTrans = curStation:GetTransByName(string.format(
        "nz%dG%dEMPos2RealPos", emParam.nozzleId, emParam.gantryId))
    emBlackboard.curTrans:ClearData()
    emBlackboard.placeUseCompansation = false
end

function emCallback:ondwnCamInspect(event, from, to)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = emEventNames.fail
        return
    end
    local curPos = curPlatform:get_pos()
    local partPos = GetPosFromDwnCam(tVisionRetPos, TwoFloat.newCustom(curPos.x_pos, curPos.y_pos))
    if from ~= emStates.init and from ~= emStates.recheckInit then
        local xError = partPos._tfPos._fX - emBlackboard.lastPlacePartDstPos._tfPos._fX
        local yError = partPos._tfPos._fY - emBlackboard.lastPlacePartDstPos._tfPos._fY
        local aError = partPos._fAngle - emBlackboard.lastPlacePartDstPos._fAngle
        --记录偏差到坐标库
        if emBlackboard.saveError2Trans then
            _gWarnLog(string.format("error at (%.2f, %.2f) -> (%.2f, %.2f)", 
                emBlackboard.lastPlacePartDstPos._tfPos._fX, emBlackboard.lastPlacePartDstPos._tfPos._fY,
                xError, yError))
            emBlackboard.curTrans:SetOnePairData(emBlackboard.lastPlacePartDstPos, partPos)
        else
			local errorReport = string.format("pick offset at (%.2f, %.2f, %.2f)  place error at (%.2f, %.2f)",
                emBlackboard.pickOffsetX, emBlackboard.pickOffsetY, emBlackboard.pickOffsetA, xError, yError, aError)
			emBlackboard.report = string.format("%s \n %s", emBlackboard.report, errorReport)
            _gWarnLog(errorReport)
        end
    else
        if emBlackboard.saveError2Trans then
            _gWarnLog("first time. skip record")
        end
    end
    emBlackboard.lastPickUpPartDstPos = partPos

    if emBlackboard.saveError2Trans == false then --如果是复检贴放 则在取料的时候叠加一个随机误差
        emBlackboard.pickOffsetX = math.random(-200, 200) / 100.0
        emBlackboard.pickOffsetY = math.random(-200, 200) / 100.0
        emBlackboard.pickOffsetA = math.random(-12, 12)
        emBlackboard.lastPickUpPartDstPos._tfPos._fX = emBlackboard.lastPickUpPartDstPos._tfPos._fX + emBlackboard.pickOffsetX
        emBlackboard.lastPickUpPartDstPos._tfPos._fY = emBlackboard.lastPickUpPartDstPos._tfPos._fY + emBlackboard.pickOffsetY
        emBlackboard.lastPickUpPartDstPos._fAngle = emBlackboard.lastPickUpPartDstPos._fAngle + emBlackboard.pickOffsetA
    end
end

function emCallback:ongetNext(event, from, to)
    local notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
    if notFinished then
        emBlackboard.lastPlacePartDstPos = TwoDimPos.newCustom(nextPosX, nextPosY, 0)
        nextEvent = emEventNames.success
    else
		if emBlackboard.saveError2Trans then
			if emBlackboard.curTrans:Save() then
				nextEvent = emEventNames.finished
			else
				nextEvent = emEventNames.fail
			end
		else
			_gWarnLog(emBlackboard.report)
			nextEvent = emEventNames.finished
		end
    end
end

function emCallback:onmoveToPickupPlace(event, from ,to)
    local tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamUNormalPixelPos", emParam.nozzleId))
    local dstPos = AllignNozle2Pos(emParam.nozzleId, tTrans:GetInnerParamWithTDP(), emBlackboard.lastPickUpPartDstPos)
	--_gInfoLog("emCallback:onmoveToPickupPlace")
	while dstPos._fAngle > 180.00 do
		dstPos._fAngle = dstPos._fAngle - 360.0
	end
	while dstPos._fAngle <= -180.00 do
		dstPos._fAngle = dstPos._fAngle + 360.0
	end
    local ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle)
    if ret then
        nextEvent = emEventNames.success
    else
        _gErrorLog("motion error  retry...")
		ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle) 
		if ret then
			nextEvent = emEventNames.success
		else
			nextEvent = emEventNames.fail
		end
    end
end

function emCallback:onpickUp(event, from, to)
    if NozzlePickup(emParam.nozzleId, emParam.pickUpZ) then
        nextEvent = emEventNames.success
    else
        nextEvent = emEventNames.fail
    end
end

function emCallback:onmoveToUpCamInspectPlace(event, from, to)
    local tTrans = curStation:GetTransByName(string.format("nozzle%dUpCamTakePicPos", emParam.nozzleId))
    local dstPos = tTrans:GetInnerParamWithTDP()
    local ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle)
    if ret then
        nextEvent = emEventNames.success
    else
        _gErrorLog("motion error  retry...")
		ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle) 
		if ret then
			nextEvent = emEventNames.success
		else
			nextEvent = emEventNames.fail
		end
    end
end

function emCallback:onupCamInspect(event, from, to)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("upCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = emEventNames.fail
        return
    end
    emBlackboard.lastUpCamInspectRet = tVisionRetPos
    nextEvent = emEventNames.success
end

function emCallback:onmoveToPlacePos(event, from, to)
    if emBlackboard.placeUseCompansation then
		emBlackboard.lastPlacePartDstPos = 
			GetPlacePosWithCompensation(emParam.nozzleId, emParam.gantryId, emBlackboard.lastPlacePartDstPos)
    end
    local dstPos =  AllignNozle2Pos(emParam.nozzleId, emBlackboard.lastUpCamInspectRet, emBlackboard.lastPlacePartDstPos)
    local ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle)    
    if ret then
        nextEvent = emEventNames.success
        gSleep(300)
    else
		_gErrorLog("motion error  retry...")
		ret = curPlatform:move_xyu_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY, dstPos._fAngle) 
		if ret then
			nextEvent = emEventNames.success
		else
			nextEvent = emEventNames.fail
		end
    end
end

function emCallback:onplaceDown(event, from, to)
    if NozzlePutdown(emParam.nozzleId, emParam.pickUpZ) then
        nextEvent = emEventNames.success
    else
        nextEvent = emEventNames.fail
    end
end

function emCallback:onmoveToDwnCamInspectPlace(event, from, to)
    local dstPos = AllignDwnCam2Pos(emBlackboard.lastPlacePartDstPos)
    local ret = curPlatform:move_xy_with_wait(dstPos._tfPos._fX, dstPos._tfPos._fY)    
    if ret then
        nextEvent = emEventNames.success
    else
        nextEvent = emEventNames.fail
    end
end

---@param dstPos TwoDimPos
---@return TwoDimPos
function AllignDwnCam2Pos(dstPos)
    local tAlignPos = GetPosFromDwnCam(_tdpDwnCamCenter, TwoFloat.newCustom(0, 0))
    return TwoDimPos.newCustom( dstPos._tfPos._fX - tAlignPos._tfPos._fX,
                                dstPos._tfPos._fY - tAlignPos._tfPos._fY, 0)
end


---@param dstPos TwoDimPos
---@return TwoDimPos
function GetPlacePosWithCompensation(nzId, convId, dstPos)
    local tTrans = curStation:GetTransByName(string.format("nz%dG%dEMPos2RealPos", nzId, convId))
    return tTrans:FromTargetToSource(dstPos)
end

---@param nzId number
---@param pixPosOnUpCam TwoDimPos
---@param dstPos TwoDimPos
---@return TwoDimPos
function AllignNozle2Pos(nzId, pixPosOnUpCam, dstPos)
    return MoveNozzleToPos(nzId, dstPos, pixPosOnUpCam)
end

function ErrorMappingForNozzle(jsonParam)
    emParam = json.decode(jsonParam)
    curPlatform:set_cur_work_head(emParam.nozzleId)
    fsm = sMachine.create({
        initial = "Start",
        events = emEvents,
        callbacks = emCallback
    })

    nextEvent = emEventNames.start
    RunFsmToEnd()
    _gInfoLog(string.format("errorMapping run to state: %s", fsm.current))

end

------------------------- recheck place to calibraiton pos -------------------------------------------------
-----做完吸嘴和下相机的标定后 直接就在当前位置 随机给定取料偏差来贴放 看误差为多少
local RecheckInfo = {
_nozzleId = 0,
_pickupZ = -1.0,
_partPosBeforePickupX=0,
_partPosBeforePickupY=0,
_partPosBeforePickupA=0,
}
local recheckPlaceEvents = {
    {   
        name = emEventNames.fail, 
        from = {emStates.recheckInit, emStates.pickUp, emStates.moveToDwnCamInspectPlace, emStates.getNext,
        emStates.moveToUpCamInspectPlace, emStates.upCamInspect, emStates.dwnCamInspect},
        to = emStates.errorRet 
    },
    {   
        name = emEventNames.quit, 
        from = {emStates.recheckInit, emStates.pickUp, emStates.moveToDwnCamInspectPlace, emStates.getNext,
        emStates.moveToUpCamInspectPlace, emStates.upCamInspect, emStates.dwnCamInspect},
        to = emStates.abort
    },
    {name = emEventNames.start, from = "Start", to = emStates.recheckInit},

    {name = emEventNames.success, from = emStates.recheckInit, to = emStates.dwnCamInspect},
    {name = emEventNames.success, from = emStates.dwnCamInspect, to = emStates.getNext},
    {name = emEventNames.success, from = emStates.getNext, to = emStates.moveToPickupPlace},
    {name = emEventNames.success, from = emStates.moveToPickupPlace, to = emStates.pickUp},
    {name = emEventNames.success, from = emStates.pickUp, to = emStates.moveToUpCamInspectPlace},
    {name = emEventNames.success, from = emStates.moveToUpCamInspectPlace, to = emStates.upCamInspect},
    {name = emEventNames.success, from = emStates.upCamInspect, to = emStates.moveToPlacePos},
    {name = emEventNames.success, from = emStates.moveToPlacePos, to = emStates.placeDown},
    {name = emEventNames.success, from = emStates.placeDown, to = emStates.moveToDwnCamInspectPlace},
    {name = emEventNames.success, from = emStates.moveToDwnCamInspectPlace, to = emStates.dwnCamInspect},

    {name = emEventNames.finished, from = emStates.getNext, to = emStates.successRet},
}
function RecheckPlace(jsonParam)
    RecheckInfo = json.decode(jsonParam)
    fsm = sMachine.create({
        initial = "Start",
        events = recheckPlaceEvents,
        callbacks = emCallback
    })

    nextEvent = emEventNames.start
    RunFsmToEnd()
    _gInfoLog(string.format("recheck run to state: %s", fsm.current))

end
function emCallback:onrecheckInit(event, from, to)
    emBlackboard.saveError2Trans = false

    emParam.nozzleId = RecheckInfo._nozzleId
    emParam.pickUpZ = RecheckInfo._pickupZ

    DistXYTable.nextPos = 1
    DistXYTable.allPos = {}
    for i = 1, 4 do
        table.insert(DistXYTable.allPos, {x = RecheckInfo._partPosBeforePickupX, y = RecheckInfo._partPosBeforePickupY})
    end
    emBlackboard.lastPlacePartDstPos = TwoDimPos.newCustom(RecheckInfo._partPosBeforePickupX,
										RecheckInfo._partPosBeforePickupY, RecheckInfo._partPosBeforePickupA)
	curStation = selfCoordSys:GetStationCoordSys("Machine1")
    curWorkHead = curPlatform:get_work_head(emParam.nozzleId)
    emCallback:onmoveToDwnCamInspectPlace()
    emBlackboard.report = "error report: \n"
    emBlackboard.placeUseCompansation = false
    _gWarnLog("start place recheck")
end

-----------------------------------------------cpk---------------------------------------------
local customBoard = { --如果不传参数进来 那么让上相机停在mark0中心 其余数据由下面的数据给定
    _dotGap = 4.5,    
    _mark1GeberPos = {15, 10}, --单位为点距 下同
    _labelGeberPos = {
        {1, 1}, {5, 1}, {9, 1}, {12, 1},
        {1, 5}, {5, 5}, {9, 5}, {12, 5},
        {1, 9}, {5, 9}, {9, 9}, {12, 9},}
}
local cpkInfo = {
    _convId = 0, --必须要传入
    _markGeberPos =  {{_fX = 0.0, _fY = 0.0}, {_fX = 10.0, _fY = 10.0},},
    _markInspectPos =  {{_fX = 10.0, _fY = 10.0}, {_fX = 10.0, _fY = 10.0}, },
    _labelGeberPos = {{_fX = 99.0, _fY = 100.0}, {_fX = 10.0, _fY = 10.0}}
}
local cpkBlackboard = {
    ---@type TwoDimCoordTrans
    global2GlassTrans = {},
    ---@type TwoDimCoordTrans
    trayTrans = {},
    nextInSpectRobotPos = {x = 0, y = 0},
    dwnCamInspectMarkGlassResult = {{x = 0, y = 0}, {x = 0, y = 0}},
    ---@type TwoDimPos[]
    GlobalPosToPlace = {},
    ---@type TwoDimPos[]
    RealGlobalPosToPlace = {}, --需要贴放的位置 真实的全局位置

    finishedLocatMark = false,
}
local placeGlobalPos = {
    nextPos = 1,
    allPos = {}
}
local CpkLocateMarkInfoForSave = {
    placePosOnGlass = {{x = 100, y = 100}, {x = 200, y = 200}},
    locateError = {{x = 1, y = 1}, {x = 2, y = 2}},
    info = cpkInfo,
}
function GetGantryId()
    local tRet = 1
    if selfModuleName == "robot_2" then
        tRet = 2
    end
    return tRet
end
---@return string
function GetMarkLocateInfoFile(convId)
    local filePath = curPath .. string.format("../../../conv%dCPKMarkInfo.json", convId)
	return filePath
end
function SaveMarkLocateInfo(convId)
    local file = io.open(GetMarkLocateInfoFile(convId), "w+")
    file:write(json.encode(CpkLocateMarkInfoForSave))
    file:close()
end
function LoadMarkLocateInfo(convId)
    local file = io.open(GetMarkLocateInfoFile(convId), "r")
    CpkLocateMarkInfoForSave = json.decode(file:read("*a"))
    local tTrans = curStation:GetTransByName(string.format("global2Glass%d", convId))
    cpkBlackboard.GlobalPosToPlace = {}
    for i = 1, #CpkLocateMarkInfoForSave.placePosOnGlass do
        table.insert(cpkBlackboard.GlobalPosToPlace, 
            tTrans:FromTargetToSource(TwoDimPos.newCustom(
                CpkLocateMarkInfoForSave.placePosOnGlass[i].x,
                CpkLocateMarkInfoForSave.placePosOnGlass[i].y, 0)))
    end
    _gWarnLog(string.format("get %d points CPK info from file", #CpkLocateMarkInfoForSave.placePosOnGlass))
    file:close()
end
local cpkStates = {
    abort = "abort", successRet = "successRet", errorRet = "errorRet",

    cpkInit = "cpkInit",
    moveToDwnCamInspectPlace = "moveToDwnCamInspectPlace",
    dwnCamInspect = "dwnCamInspect",
    getNext = "getNext",
}
local cpkEvents = {
    {
        name = emEventNames.fail, 
        from = {cpkStates.cpkInit, cpkStates.moveToDwnCamInspectPlace,
         cpkStates.dwnCamInspect, cpkStates.getNext},
        to = cpkStates.errorRet
    },
    {
        name = emEventNames.quit,
        from = {cpkStates.cpkInit, cpkStates.moveToDwnCamInspectPlace,
         cpkStates.dwnCamInspect, cpkStates.getNext},
        to = cpkStates.abort
    },
    {name = emEventNames.start, from = "Start", to = cpkStates.cpkInit},
    {name = emEventNames.success, from = cpkStates.cpkInit, to = cpkStates.getNext},

    {name = emEventNames.success, from = cpkStates.getNext, to = cpkStates.moveToDwnCamInspectPlace},
    {name = emEventNames.finished, from = cpkStates.getNext, to = cpkStates.successRet},

    {name = emEventNames.success, from = cpkStates.moveToDwnCamInspectPlace, to = cpkStates.dwnCamInspect},
    {name = emEventNames.success, from = cpkStates.dwnCamInspect, to = cpkStates.getNext}
}
local lctMarkCallback = {}
lctMarkCallback.onsuccess = onSuccess
lctMarkCallback.onfail = onFail
lctMarkCallback.onabort = onAbort
lctMarkCallback.onsuccessRet = function(self, event, from, to)
    _gInfoLog("in onsuccessRet")
 --   selfCoordSys:Save()
 --   selfCoordSys:Init("")
    lastRunRetStr = "ok"
    nextEvent = ""
end
lctMarkCallback.onerrorRet = onErrorRet
function CpkForNozzleStep1LocatBoard(jsonParam)
    cpkInfo = json.decode(jsonParam)
    if cpkInfo._mark1GeberPos == null or cpkInfo._mark1GeberPos == "null" or #cpkInfo._mark1GeberPos == 0 then --填入默认板子信息
        local curPos = curPlatform:get_pos()
        cpkInfo._markInspectPos = {{_fX = curPos.x_pos, _fY = curPos.y_pos},
            {_fX = curPos.x_pos + customBoard._dotGap * customBoard._mark1GeberPos[1],
             _fY = curPos.y_pos + customBoard._dotGap * customBoard._mark1GeberPos[2]}}
        cpkInfo._markGeberPos = {{_fX = 0, _fY = 0},
            {_fX = customBoard._dotGap * customBoard._mark1GeberPos[1],
             _fY = customBoard._dotGap * customBoard._mark1GeberPos[2]}}
        cpkInfo._labelGeberPos = {}
        for i = 1, #customBoard._labelGeberPos do
            table.insert(cpkInfo._labelGeberPos, 
            {_fX = customBoard._dotGap * customBoard._labelGeberPos[i][1],
             _fY = customBoard._dotGap * customBoard._labelGeberPos[i][2]})
        end
    end
	CpkLocateMarkInfoForSave.info = cpkInfo
    ---locat mark
	cpkBlackboard.GlobalPosToPlace = {}
    cpkBlackboard.RealGlobalPosToPlace = {}
    fsm = sMachine.create({
        initial = "Start",
        events = cpkEvents,
        callbacks = lctMarkCallback
    })
    nextEvent = emEventNames.start
    RunFsmToEnd()
    _gInfoLog(string.format("cpk inspect mark run to state: %s", fsm.current))
    if fsm.current ~= cpkStates.successRet then
        _gErrorLog("inspcet Mark error, skip place")
        return
    end
end
function CpkStep2NozzlePlace(jsonParam)
    emParam = json.decode(jsonParam)
    --place then recheck one by one
    local cpkPlaceCallback = {}
    cpkPlaceCallback.oninit = cpkPlaceInit
    cpkPlaceCallback.ondwnCamInspect = cpkDwnCamInspectAftPlace
	cpkPlaceCallback.ongetNext = emCallback.ongetNext
    cpkPlaceCallback.onmoveToPickupPlace = emCallback.onmoveToPickupPlace
    cpkPlaceCallback.onpickUp = emCallback.onpickUp
    cpkPlaceCallback.onmoveToUpCamInspectPlace = emCallback.onmoveToUpCamInspectPlace
    cpkPlaceCallback.onupCamInspect = emCallback.onupCamInspect
    cpkPlaceCallback.onmoveToPlacePos = emCallback.onmoveToPlacePos
    cpkPlaceCallback.onplaceDown = emCallback.onplaceDown
    cpkPlaceCallback.onmoveToDwnCamInspectPlace = emCallback.onmoveToDwnCamInspectPlace

    cpkPlaceCallback.onsuccess = onSuccess
    cpkPlaceCallback.onfail = onFail
    cpkPlaceCallback.onabort = onAbort
    cpkPlaceCallback.onsuccessRet = function(self, event, from, to)
        _gInfoLog("in onsuccessRet")
        --   selfCoordSys:Save()
         --   selfCoordSys:Init("")
        lastRunRetStr = "ok"
        nextEvent = ""
    end
emCallback.onerrorRet = onErrorRet
    fsm = sMachine.create({
        initial = "Start",
        events = emEvents,
        callbacks = cpkPlaceCallback
    })
    nextEvent = emEventNames.start
    RunFsmToEnd()
    _gInfoLog(string.format("cpkPlace run to state: %s", fsm.current))

end

function lctMarkCallback:oncpkInit(event, from, to)
    curPlatform:set_velocity_related_2_percent(30)
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    cpkBlackboard.global2GlassTrans = curStation:GetTransByName(string.format("global2Glass%d", cpkInfo._convId))
    cpkBlackboard.trayTrans = curStation:GetTransByName("tempTray")

    DistXYTable.nextPos = 1
    DistXYTable.allPos = {  {x = cpkInfo._markInspectPos[1]._fX, y = cpkInfo._markInspectPos[1]._fY},
                            {x = cpkInfo._markInspectPos[2]._fX, y = cpkInfo._markInspectPos[2]._fY},}
    curPlatform:all_work_head_2_normal_with_wait()
    
    cpkBlackboard.finishedLocatMark = false
    nextEvent = emEventNames.success
end
function lctMarkCallback:ongetNext(event, from, to)
    local notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
    if notFinished then
        cpkBlackboard.nextInSpectRobotPos.x = nextPosX
        cpkBlackboard.nextInSpectRobotPos.y = nextPosY
        nextEvent = emEventNames.success
    else
        if cpkBlackboard.finishedLocatMark then
            SaveMarkLocateInfo(cpkInfo._convId)
            nextEvent = emEventNames.finished
            return
        end
        --计算
        cpkBlackboard.trayTrans:ClearData()
        cpkBlackboard.trayTrans:SetOnePairData(TwoDimPos.newCustom(
            cpkInfo._markGeberPos[1]._fX, cpkInfo._markGeberPos[1]._fY, 0),
             cpkBlackboard.dwnCamInspectMarkGlassResult[1])
        cpkBlackboard.trayTrans:SetOnePairData(TwoDimPos.newCustom(
            cpkInfo._markGeberPos[2]._fX, cpkInfo._markGeberPos[2]._fY, 0),
            cpkBlackboard.dwnCamInspectMarkGlassResult[2])
        DistXYTable.nextPos = 1 DistXYTable.allPos = {}
        _gWarnLog("start to calculate place pos")
        CpkLocateMarkInfoForSave.placePosOnGlass = {}
        CpkLocateMarkInfoForSave.locateError = {}
        for i = 1, #cpkInfo._labelGeberPos do
            local tGlassPos = cpkBlackboard.trayTrans:FromSourceToTarget(TwoDimPos.newCustom(
                cpkInfo._labelGeberPos[i]._fX, cpkInfo._labelGeberPos[i]._fY, 0))
            table.insert(CpkLocateMarkInfoForSave.placePosOnGlass, {x = tGlassPos._tfPos._fX, y = tGlassPos._tfPos._fY})
            cpkBlackboard.GlobalPosToPlace[i] = cpkBlackboard.global2GlassTrans:FromTargetToSource(tGlassPos)
			_gWarnLog(string.format("%d -> pos to place(%.3f, %.3f)", i, 
				cpkBlackboard.GlobalPosToPlace[i]._tfPos._fX, cpkBlackboard.GlobalPosToPlace[i]._tfPos._fY))
            local pos2Locate = AllignDwnCam2Pos(cpkBlackboard.GlobalPosToPlace[i])
            table.insert(DistXYTable.allPos, {x = pos2Locate._tfPos._fX, y = pos2Locate._tfPos._fY})
        end

        cpkBlackboard.finishedLocatMark = true
		notFinished, nextPosX, nextPosY = DistXYTable:GetNextDist()
		cpkBlackboard.nextInSpectRobotPos.x = nextPosX
        cpkBlackboard.nextInSpectRobotPos.y = nextPosY
        nextEvent = emEventNames.success --继续定位需要贴放的点
    end
end
function lctMarkCallback:onmoveToDwnCamInspectPlace(event, from, to)
    local ret = curPlatform:move_xy_with_wait(cpkBlackboard.nextInSpectRobotPos.x, 
                    cpkBlackboard.nextInSpectRobotPos.y)
    if ret then
        nextEvent = emEventNames.success
    else
        nextEvent = emEventNames.fail
    end
end
function lctMarkCallback:ondwnCamInspect(event, from, to)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectCpkMark")
    if not tVsnRetPass then 
        nextEvent = emEventNames.fail
        return
    end
    local tGlobalPos = GetPosFromDwnCam(tVisionRetPos, TwoFloat.newCustom(cpkBlackboard.nextInSpectRobotPos.x,
            cpkBlackboard.nextInSpectRobotPos.y))
    if not cpkBlackboard.finishedLocatMark then
        local tGlassPos = cpkBlackboard.global2GlassTrans:FromSourceToTarget(tGlobalPos)
        cpkBlackboard.dwnCamInspectMarkGlassResult[DistXYTable.nextPos - 1] = tGlassPos
    else
        cpkBlackboard.RealGlobalPosToPlace[DistXYTable.nextPos - 1] = tGlobalPos
        local curPosIndex = DistXYTable.nextPos - 1
        local xError = -tGlobalPos._tfPos._fX + cpkBlackboard.GlobalPosToPlace[curPosIndex]._tfPos._fX
        local yError = -tGlobalPos._tfPos._fY + cpkBlackboard.GlobalPosToPlace[curPosIndex]._tfPos._fY
        table.insert(CpkLocateMarkInfoForSave.locateError, {x = xError, y = yError})
        _gWarnLog(string.format("place pos index: %d(%.3f, %.3f), locate error -> (%.3f, %.3f)",
            curPosIndex,
			cpkInfo._labelGeberPos[curPosIndex]._fX, cpkInfo._labelGeberPos[curPosIndex]._fY,
            xError, yError))
    end
    nextEvent = emEventNames.success
end

function cpkPlaceInit(self, event, from, to)
    LoadMarkLocateInfo(emParam.gantryId)
    DistXYTable.nextPos = 1 DistXYTable.allPos = {}
    for i = 1, #cpkBlackboard.GlobalPosToPlace do
        table.insert(DistXYTable.allPos, { x = cpkBlackboard.GlobalPosToPlace[i]._tfPos._fX,
                                    y = cpkBlackboard.GlobalPosToPlace[i]._tfPos._fY})
    end
    emBlackboard.report = "placeErrorReport: \n"
    emBlackboard.saveError2Trans = false
    emBlackboard.placeUseCompansation = true
    nextEvent = emEventNames.success
	curPlatform:set_velocity_related_2_percent(30)    
	curStation = selfCoordSys:GetStationCoordSys("Machine1")
    curWorkHead = curPlatform:get_work_head(emParam.nozzleId)
end

function cpkDwnCamInspectAftPlace(self, event, from, to)
    local tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectPart")
    if not tVsnRetPass then 
        nextEvent = emEventNames.fail
        return
    end
    local curPos = curPlatform:get_pos()
    local partPos = GetPosFromDwnCam(tVisionRetPos, TwoFloat.newCustom(curPos.x_pos, curPos.y_pos))
    emBlackboard.lastPickUpPartDstPos = partPos
    if DistXYTable.nextPos == 1 then --第一次 不需要定位下底下的mark点 记录偏差
        nextEvent = emEventNames.success
        return
    end
--[[ --直接使用 上一次测mark后 定位贴放位置的结果来算错误 如果机器人的重复精度好就能用这个方法
    tVsnRetPass, tVisionRetPos = GetSingleVisionResult2TDPRet("dwnCamInspectCpkMark")
    if not tVsnRetPass then 
        nextEvent = emEventNames.fail
        return
    end
    local markPos = GetPosFromDwnCam(tVisionRetPos, TwoFloat.newCustom(curPos.x_pos, curPos.y_pos))
    local xError = markPos._tfPos._fX - partPos._tfPos._fX
    local yError = markPos._tfPos._fY - partPos._tfPos._fY  
]]
    local curPosIndex = DistXYTable.nextPos - 1
	local placeErrorX = partPos._tfPos._fX - cpkBlackboard.GlobalPosToPlace[curPosIndex]._tfPos._fX
	local placeErrorY = partPos._tfPos._fY - cpkBlackboard.GlobalPosToPlace[curPosIndex]._tfPos._fY
    local xError = placeErrorX + CpkLocateMarkInfoForSave.locateError[curPosIndex].x
    local yError = placeErrorY + CpkLocateMarkInfoForSave.locateError[curPosIndex].y

    local errorReport = string.format("placeDwnError:(%.3f, %.3f), TotalError(%.3f, %.3f)",
			placeErrorX, placeErrorY, xError, yError)
    emBlackboard.report = string.format("%s \n %s", emBlackboard.report, errorReport)
    _gWarnLog(string.format("error at geber(%.2f, %.2f) -> (%s)", 
        CpkLocateMarkInfoForSave.info._labelGeberPos[curPosIndex]._fX, 
        CpkLocateMarkInfoForSave.info._labelGeberPos[curPosIndex]._fY, errorReport))
    nextEvent = emEventNames.success
end

function cpkSuccessRet(self, event, from, to)
    _gInfoLog("in onsuccessRet")
    --   selfCoordSys:Save()
    --   selfCoordSys:Init("")
       lastRunRetStr = "ok"
       nextEvent = ""
end