----------------------------- serial_comm api -----------------------------------
---@class SimpleSynComm
local SimpleSynComm = {}

---@return string
---@return number
function SimpleSynComm:read() end

---@param str_data string
---@return boolean
function SimpleSynComm:wirte(str_data) end

---@param str_data string
---@return number
function SimpleSynComm:write_with_wait(str_data) end

---@param str_data string
---@return string
function SimpleSynComm:write_and_read(str_data) end

---@param i_ticks number
---@return boolean
function SimpleSynComm:try_occupy_within_ticks(i_ticks) end

---@return boolean
function SimpleSynComm:try_occupy() end

---@return void
function SimpleSynComm:occupy() end

---@return void
function SimpleSynComm:release_ctrl() end

---@type SimpleSynComm
selfSimpleSynComm = {}