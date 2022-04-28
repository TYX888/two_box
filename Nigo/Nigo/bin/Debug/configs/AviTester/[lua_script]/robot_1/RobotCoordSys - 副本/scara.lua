local json = require("json")
local aglSin = function(x) return math.sin(math.rad(x)) end
local aglCos = function(x) return math.cos(math.rad(x)) end
-- print(package.path)
if (curPath == nil) then
    curPath = ""
end

function getArm1Length()
    local jsonfile = io.open(curPath .. "../sys/RobotCoordSys/machine1/scara.json", "r")
    local jsonstr = jsonfile:read("*a")
    local jsonobj = json.decode(jsonstr)
    return jsonobj["_dP1Length"]
end

-- local robotCoordSys = RobotCoordSys.GetPtr()
local robotCoordSys = RobotCoordSys.GetInstance()
-- local robotTrans = robotCoordSys:GetStationCoordSys("machine1"):GetTransByName("scara")

--source to target
function robotJointDgrToXy(j1, j2, j4, scaraTrans)
  local tTDP = TwoDimPos.new()
  tTDP._tfPos._fX = j1
  tTDP._tfPos._fY = j2
  tTDP._fAngle = j4
  return scaraTrans:FromSourceToTarget(tTDP)
end

--target to source
function robotXyToJointDgr(x, y, u, scaraTrans)
  local tTDP = TwoDimPos.new()
  tTDP._tfPos._fX = x
  tTDP._tfPos._fY = y
  tTDP._fAngle = u
  return scaraTrans:FromTargetToSource(tTDP)
end

local S2T_RetTDP = robotJointDgrToXy
local T2S_RetTDP = robotXyToJointDgr

function testWithCppHost()
    -- body
    local tRet = robotCoordSys:Init()
    local tStation = robotCoordSys:GetStationCoordSys("machine1")
    print(tStation:GetName())
    local tTrans = tStation:GetTransByName("scara")
    tStation:CreateTrans("testTrans", 3)
    print(tStation:GetTransByName("testTrans"):GetType())
    print("Init ret: ", tRet)
    print(tTrans:GetName())
    local tInputTDP = TwoDimPos.new()
    tInputTDP._tfPos._fY = 275
    tInputTDP._tfPos._fX = 325
    tInputTDP._fAngle = 0
    local ret = tTrans:FromTargetToSource(tInputTDP)
    print(ret._tfPos._fX, ret._tfPos._fY, ret._fAngle)
    Log("very cool!")
    local cmd = "cmd1"
    local param = ""
    local cmdRet = ExecutCmd(cmd, param)
    print(cmdRet)
    cmd = "cmd2"
    print(ExecutCmd(cmd, param))
end

function testCppStop(...)
  while not NeedStop() do
    Sleep(500)
    Log("In loop!")
  end
  Log("Out loop!")
end

function testGetVisionResult(jsonParam) 
  local tRet = getVisionResult("testGetscaraCaliStep1")
    for i = 1, #tRet do 
    Log("xPos = " .. tRet[i]["_dXpos"]) 
    Log("yPos = " .. tRet[i]["_dYpos"]) 
    Log("aPos = " .. tRet[i]["_dApos"]) 
  end
  return true
end

function testMoveRobot( jsonParam )
  moveRobot(0, 90, 120)
  return true
end

function testGetRobottCurPos( ... )
  local tRet = getRobotCurPos()
   --可用如下方法访问到 关键坐标
  Log("test getRobotCurPos j1 = " .. tRet["_dJoint1"] .. "j2 = " .. tRet["_dJoint2"] )
  return true;
end


-- 全局变量  将会被c++端查询 / 交互
lastRunRetStr = ""

--bool NeeedStop 反向查询c++端是否需要停止流程 所以长流程 的函数可以监听这个变量

--void Sleep( int ) 会绑定到c++端 入参毫秒数

--string ExecutCmd(string cmd, string param) 执行cpp端的命令

--void Log(string msg) 往cpp端写日志
function moveRobot(j1, j2, j4)
  local tRet = moveRobotSimple(j1 - 10, j2 + 15, j4)
  if tRet then 
    tRet = moveRobotSimple(j1, j2, j4)
  end
  Sleep(300)
  return tRet
end

function moveRobotSimple(j1, j2, j4) 
  local tRet = false
  local tJsonObj = {["_dJoint1"] = j1,
  ["_dJoint2"] = j2,
  ["_dJoint3"] = 0,
  ["_dJoint4"] = j4}
  local tParam = json.encode(tJsonObj)
  Log("moveRobot joint to:" .. tParam)
  local tRetStr = ExecutCmd("MoveRobotJ124", tParam)
  if(tRetStr == "pass") then
    tRet = true
  end
  return tRet
end

function getRobotCurPos()
  local tRetStr = ExecutCmd("GetCurJointPos", "")
  local tRet = json.decode(tRetStr)
  Log("getRobotCurPos ret: " .. tRetStr)
   return tRet["_dJoint1"], tRet["_dJoint2"], tRet["_dJoint3"], tRet["_dJoint4"]
end

function getVisionResult(funcName)
  local tRetStr = ExecutCmd("GetVisionGetResult", funcName)
  local jsonobj = json.decode(tRetStr)
  local tRet = jsonobj["_pipRetVec"]
  --可用如下的方法访问返回的数据 已测试
  -- for i = 1, #tRet do 
  --   print(tRet[i]["_dXpos"]) 
  --   print(tRet[i]["_dYpos"]) 
  --   print(tRet[i]["_dApos"]) 
  --   print(tRet[i]["_bPassed"])
  -- end
  return tRet
end

function getVisionSingleResult(funcName)
  local tRet = getVisionResult(funcName)
  if not tRet[1]["_bPassed"] then
    Log("getVisionSingleResult failed")
  end
  return tRet[1]["_dXpos"], tRet[1]["_dYpos"], tRet[1]["_dApos"], tRet[1]["_bPassed"]
end

-- 未测试 这样传函数是否有问题  暂时注释掉  待测试
-- function trans(in1, in2, in3, transMethod) 
--   local tInputTDP = TwoDimPos.new()
--   tInputTDP._tfPos._fX = in1
--   tInputTDP._tfPos._fY = in2
--   tInputTDP._fAngle = in3
--   local tRet = transMethod(tInputTDP)
--   return tRet._tfPos._fX, tRet._tfPos._fY, tRet._fAngle
-- end

--target to source
function xyToDgr(x, y, u, trans)
  Log(trans:GetName() .. " xyToDgr x: " .. x .. " y: " .. y)
  local tInputTDP = TwoDimPos.new()
  tInputTDP._tfPos._fX = x
  tInputTDP._tfPos._fY = y
  tInputTDP._fAngle = u
  local ret = trans:FromTargetToSource(tInputTDP)
  Log(trans:GetName() .. " xyToDgr ret: dgr1: " .. ret._tfPos._fX .. " dgr2: " .. ret._tfPos._fY)
  return ret._tfPos._fX, ret._tfPos._fY, ret._fAngle
end

--source to target
function dgrToXY(dgr1, dgr2, dgr4, trans)
  Log(trans:GetName() .. " dgrToXY dgr1: " .. dgr1 .. " dgr2: " .. dgr2)
  local tInputTDP = TwoDimPos.new()
  tInputTDP._tfPos._fX = dgr1
  tInputTDP._tfPos._fY = dgr2
  tInputTDP._fAngle = dgr4
  local ret = trans:FromSourceToTarget(tInputTDP)
  Log(trans:GetName() .. " dgrToXY ret x: " .. ret._tfPos._fX .. " y: " .. ret._tfPos._fY)
  return ret._tfPos._fX, ret._tfPos._fY, ret._fAngle
end

--简约校准  只使用一个点  认为机械手是标准的
function scaraCaliInit(jsonParam) 
  local tRet = robotCoordSys:ClearAllStationAndInfo()
  if(not tRet) then return tRet end
  tRet = robotCoordSys:CreateStation("machine1")
  if(not tRet) then return tRet end
  curStation = robotCoordSys:GetStationCoordSys("machine1")
  if(curStation == nil) then return tRet end
  --创建scara 和 上相机 两个trans 其中上相机是挂在arm2上的一个工具
  curStation:CreateTrans("scara", 7)
  curStation:CreateTrans("dwnCam", 8)
  curStation:CreateTrans("dwnCamRotate", 5) --创建头上旋转
  curStation:CreateTrans("robtMotionToDwnCam", 3) --上相机的的mapping
  curStation:CreateTrans("dwnCamMarkPos", 4) --上相机做mapping的时候 看的点的位置
  curStation:CreateTrans("robotMotionToUpCam", 2) --下相机的mapping
  curStation:CreateTrans("tempCollector", 9) --临时工具坐标系 
  curStation:CreateTrans("tempTray", 6)

  local curTrans = curStation:GetTransByName("scara")
  curTrans:SetInnerParam(299.980, 299.924, 0)
  curTrans = curStation:GetTransByName("dwnCam")
  curTrans:SetInnerParamWithStr("scara")
  curTrans = curStation:GetTransByName("tempCollector")
  curTrans:SetInnerParamWithStr("scara")
  curTrans = curStation:GetTransByName("dwnCamRotate")
  curTrans:SetInnerParam(640, 480, 0)
  --创建solver
  curStation:CreateSolverInfo("GetPosFromDwnCam")
  curStation:InsertTransInfoInSolverInfo("dwnCamRotate",
                    "GetPosFromDwnCam", true)
  curStation:InsertTransInfoInSolverInfo("robtMotionToDwnCam",
                    "GetPosFromDwnCam", false)
  curStation:InsertTransInfoInSolverInfo("dwnCamMarkPos",
                    "GetPosFromDwnCam", false)
  
  robotCoordSys:Save()
  local tRet = robotCoordSys:ClearAllStationAndInfo()
  tRet = robotCoordSys:Init()
  curStation = robotCoordSys:GetStationCoordSys("machine1")
  if tRet then
    lastRunRetStr = "scaraCaliInit Success" 
  else 
    lastRunRetStr = "scaraCaliInit Failed"
  end
  return tRet
end

-- function local param:  can change if you need
local localParam = {
  --左右手对准相关
  ["finePixcel"] = 0.55, --像素误差 认为是对准的
  ["dwnCamCenter"] = {['x'] = 640.0, ['y'] = 480.0}, --上相机中心
  ["maxAttemptTimes"] = 10, --对准的最大尝试次数  超过自动退出 返回错误
  ["stopDelay"] = 100, --停下后 等待停稳的时间
  --映射表相关
  ["scale"] = 5, --做成5*5的举证
  ["stepLength"] = 4, --每一步 走的mm的距离

 --下相机相关
  ["upCamStepX"] = 5, --因为下相机非正方向 所以分成两个配置
  ["upCamStepY"] = 5,
  ["upCamStepLength"] = 3.5, --下相机内 每一步走的mm的距离
  ["upCamPixCenter"] = {['x'] = 640.0, ['y'] = 480.0} --下相机中心
}

local dwnCamCenter = TwoDimPos.new()
dwnCamCenter._tfPos._fX = localParam["dwnCamCenter"]['x']
dwnCamCenter._tfPos._fY = localParam["dwnCamCenter"]['y']
local upCamCenter = TwoDimPos.new()
upCamCenter._tfPos._fX = localParam["upCamPixCenter"]["x"]
upCamCenter._tfPos._fY = localParam["upCamPixCenter"]["y"]

--第一步 做完 左右手 同时做好映射表
function scaraCaliStep1(jsonParam)
    local scaraTrans = curStation:GetTransByName("scara")
    local camTrans = curStation:GetTransByName("dwnCam")
    --Parse jsonParam
    local inputParam = json.decode(jsonParam)
    local rhJ1 = inputParam["_posRightHand"]["_dJoint1"]
    local rhJ2 = inputParam["_posRightHand"]["_dJoint2"]
    local lhJ1 = inputParam["_posLeftHand"]["_dJoint1"]
    local lhJ2 = inputParam["_posLeftHand"]["_dJoint2"]
    --local rhJ1, rhJ2, _, _ = xyToDgr(rhX, rhY, 0, scaraTrans)
    --scaraTrans:SetMethod(-1)
    --local lhJ1, lhJ2, _, _ = xyToDgr(lhX, lhY, 0, scaraTrans)
    --init calculate
    robotArm1L = getArm1Length()
    moveRobot(rhJ1, rhJ2, 0)
    --粗略求解 相机的位置
    local dwnCamPos = calDwnCamPos(rhJ1, rhJ2, lhJ1, lhJ2, robotArm1L)
--    local rbtJ1, rbtJ2, _, rbtJ4 = getRobotCurPos()
    local rbtJ1, rbtJ2, rbtJ4 = rhJ1, rhJ2, 0
    local markPosX, markPosY, _ = dgrToXY(rbtJ1, rbtJ2, rbtJ4, camTrans)
    --粗略做个映射 方便对准相机 到 mark 点
    local tRet = mapDwnCam(markPosX, markPosY, 
        localParam["stepLength"], (localParam["scale"] - 1) / 2 + 1)
    -- 左右手 精确对准
    if tRet then 
      local tRhj1, tRhj2, tLhj1, tLhj2, tRet = LhRhCali()
      if tRet then 
        --精确计算相机位置
        dwnCamPos = calDwnCamPos(tRhj1, tRhj2, tLhj1, tLhj2, robotArm1L)
        --移到右手
        local tRj1, tRj2, _, _ = getRobotCurPos()
        markPosX, markPosY, _ = dgrToXY(tRj1, tRj2, 0, camTrans)
        local distnPos = TwoDimPos.new() distnPos._tfPos._fX = markPosX distnPos._tfPos._fY = markPosY
        moveDwnCamToPos(distnPos, true)
        --精确映射上相机
        tRet = mapDwnCam(markPosX, markPosY, 
        localParam["stepLength"], localParam["scale"])
      end
    end
    if(tRet) then
      lastRunRetStr = "Successful running ScaraCaliStep1!"
    else
      lastRunRetStr = "Something wrong in running ScaraCaliStep1"
    end
    return tRet
end

--左右手对齐
function LhRhCali() 
  Log("LhRhCali Start!")
  local rbtJ1, rbtJ2, _, rbtJ4 = getRobotCurPos()
  local imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep1")
  if(not passed) then  return false end
  local getErrorDis = function (imgX, imgY)
    local xError = math.abs(dwnCamCenter._tfPos._fX - imgX) 
    local yError = math.abs(dwnCamCenter._tfPos._fY - imgY)
    return math.sqrt( xError * xError + yError * yError )
  end 
  local errorDis = getErrorDis(imgX,imgY)
  local _, _, _, markPos = getPosFromDwnCam(rbtJ1, rbtJ2, imgX, imgY, imgA)
  -- moveDwnCamToPos(markPos, true)
  --右手对准
  local stepCount = 1
  while(passed and stepCount < localParam["maxAttemptTimes"] 
        and (not NeedStop()) and errorDis > localParam["finePixcel"]) 
  do 
    stepCount = stepCount + 1   
    moveDwnCamToPos(markPos, true)
    imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep1")
    rbtJ1, rbtJ2, _, rbtJ4 = getRobotCurPos()
    _, _, _, markPos = getPosFromDwnCam(rbtJ1, rbtJ2, imgX, imgY, imgA)
    errorDis = getErrorDis(imgX,imgY)
  end
  if errorDis > localParam["finePixcel"] then 
    Log("LhRhCali: right hand failed!" .. stepCount ..  " error: " .. errorDis)
    return 0, 0, 0, 0, false 
  end
  local rhJ1, rhJ2 = rbtJ1, rbtJ2

  -- 换左手对准
stepCount = 1
errorDis = localParam["finePixcel"] + 1
while (passed and stepCount < localParam["maxAttemptTimes"] 
        and (not NeedStop()) and errorDis > localParam["finePixcel"]) do
    stepCount = stepCount + 1
    moveDwnCamToPos(markPos, false)
    imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep1")
    rbtJ1, rbtJ2, _, rbtJ4 = getRobotCurPos()
    _, _, _, markPos = getPosFromDwnCam(rbtJ1, rbtJ2, imgX, imgY, imgA)
    errorDis = getErrorDis(imgX, imgY)
end
if errorDis > localParam["finePixcel"] then
    Log("LhRhCali: left hand failed! Step: " .. stepCount ..  " error: " .. errorDis)
    return 0, 0, 0, 0, false
end
local lhJ1, lhJ2 = rbtJ1, rbtJ2
Log("LhRhCali: successed!")
return rhJ1, rhJ2, lhJ1, lhJ2, true
end

--知道arm1Length臂长 和 左右手用相机对准同一个点  计算相机在机械手的位置
function calDwnCamPos(rhJ1, rhJ2, lhJ1, lhJ2, arm1Length)
    local tRatio = aglSin((lhJ1 - rhJ1) / 2) / aglSin((rhJ1 + rhJ2 - lhJ1 - lhJ2) / 2)
    local ret = {
        ["camDgrOffset"] = (0 - lhJ2 - rhJ2) / 2,
        ["camArm1L"] = arm1Length,
        ["camArm2L"] = tRatio * arm1Length
    }
    Log("function: calDwnCamPos --> " .. json.encode(ret))
    local camTrans = curStation:GetTransByName("dwnCam")
    camTrans:SetInnerParam(ret["camArm2L"], ret["camDgrOffset"], 0)
    return ret
end

--做上相机的mapping
function mapDwnCam(markPosX, markPosY, stepL, stepCount)
  Log("mapDwnCam: " .. "markPosX" .. " " .. "markPosY" .. " " .. "stepL" .. " " .. "stepCount")
  local scaraTrans = curStation:GetTransByName("scara")
  local camTrans = curStation:GetTransByName("dwnCam")
  local rotTrans = curStation:GetTransByName("dwnCamRotate")
  local mapTrans = curStation:GetTransByName("robtMotionToDwnCam")
  local markPosTrans = curStation:GetTransByName("dwnCamMarkPos")
  mapTrans:ClearData()

  local startX = markPosX - stepL * (stepCount - 1) / 2
  local startY = markPosY - stepL * (stepCount - 1) / 2
  for rowStep = 1, stepCount do 
    for colStep = 1, stepCount do 
      local toPosX = startX + (rowStep - 1) * stepL
      local toPosY = startY + (colStep - 1) * stepL
      --计算相机去改位置 改怎么走
      if(not NeedStop()) then 
        local j1, j2, j4 = xyToDgr(toPosX, toPosY, 0, camTrans)
        moveRobot(j1,j2,j4)
        Sleep(300)
        local imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep1")
        if passed then 
          Log("script get vision single ret: " .. imgX .. "  " .. imgY .. "  " .. imgA)
          --将视觉结果旋转到合适的位置 插入map
          local posInMotion = TwoDimPos.new()
          local posInCam = TwoDimPos.new()
          posInMotion._tfPos._fX = toPosX posInMotion._tfPos._fY = toPosY
          rotTrans:SetInputParam(j1 + j2, 0, 0)
          -- posInCam = robotJointDgrToXy(imgX, imgY, 0, rotTrans)
          posInCam = S2T_RetTDP(imgX, imgY, 0, rotTrans)
          mapTrans:SetOnePairData(posInMotion, posInCam)
        else 
          Log("script get vision single ret failed!")
          return false
        end
        
      else
        Log("NeedStop() return ture!")
        return false
      end
    end
  end
  --将做标记的mark点的位置  记入map
  local tMarkPos = mapTrans:FromTargetToSource(dwnCamCenter)
  markPosTrans:SetInnerParam(tMarkPos._tfPos._fX, tMarkPos._tfPos._fY, 0)
  -- tempSave
  scaraTrans:Save() camTrans:Save() rotTrans:Save() mapTrans:Save() markPosTrans:Save()
  Log("mapDwnCam complete!")
  return true 
end

--从上相机里一个检测位置 求得全局位置
function getPosFromDwnCam(rbJ1, rbJ2, imgX, imgY, imgA) 
  Log("getPosFromDwnCam :" .. rbJ1 .. "; " .. rbJ2 .. "; "
        .. imgX .. "; " .. imgY .. "; " .. imgA)
  local rotTrans = curStation:GetTransByName("dwnCamRotate")
  local markPosTrans = curStation:GetTransByName("dwnCamMarkPos")
  local dwnCamTrans = curStation:GetTransByName("dwnCam")
  local posInCam = TwoDimPos.new()

  posInCam._tfPos._fX = imgX posInCam._tfPos._fY = imgY posInCam._fAngle = imgA
  rotTrans:SetInputParam(rbJ1 + rbJ2, 0, 0)

  local inspectPos = TwoDimPos.new()
  inspectPos._tfPos._fX = rbJ1 inspectPos._tfPos._fY = rbJ2
  inspectPos = dwnCamTrans:FromSourceToTarget(inspectPos)
  markPosTrans:SetInputParam(inspectPos._tfPos._fX, inspectPos._tfPos._fY, 0)

  local tRet = curStation:RunSolver(posInCam, "GetPosFromDwnCam")
  Log("getPosFromDwnCam ret: " .. tRet._tfPos._fX .. " " 
                  .. tRet._tfPos._fY .. " "  .. tRet._fAngle)
  return tRet._tfPos._fX, tRet._tfPos._fY, tRet._fAngle, tRet
end

function moveDwnCamToPos(distnPos, isRihtHand)
    local dwnCamTrans = curStation:GetTransByName("dwnCam")
    if isRihtHand then
        dwnCamTrans:SetMethod(1)
    else
        dwnCamTrans:SetMethod(-1)
    end
    local rbtNeedToGo = dwnCamTrans:FromTargetToSource(distnPos)
    moveRobot(rbtNeedToGo._tfPos._fX, rbtNeedToGo._tfPos._fY, 0)
end

function testMoveCamCenterToPos(inputParam)
  curStation = robotCoordSys:GetStationCoordSys("machine1")
  local isRihtHand = ""
  if(inputParam == "r") then 
    isRihtHand = true
  else
    isRihtHand = false
  end

  local tJ1, tJ2, _, _ = getRobotCurPos()
  local imgX, imgY, imgA, pass = getVisionSingleResult("test")
  if(pass) then
    local _, _, _, tRet = getPosFromDwnCam(tJ1, tJ2, imgX, imgY, imgA)
    moveDwnCamToPos(tRet, isRihtHand)
    lastRunRetStr = "Done!" 
  else
    lastRunRetStr = "Vision fail!"
  end
end

--简易校准 直接用可被识别的标记 来校准下相机
function scaraCaliStep2(jsonParam)
  curStation = robotCoordSys:GetStationCoordSys("machine1")
  local tRet = false 
  local upCamTrans = curStation:GetTransByName("robotMotionToUpCam")
  local scaraTrans = curStation:GetTransByName("scara")
  upCamTrans:ClearData()
  local rbtJ1, rbtJ2, _, rbtJ4 = getRobotCurPos()
  local centerX, centerY, _ = dgrToXY(rbtJ1, rbtJ2, rbtJ4, scaraTrans)
  local imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep2")
  local upCamCenterRbtPos = TwoDimPos.new()
  if not passed then goto funcRet end
  --先简易做个表 来让下相机标记来对准相机中心
  tRet = upCamMapping(centerX, centerY, 3, 3, localParam["upCamStepLength"])
  if not tRet then goto funcRet end
  upCamCenterRbtPos = upCamTrans:FromTargetToSource(upCamCenter)
  tRet = upCamMapping(upCamCenterRbtPos._tfPos._fX , upCamCenterRbtPos._tfPos._fY,
                  localParam["upCamStepX"], localParam["upCamStepY"], 
                  localParam["upCamStepLength"])

  ::funcRet::
  if tRet then
    lastRunRetStr = "CaliStep 2 done!"
  else
    lastRunRetStr = "Calistep 2 failed"
  end
  return tRet
end

function upCamMapping(centerX, centerY, stepCountX, stepCountY, stepLengh)
  Log("upCamMapping Start")
  local tRet = false
  local upCamTrans = curStation:GetTransByName("robotMotionToUpCam")
  local scaraTrans = curStation:GetTransByName("scara")
  upCamTrans:ClearData()
  
  for stepX = 0, stepCountX - 1 do 
    for stepY = 0, stepCountY - 1 do
      if NeedStop() then goto funcRet end
      local posToMoveX = centerX + (stepX - (stepCountX - 1) / 2) * stepLengh
      local posToMoveY = centerY + (stepY - (stepCountY - 1) / 2) * stepLengh
      scaraTrans:SetMethod(1)
      local dgr1, dgr2, dgr4 = xyToDgr(posToMoveX, posToMoveY, 0, scaraTrans)

      if not moveRobot(dgr1, dgr2, 0) then goto funcRet end
      local imgX, imgY, imgA, passed = getVisionSingleResult("scaraCaliStep2")
      if not passed then goto funcRet end
      if not moveRobotSimple(dgr1, dgr2, 180) then goto funcRet end
      Sleep(300)
      local imgX2, imgY2, imgA2, passed2 = getVisionSingleResult("scaraCaliStep2")
      local posInMotion = TwoDimPos.new() local posInCam = TwoDimPos.new()
      posInMotion._tfPos._fX = posToMoveX 
      posInMotion._tfPos._fY = posToMoveY
      posInCam._tfPos._fX = (imgX + imgX2) / 2 
      posInCam._tfPos._fY = (imgY + imgY2) / 2

      upCamTrans:SetOnePairData(posInMotion, posInCam)
    end
  end
  tRet = true
  ::funcRet::
  if tRet then 
    Log("upCamMapping successed")
    upCamTrans:Save()
  else 
    Log("upCamMapping failed")
  end
  return tRet
end