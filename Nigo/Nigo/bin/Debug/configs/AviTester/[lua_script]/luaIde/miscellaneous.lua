---@class CmdAgent
local CmdAgent = {}

---@param str_cmdType string
---@param str_cmdArgs string
---@return string
function CmdAgent:execute_special_cmd(str_cmdType, str_cmdArgs) end

---@type CmdAgent
selfCmdAgent = {}