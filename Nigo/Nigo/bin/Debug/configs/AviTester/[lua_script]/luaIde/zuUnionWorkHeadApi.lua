------------------------------------z_u_union_Api--------------------------------------------

---@class ZUUnion
local ZUUnion = {}

--return bool
function ZUUnion:have_z() end

--return bool
function ZUUnion:have_u() end

--@return [luaIde.axisApi#axis]
function ZUUnion:get_z_axis() end

--@return [luaIde.axisApi#axis]
function ZUUnion:get_u_axis() end

function ZUUnion:set_z_safe_pos(f_pos, b_isPosDir) end

function ZUUnion:set_z_normal_pos(f_pos) end

function ZUUnion:set_u_normal_pos(f_pos) end

function ZUUnion:z_2_normal() end

--return bool
function ZUUnion:wait_z_normal() end

--return bool
function ZUUnion:wait_z_safe() end

--return bool
function ZUUnion:z_2_normal_with_wait() end

--return float
function ZUUnion:get_z_normal_pos() end

--return float
function ZUUnion:get_z_safe_pos() end

function ZUUnion:z_2_pos(f_pos) end

--return bool
function ZUUnion:z_2_pos_with_wait(f_pos) end

--return bool
function ZUUnion:is_z_in_safe() end

--return bool
function ZUUnion:chk_or_wait_z_safe() end

function ZUUnion:u_2_normal() end

--return bool
function ZUUnion:u_2_normal_with_wait() end

--return bool
function ZUUnion:wait_u_normal() end

--return float
function ZUUnion:get_u_normal_pos() end

function ZUUnion:u_2_pos(f_pos) end

--return bool
function ZUUnion:u_2_pos_with_wait(f_pos) end

--return float
function ZUUnion:get_z_pos() end

--return float
function ZUUnion:get_u_pos() end



----------------------------------------work_head_Api-----------------------------------
---@class WorkHead
local WorkHead = {}

--return bool
function WorkHead:have_z() end

--return bool
function WorkHead:have_u() end

--return bool
function WorkHead:have_clyd() end

--return bool
function WorkHead:have_vacuum_meter() end

--@return [luaIde.zuUnionWorkHeadApi#z_u_union]
function WorkHead:get_z_u() end

--@return [luaIde.ioEquipmentApi#cylinder]
function WorkHead:get_up_down_cyld() end

--return bool
function WorkHead:is_head_homed() end

function WorkHead:to_safe() end

--return bool
function WorkHead:wait_safe() end

--return bool
function WorkHead:chk_or_wait_safe() end

--return bool
function WorkHead:to_safe_with_wait() end

--return bool
function WorkHead:is_safe_4_xy_move() end

function WorkHead:all_2_normal() end

--return bool
function WorkHead:all_wait_normal() end

--return bool
function WorkHead:all_2_normal_with_wait() end

function WorkHead:vacuum_open() end

function WorkHead:vacuum_open_with_delay() end

--return bool
function WorkHead:vacuum_open_with_meter_chk(i_overTimeTicks) end

function WorkHead:vacuum_close() end

function WorkHead:vacuum_break() end

function WorkHead:vacuum_break_with_delay_and_close() end

function WorkHead:vacuum_break_close() end

--return bool
function WorkHead:is_vacuum_meter_on() end