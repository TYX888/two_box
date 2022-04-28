---@class xyzu_axis
local xyzu_axis = {
	x_axis = 0,
	y_axis = 1,
	z_axis = 2,
	u_axis = 3
}

---@class xyzu_platform_pos
local xyzu_platform_pos ={
    x_pos = 0.0, y_pos = 0.0, z_pos = 0.0, u_pos = 0.0
}

---@class XyzuPlatform
local XyzuPlatform = {}

--@return [luaIde.zuUnionWorkHeadApi#z_u_union]
function XyzuPlatform:get_platform_zu() end

--@return [luaIde.axisApi#axis]
function XyzuPlatform:get_axis(e_xyzu_axis) end

--@return [luaIde.zuUnionWorkHeadApi#work_head]
function XyzuPlatform:get_work_head(i_workHeadIndex) end

--return bool
function XyzuPlatform:have_z() end

--return bool
function XyzuPlatform:have_u() end

--return int
function XyzuPlatform:get_head_num() end

--return bool
function XyzuPlatform:home_all_axis() end

--return bool
function XyzuPlatform:is_platform_homed() end

function XyzuPlatform:set_cur_work_head(i_workHeadIndex) end

--return bool
function XyzuPlatform:work_head_2_normal_with_wait(i_workHeadIndex) end

--return bool
function XyzuPlatform:all_work_head_2_normal_with_wait() end

--return int
function XyzuPlatform:get_alarm_on_axis_index() end

--return int
function XyzuPlatform:get_motion_error_code() end

--return int
function XyzuPlatform:get_platform_status() end

function XyzuPlatform:close_all_output() end

--return bool
function XyzuPlatform:work_head_2_safe_with_wait(i_workHeadIndex) end

function XyzuPlatform:set_velocity_related_2_default() end

function XyzuPlatform:set_velocity_related_2_percent(f_percent) end

--return bool
function XyzuPlatform:all_work_head_2_safe_with_wait() end

--return float
function XyzuPlatform:get_z_normal_pos() end

--return float
function XyzuPlatform:get_z_safe_pos() end

--return bool
function XyzuPlatform:is_xyu_motion_safe() end

--return bool
function XyzuPlatform:is_xyu_stop() end

--return bool
function XyzuPlatform:wait_xyu_motion_safe() end

--return bool
function XyzuPlatform:wait_xyu_stop() end

--return bool
function XyzuPlatform:is_platform_stop() end

--return bool
function XyzuPlatform:wait_platform_stop() end

function XyzuPlatform:stop_axis(e_xyzu_axis) end

function XyzuPlatform:stop_all() end

--return float
function XyzuPlatform:get_u_normal_pos() end

--return bool
function XyzuPlatform:is_dest_xy_safe(f_xPos, f_yPos) end

--return bool
function XyzuPlatform:move_single(e_xyzu_axis, f_pos) end

--return bool
function XyzuPlatform:move_single_with_wait(e_xyzu_axis, f_pos) end

--return bool
function XyzuPlatform:move_single_z(i_headId, f_pos) end

--return bool
function XyzuPlatform:move_single_z_with_wait(i_headId, f_pos) end

--return bool
function XyzuPlatform:move_single_u(i_headId, f_pos) end

--return bool
function XyzuPlatform:move_single_u_with_wait(i_headId, f_pos) end

--return float
function XyzuPlatform:get_cur_head_single_pos(e_xyzu_axis) end

--return float
function XyzuPlatform:get_single_pos(i_headId, e_xyzu_axis) end

--@return [luaIde.xyzuPlatformApi#xyzu_platform_pos]
function XyzuPlatform:get_pos() end

--return int
function get_motion_method() end

function set_motion_method(i_method) end

--return bool
function XyzuPlatform:move_xy_without_wait(f_xPos, f_yPos) end

--return bool
function XyzuPlatform:move_xy_with_wait(f_xPos, f_yPos) end

--return bool
function XyzuPlatform:move_xyu_without_wait(f_xPos, f_yPos, f_uPos) end

--return bool
function XyzuPlatform:move_xyu_with_wait(f_xPos, f_yPos, f_uPos) end

--return bool
function XyzuPlatform:wait_z_safe_move_xyu_without_wait(f_xPos, f_yPos, f_uPos) end

--return bool
function XyzuPlatform:wait_xyu_arrived_pos(f_xPos, f_yPos, f_uPos, f_xTol, f_yTol, f_uTol) end

function XyzuPlatform:change_xyu_pos(f_xPos, f_yPos, f_uPos) end

--return bool
function XyzuPlatform:change_xyu_pos_with_wait(f_xPos, f_yPos, f_uPos) end

--return bool
function XyzuPlatform:move_2_pos_with_path_without_wait(xyzu_platform_pos_vec, str_extra_param_vec ) end

---@type xyzu_platform
selfXyzuPlatform = {}