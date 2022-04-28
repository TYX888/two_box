local homeMode = {
	abs = 0,
	lmt = 1,
	ref = 2,
	abs_ref = 3,
	abs_neg_ref = 4,
	lmt_ref = 5,
	abs_search = 6,
	lmt_search = 7,
	abs_search_ref = 8,
	abs_search_neg_ref = 9,
	lmt_search_ref = 10,
	abs_search_refind = 11,
	lmt_search_refind = 12,
	abs_search_refind_ref = 13,
	abs_search_refind_neg_ref = 14,
	lmt_search_refind_ref = 15
}

local axisStatus = {
	disable = 0,
	ready = 1,
	stop = 2,
	error_stop = 3,
	homing = 4,
	ptp_motion = 5,
	continue_motion = 6,
	syn_motion = 7,
	user_difined_1 = 8,
	user_difined_2 = 9,
	user_difined_3 = 10,
	user_difined_4 = 11,
	user_difined_5 = 12,
	user_difined_6 = 13,
	user_difined_7 = 14,
	user_difined_8 = 15
}

local pathCmd = {
	end_path = 0,
	abs_2d_line = 1,
	rel_2d_line = 2,
	abs_2d_arc_cw = 3,
	abs_2d_arc_ccw = 4,
	rel_2d_arc_cw = 5,
	rel_2d_arc_ccw = 6,
	abs_3d_line = 7,
	rel_3d_line = 8,
	abs_multi_line = 9,
	rel_multi_line = 10,
	abs_2d_direct = 11,
	rel_2d_direct = 12,
	abs_3d_direct = 13,
	rel_3d_direct = 14,
	abs_4d_direct = 15,
	rel_4d_direct = 16,
	abs_5d_direct = 17,
	rel_5d_direct = 18,
	abs_6d_direct = 19,
	rel_6d_direct = 20,
	abs_3d_arc_cw = 21,
	rel_3d_arc_cw = 22,
	abs_3d_arc_ccw = 23,
	rel_3d_arc_ccw = 24,
	abs_3d_helix_cw = 25,
	rel_3d_helix_cw = 26,
	abs_3d_helix_ccw = 27,
	rel_3d_helix_ccw = 28,
	gp_delay = 29 
}

local axisSpecialInput = {
	ready = 0,
	alarm = 1,
	pos_limt = 2,
	neg_limt = 3,
	origion = 4,
	dir = 5,
	emg_input = 6,
	pcs = 7, --不详
	erc = 8, --保留
	ez = 9, --Z信号
	clr = 10, --外部输入 清除计数器  不支持
	ltc = 11, --锁存信号输入
	sd = 12, --不支持
	inpos = 13, --到位信号
	servo_on = 14,
	reset_alarm = 15,
	soft_pos_limit = 16,
	soft_neg_limit = 17,
	compara = 18,
	camd0 = 19 --凸轮区间D0
};

---@class  Axis
local Axis = {}

---@return  number @enum.axisStatus
function Axis:get_axis_status() end

---@return void
function Axis:try_reset_error() end

---@return  number
function Axis:get_axis_error_code() end

---@param b_isEnable boolean
---@param b_isPosLimt boolean
---@return  void
function Axis:set_limit_enable_status(b_isPosLimt, b_isEnable) end

function Axis:set_limit(f_limtPos, b_isPosLimit) end

function Axis:set_servo_on_status(b_isOn) end

--return bool
function Axis:is_pos_limit_on() end

--return bool
function Axis:is_neg_limit_on() end

--return bool
function Axis:is_origin_ref_on() end

--return bool
function Axis:get_special_input(e_axisSpecialInput) end

function Axis:stop() end

function Axis:emg_stop() end

--return bool
function Axis:try_stop() end

function Axis:start_axis_home() end

function Axis:start_axis_home_default_mode() end

--return bool
function Axis:wait_axis_home_finished() end

--return bool
function Axis:is_finished_home() end

function Axis:reset_finished_flag() end

function Axis:set_velocity_related_2_default() end

function Axis:set_velocity_percent_of_default(f_percent) end

function Axis:set_velocity_mode(b_useJerk) end

function Axis:set_abs_max_accel(f_acc) end

function Axis:set_abs_max_decel(f_dec) end

function Axis:set_abs_max_speed(f_speed) end

function Axis:set_abs_start_speed(f_speed) end

function Axis:set_home_speed_param(f_speed) end

function Axis:set_decel_percent(f_percent) end

function Axis:set_accel_percent(f_percent) end

function Axis:set_speed_percent(f_percent) end

---@return number
function Axis:get_abs_accel() end

--return float
function Axis:get_abs_decel() end

--return float
function Axis:get_abs_speed() end

--return float
function Axis:get_abs_start_speed() end

function Axis:abs_move_without_wait(f_destPos) end

--return bool
function Axis:abs_move_with_wait(f_destPos) end

--return bool
function Axis:rel_move_with_wait(f_dist) end

function Axis:rel_move_without_wait(f_dist) end

function Axis:start_velocity_move(b_isPosDir) end

function Axis:change_pos(f_destPos) end

--return bool
function Axis:wait_stop() end

--return bool
function Axis:wait_arrived_pos(f_dstPos, f_tolerance) end

--return bool
function Axis:wait_go_through_pos(f_destPos, b_isPlusDir) end

function Axis:reset_cmd_pos(f_cmdPos) end

--return float
function Axis:get_cmd_pos() end

function Axis:reset_act_pos(f_actPos) end

--return float
function Axis:get_act_pos() end

--return bool
function Axis:is_stop() end

function Axis:reset_all_pos_to_zero() end

--return bool
function Axis:set_current_axis_param(str_jsonParam) end

--return bool
function Axis:save_current_axis_param() end

return Axis

---@type Axis
selfAxis = {}