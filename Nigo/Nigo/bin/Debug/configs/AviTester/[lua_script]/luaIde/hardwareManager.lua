---@class HardwareManager
local HardwareManager = {}

---@return DigitalOutput
function HardwareManager:get_digital_output(str_name) end

---@return DigitalInput
function HardwareManager:get_digital_input(str_name) end

---@return Cylinder
function HardwareManager:get_cylinder(str_name) end

---@return Beacon
function HardwareManager:get_beacon(str_name) end

---@return Axis
function HardwareManager:get_axis(str_name) end

---@return ZUUnion
function HardwareManager:get_zu_union(str_name) end

---@return WorkHead
function HardwareManager:get_work_head(str_name) end

---@return XyzuPlatform
function HardwareManager:get_xyzu_platform(str_name) end

---@return SimpleSynComm
function HardwareManager:get_simple_syn_comm(str_name) end

---@type HardwareManager
selfHardwareManager = {}