-------------------------------digital_input api--------------------------
---@class DigitalInput
local DigitalInput = {}

--return bool
function DigitalInput:get_status() end

--return bool
function DigitalInput:get_status_without_buffer() end

---@type DigitalInput
selfDigitalInput = {}

-------------------------------digital_output api--------------------------
---@class DigitalOutput
local DigitalOutput = {}

--return bool
function DigitalOutput:get_status() end

function DigitalOutput:turn_on() end

function DigitalOutput:turn_off() end

function DigitalOutput:set_status(b_isON) end

function DigitalOutput:switch_status() end

---@type DigitalOutput
selfDigitalOutput = {}

-------------------------------cylinder api---------------------------
---@class cylinder_status
local cylinder_status = {
	extended = 1,
	retracted = -1,
	unknow = 0
}

---@class Cylinder
local Cylinder = {}

--return enum cylinder_status
function Cylinder:get_status() end

function Cylinder:set_status(e_cylinder_status) end

--return bool
function Cylinder:wait_status(e_cylinder_status) end

--return bool
function Cylinder:set_status_with_wait(e_cylinder_status) end

--return bool
function Cylinder:is_extended() end

--return bool
function Cylinder:is_retracted() end

---@type Cylinder
selfCylinder = {}

--------------------------------beacon api-------------------------
---@class Beacon
local Beacon = {}

--return bool
function Beacon:start_work() end

--return bool
function Beacon:stop_work() end

function Beacon:set_red_light_status(i_status) end

function Beacon:set_yellow_light_status(i_status) end

function Beacon:set_green_light_status(i_status) end

function Beacon:set_alarm_status(i_status) end

---@type Beacon
selfBeacon = {}