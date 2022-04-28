
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

function testFunc(jsonParam)
    FindRealXYOffset(jsonParam)
end

--将一个点集合传入  拟合直线后将每个点距离直线的距离返回
--点集json格式:
--[[ 
"[
   {
      "x" : 1.0,
      "y" : 2.0
   },
   {
      "x" : 2.0,
      "y" : 3.0
   },
   {
      "x" : 4.0,
      "y" : 5.0
   }
]"
]]
--返回的json格式为 :
--[[
"[5.0, 6.0, 7.0]"
]]
function StraightnessOfPoints(jsonParam) 
    local tPoints = json.decode(jsonParam)
    local tTwoFloatPoints = {}
    for tIndex = 1, #tPoints do
        table.insert(tTwoFloatPoints, TwoFloat.newCustom(tPoints[tIndex].x, tPoints[tIndex].y))
    end
    local tRet = {}
    local start, dir = MyMath.FitLine(tTwoFloatPoints)
    for tIndex = 1, #tPoints do
        table.insert(tRet, MyMath.DistanceBetweenPointAndLine(tTwoFloatPoints[tIndex], start, dir))
    end
    lastRunRetStr = json.encode(tRet)
end

function FindRealXYOffset(jsonParam)
    local tJsonParamObj = json.decode(jsonParam)
    local curPath = globalPath .. "RobotCoordSys/"
    local jsonfile = io.open(curPath .. tJsonParamObj["GeberFileRelatePath"], "r")
    local xOff, yOff = tJsonParamObj["xOff"], tJsonParamObj["yOff"]
    local geberObj = json.decode(jsonfile:read("*a"))["ProductDatas"][1]["NormalBoardData"]
    local yCount, xCount = geberObj["RowNumber"], geberObj["ColNumber"]

    ---@class PosInGeber
    ---@field public XPos number
    ---@field public YPos number
    ---@field public UPos number

    ---@type PosInGeber[]
    local pointsInGeber, tTwoFloatPoints = geberObj["BomLabelList"], {}
    --拟合方向
    local xDirVec, yDirVec = {}, {}
    gInfoLog("start X Dir fit")
    for y = 1, yCount do
        for x = 1, xCount do
            table.insert(tTwoFloatPoints, TwoFloat.newCustom(pointsInGeber[x + (y - 1) * xCount].XPos,
                    pointsInGeber[x + (y - 1) * xCount].YPos))
        end
        local _, tVec = MyMath.FitLine(tTwoFloatPoints)
        gInfoLog(string.format("tVec: [%.5f, %.5f]", tVec._fX, tVec._fY))
        table.insert(xDirVec, tVec)
        tTwoFloatPoints = {}
    end

    gInfoLog("start Y Dir fit")
    for x = 1, xCount do
        tTwoFloatPoints = {}
        for y = 1, yCount do
            table.insert(tTwoFloatPoints, TwoFloat.newCustom(pointsInGeber[x + (y - 1) * xCount].XPos,
                    pointsInGeber[x + (y - 1) * xCount].YPos))
        end
        local _, tVec = MyMath.FitLine(tTwoFloatPoints)
        gInfoLog(string.format("tVec: [%.5f, %.5f]", tVec._fX, tVec._fY))
        table.insert(yDirVec, tVec)
        tTwoFloatPoints = {}
    end

    local averageTwoFloatArray = function(array)
        local ret = TwoFloat.new()
        for _, v in pairs(array) do
            ret._fX = ret._fX + v._fX
            ret._fY = ret._fY + v._fY
        end
        ret._fX = ret._fX / #array
        ret._fY = ret._fY / #array
        return ret
    end

    local xDirVecAverage, yDirVecAverage = averageTwoFloatArray(xDirVec), averageTwoFloatArray(yDirVec)

    gInfoLog(string.format("xAvg:%.4f, %.4f", xDirVecAverage._fX, xDirVecAverage._fY))
    gInfoLog(string.format("yAvg:%.4f, %.4f", yDirVecAverage._fX, yDirVecAverage._fY))
    local NomalizeDirVec = function(tfVec)
        local len = math.sqrt(tfVec._fX * tfVec._fX + tfVec._fY * tfVec._fY)
        return TwoFloat.newCustom(tfVec._fX / len, tfVec._fY / len)
    end
    xDirVecAverage, yDirVecAverage = NomalizeDirVec(xDirVecAverage), NomalizeDirVec(yDirVecAverage)
    -- 要保证xDir yDir的正确性  有可能X 反向了
    if MyMath.GetRadian(xDirVecAverage) > MyMath.GetRadian(yDirVecAverage) then
        xDirVecAverage._fX = -xDirVecAverage._fX
        xDirVecAverage._fY = -xDirVecAverage._fY
    end

    local tRet = { ["xOffset"] = xDirVecAverage._fX * xOff + yDirVecAverage._fX * yOff,
            ["yOffset"] = xDirVecAverage._fY * xOff + yDirVecAverage._fY * yOff}
    lastRunRetStr = json.encode(tRet)
    --lastRunRetStr = string.format(  "x: %.2f, y:%.2f", tRet.xOffset, tRet.yOffset)
end

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

---@param twoDimPos_pixelPos TwoDimPos
---@param twoDimPos_pixelPos TwoFloat
---@return  TwoDimPos
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

    curStation:CreateTrans("nozzleRotatePixelCenter",TransformType.enRotateAxis)
    curStation:CreateTrans("nozzle2RbtAglOffset", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzleFirstPosInCam", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzleFirstTakePicPos", TransformType.enLinearAxis)
    curStation:CreateTrans("nozzleFistPlacePos", TransformType.enLinearAxis)

    curStation:CreateTrans("tempTray",TransformType.enTrayCoord)
    curStation:CreateTrans("placeError", TransformType.enXYDisperseMap)
    curStation:GetTransByName("placeError"):SetMethod(3)  --use homography trans
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
	
---TODO:  保障xy 总是从同一个方向走到这个目的地
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

---@class CaliStep2Info
local CaliStep2Info = {
    _firstPlacePos = {_xPos = 0.0, _yPos = 0.0, _uPos = 0.0},
    _firstTakePicPos = {_xPos = 0.0, _yPos = 0.0},
    _count = 5,
    _uOffsetPerStep = 1.0,
    _visionResult = {{_xPos = 0, _yPos = 0, _uPos = 0},{_xPos = 0, _yPos = 0, _uPos = 0},{_xPos = 0, _yPos = 0, _uPos = 0}}
}

function CaliStep2ForNozzle(jsonParam)
    ---@type CaliStep2Info
    local jsonobj = json.decode(jsonParam)
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    local tRotateTrans = curStation:GetTransByName("nozzleRotatePixelCenter")
    local agloffsetTrans = curStation:GetTransByName("nozzle2RbtAglOffset")
    local takePicPosTrans = curStation:GetTransByName("nozzleFirstTakePicPos")
    local firstPosInCamTrans = curStation:GetTransByName("nozzleFirstPosInCam")
    local firstPlacePosTrans = curStation:GetTransByName("nozzleFistPlacePos")

    local takePicPos = TwoDimPos.newCustom(jsonobj_firstTakePicPos._xPos,
            jsonobj._firstTakePicPos._yPos, jsonobj._firstTakePicPos._uPos)
    takePicPosTrans:SetInnerParam(takePicPos._tfPos._fX, takePicPos._tfPos._fY, 0)
    firstPlacePosTrans:SetInnerParam(jsonobj._firstPlacePos._xPos, jsonobj._firstPlacePos._yPos,
                    jsonobj._firstPlacePos._uPos)

    local placePos = TwoDimPos.newCustom(jsonobj._firstPlacePos._xPos,
                jsonobj._firstPlacePos._yPos, jsonobj._firstPlacePos._uPos)
    ---@type TwoFloat[]
    local poses = {}
    ---@type number[]
    local agles={}
    for _, v in ipairs(jsonobj["_visionResult"]) do
        local tPos = GetPosFromDwnCam(TwoDimPos.newCustom(v._xPos, v._yPos, v._uPos), takePicPos._tfPos)
        --table.insert(poses, tPos._tfPos)
        table.insert(poses, TwoFloat.newCustom(v._xPos, v._yPos))
        table.insert(agles, tPos._fAngle)
    end

    ---计算平均角度差
    local totalAglOff = 0
    for i, v in ipairs(agles) do
        totalAglOff = totalAglOff + v - ((i-1) * jsonobj._uOffsetPerStep + placePos._fAngle)
    end
    local meanAglOff = totalAglOff / #agles
    agloffsetTrans:SetInnerParam(0, 0, meanAglOff)

    --计算圆心
    --[[  直接拟合的方式并不适合 小角度偏转的几个点  这样圆心不准 这些点对拟合的圆心来说 张开的圆弧角度也不对
    local rotCenter = MyMath.FitCircle(poses)
    tRotateTrans:SetInnerParam(rotCenter._tfPos._fX, rotCenter._tfPos._fY, 0)
    --]]
    --用个连接起始 终止 圆心的等腰三角形 来粗略模拟圆拟合
    local txDis = MyMath.Distance(poses[1], poses[#poses])
    local tyDis = (txDis / 2) / math.tan(math.rad(jsonobj._uOffsetPerStep * (#poses - 1) / 2))
    local tTrayTrans = curStation:GetTransByName("tempTray")
    tTrayTrans:ClearData()
    tTrayTrans:SetOnePairData(TwoDimPos.newCustom(txDis / 2, 0, 0), TwoDimPos.newCustom(poses[1]._fX,  poses[1]._fY, 0))
    tTrayTrans:SetOnePairData(TwoDimPos.newCustom(-txDis / 2, 0, 0), TwoDimPos.newCustom(poses[#poses]._fX,  poses[#poses]._fY, 0))
     --为负 这样如果_uOffsetPerStep为正 则-tyDis为负 从txDis到-txDis为正角度旋转
    local rotCenter = tTrayTrans:FromSourceToTarget(TwoDimPos.newCustom(0, -tyDis, 0))
    tTrayTrans:ClearData()
    rotCenter._fAngle = MyMath.Distance(poses[1], rotCenter._tfPos)
    tRotateTrans:SetInnerParam(rotCenter._tfPos._fX, rotCenter._tfPos._fY, 0)

    --汇报错误
    for i, v in pairs(poses) do
        local dis = MyMath.Distance(v, rotCenter._tfPos) - rotCenter._fAngle
        local disA = agles[i] - ((i-1) * jsonobj._uOffsetPerStep + placePos._fAngle) - meanAglOff
        gInfoLog(string.format("fitcircle error: index:%i, dis:%.2f agl:%.2f", i, dis, disA))
    end

   --考虑平均误差  估算第一个拍照结果应该是
    local firstCamPos = TwoFloat.newCustom(jsonobj._visionResult[1]._xPos, jsonobj["_visionResult"][1]._yPos)
    local tRatio = MyMath.Distance(rotCenter._tfPos, firstCamPos) / rotCenter._fAngle
    firstPosInCamTrans:SetInnerParam(tRatio * (firstCamPos._fX - rotCenter._tfPos._fX) + rotCenter._tfPos._fX,
    tRatio * (firstCamPos._fY - rotCenter._tfPos._fY) + rotCenter._tfPos._fY,
            placePos._fAngle + meanAglOff)

    selfCoordSys:Save()
    selfCoordSys:Init("")
    lastRunRetStr = "ok"
end

---@class PlaceErrorInfo
local PlaceErrorInfo = {
    _placePos = {{_xPos = 0, _yPos = 0, _uPos = 0}, {_xPos = 0, _yPos = 0, _uPos = 0}},

    _placeError = {{_xPos = 0, _yPos = 0, _uPos = 0},{_xPos = 0, _yPos = 0, _uPos = 0},{_xPos = 0, _yPos = 0, _uPos = 0}}
}
function CaliPlaceError(jsonParam)
    local errorTrans = selfCoordSys:GetStationCoordSys("Machine1"):GetTransByName("placeError")

    for i = 1, #PlaceErrorInfo do

    end
end

---@param disPos TwoDimPos
---@return TwoDimPos
function MoveNozzleToPos(disPos)
    curStation = selfCoordSys:GetStationCoordSys("Machine1")
    local tRotateTrans = curStation:GetTransByName("nozzleRotatePixelCenter")
    local agloffsetTrans = curStation:GetTransByName("nozzle2RbtAglOffset")
    local takePicPosTrans = curStation:GetTransByName("nozzleFirstTakePicPos")
    local firstPosInCamTrans = curStation:GetTransByName("nozzleFirstPosInCam")
    local firstPlacePosTrans = curStation:GetTransByName("nozzleFistPlacePos")

    local tAglOff = agloffsetTrans:GetInnerParamWithTDP()._fAngle
    local tFistPosInCam = firstPosInCamTrans:GetInnerParamWithTDP()
    local tFirstPlacePos = firstPlacePosTrans:GetInnerParamWithTDP()
    --- 偏差 = 实际标签角度 - U角度  所以U角度= 实际位置- 偏差
    local tNeedUPos = disPos._fAngle - tAglOff
    local tNeedRotate = tNeedUPos - tFirstPlacePos._fAngle
    tRotateTrans:SetInputParam(tNeedRotate, 0, 0)
    local tPos = tRotateTrans:FromSourceToTarget(tFistPosInCam)

    local tVirtualPos = GetPosFromDwnCam(tPos, takePicPosTrans:GetInnerParamWithTDP()._tfPos)
    return TwoDimPos.newCustom(tFirstPlacePos._tfPos._fX - tVirtualPos._tfPos._fX + disPos._tfPos._fX,
    tFirstPlacePos._tfPos._fY - tVirtualPos._tfPos._fY + disPos._tfPos._fY, tNeedUPos)

end