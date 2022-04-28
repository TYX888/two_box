---@class TwoFloat
local TwoFloat = {
    ---@field number
    _fX = 0,
    ---@field number
    _fY = 1 
}

---@return TwoFloat
function TwoFloat.new() end

---@param x number
---@param y number
---@return TwoFloat
function TwoFloat.newCustom(x, y) end

---@class TwoDimPos
local TwoDimPos = {
    ---@field TwoFloat
    _tfPos = {
        _fX = 0,
        _fY = 1 
    },
    ---@field number
    _fAngle = 2,
}

---@return TwoDimPos
function TwoDimPos.new() end

---@param x number
---@param y number
---@param a number
---@return TwoDimPos
function TwoDimPos.newCustom(x, y, a) end

---@type MyMath
local MyMath = {}

---@param points TwoFloat[]
---@return TwoDimPos @x,y为位置 _fAngle复用为半径
function MyMath.FitCircle(points) end

---@param first TwoFloat
---@param sec TwoFloat
---@return number
function MyMath.Distance(first, sec) end

---@param points TwoFloat[]
---@return TwoFloat, TwoFloat @第一个为startPos 第二个为方向矢量
function MyMath.FitLine(points) end

---@param point TwoFloat
---@param lineStart TwoFloat
---@param lineDir TwoFloat
---@return number
function MyMath.DistanceBetweenPointAndLine(point, lineStart, lineDir) end

-----------------------------TwoDimCoordTrans Api--------------------------------
---@type TwoDimCoordTrans
local TwoDimCoordTrans = {}

---@param float_agl  number
---@return number
function TwoDimCoordTrans:AglFromSourceToTarget(float_agl) end

---@param float_agl number
---@return number
function TwoDimCoordTrans:AglFromTargetToSource(float_agl) end


 ---从trans的正方向求解坐标转换
---@param twoDimPos_pos TwoDimPos
---@return TwoDimPos
function TwoDimCoordTrans:FromSourceToTarget(twoDimPos_pos) end


---从trans的负方向求解坐标转换
---@param twoDimPos_pos TwoDimPos
---@return TwoDimPos
function TwoDimCoordTrans:FromTargetToSource(twoDimPos_pos) end

---@return boolean
function TwoDimCoordTrans:ClearData() end

---@param  twoDimPos_source TwoDimPos
---@param  twoDimPos_target TwoDimPos
---@return boolean
function TwoDimCoordTrans:SetOnePairData(twoDimPos_source, twoDimPos_target) end

---@param  f_param1 number
---@param  f_param2 number
---@param  f_param3 number
---@return boolean
function TwoDimCoordTrans:SetInnerParam(f_param1, f_param2, f_param3) end

---获取内参 可用于线性转换和 旋转转换的Trans
---@return  TwoDimPos
function TwoDimCoordTrans:GetInnerParamWithTDP() end

---@return boolean
function TwoDimCoordTrans:SetInnerParamWithStr(str_param) end

---@param  f_param1 number
---@param  f_param2 number
---@param  f_param3 number
---@return boolean
function TwoDimCoordTrans:SetInputParam(f_param1, f_param2, f_param3) end

---@param  i_method number
---@return boolean
function TwoDimCoordTrans:SetMethod(i_method) end

---@return  number
function TwoDimCoordTrans:GetMethod() end

---@return boolean
function TwoDimCoordTrans:Save() end

---@return boolean
function TwoDimCoordTrans:Load() end

---@return boolean
function TwoDimCoordTrans:SetName(str_name) end

---@return boolean
function TwoDimCoordTrans:SetStationName(str_stationName) end

---@return  string
function TwoDimCoordTrans:GetStationName() end

---@return  string
function TwoDimCoordTrans:GetName() end

---@return  number @ (enum: TransformType)
function TwoDimCoordTrans:GetType() end

---@return  number
function TwoDimCoordTrans:GetMaxErrorEstimation() end

---@return  number
function TwoDimCoordTrans:GetAverageErrorEstimation() end

---------------------------StationCoordSys Api-------------------------------------
---@class StationCoordSys
local StationCoordSys = {}

---@return string
function StationCoordSys:GetName() end

---@return boolean
function StationCoordSys:Init() end

---@return boolean
function StationCoordSys:Save() end

---@param str_transName string
---@param transType_type number @enum transtype
---@return boolean
function StationCoordSys:CreateTrans(str_transName, transType_type) end

---@return boolean
function StationCoordSys:ClearAllTrans() end


---从station coordinate system 里 按名字获取一个trans
---@param str_transName string
---@return TwoDimCoordTrans
function StationCoordSys:GetTransByName(str_transName) end

---运行一个solver 按顺序运行一个solver内的所有trans 获得结果
---@param twoDimPos_inputPos TwoDimPos
---@return  TwoDimPos
function StationCoordSys:RunSolver(twoDimPos_inputPos) end

---@return boolean
function StationCoordSys:CreateSolverInfo(str_solverName) end

---@return boolean
function StationCoordSys:InsertTransInfoInSolverInfo(str_transName,str_solverName,bool_dir) end


--------------------------RobotCoordSys Api--------------------------------------------
---@class RobotCoordSys
local RobotCoordSys = {}

---重新读配置文件 入参简易使用空字串  这样能使用默认的地址来储存配置文件
---@param str_appPath string
---@return boolean
function RobotCoordSys:Init(str_appPath) end

---@return boolean
function RobotCoordSys:Save() end

---@return boolean
function RobotCoordSys:ClearAllStationAndInfo() end

---@return boolean
function RobotCoordSys:CreateStation(str_stationName) end

---@return boolean
function RobotCoordSys:ClearStation(str_stationName) end


---按名字索引station coordinate system
---@param str_stationName string
---@return StationCoordSys
function RobotCoordSys:GetStationCoordSys(str_stationName) end





---每个node的lua环境里的 全局变量
---@type RobotCoordSys
selfRobotCoordSys = {}

function ExecutCmd(str_cmdType,str_jsonParam) end