# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set OUTPUT_WIDTH [ipgui::add_param $IPINST -name "OUTPUT_WIDTH" -parent ${Page_0}]
  set_property tooltip {输出的复位信号数量，每一位输出都是相同的。每多加一位输出就多使用一个D触发器作输出，从而避免单个复位信号的扇出过多。} ${OUTPUT_WIDTH}
  set RESET_HOLD_CYCLE [ipgui::add_param $IPINST -name "RESET_HOLD_CYCLE" -parent ${Page_0}]
  set_property tooltip {复位信号保持周期数，至少为1} ${RESET_HOLD_CYCLE}


}

proc update_PARAM_VALUE.OUTPUT_WIDTH { PARAM_VALUE.OUTPUT_WIDTH } {
	# Procedure called to update OUTPUT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUTPUT_WIDTH { PARAM_VALUE.OUTPUT_WIDTH } {
	# Procedure called to validate OUTPUT_WIDTH
	return true
}

proc update_PARAM_VALUE.RESET_HOLD_CYCLE { PARAM_VALUE.RESET_HOLD_CYCLE } {
	# Procedure called to update RESET_HOLD_CYCLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_HOLD_CYCLE { PARAM_VALUE.RESET_HOLD_CYCLE } {
	# Procedure called to validate RESET_HOLD_CYCLE
	return true
}


proc update_MODELPARAM_VALUE.OUTPUT_WIDTH { MODELPARAM_VALUE.OUTPUT_WIDTH PARAM_VALUE.OUTPUT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUTPUT_WIDTH}] ${MODELPARAM_VALUE.OUTPUT_WIDTH}
}

proc update_MODELPARAM_VALUE.RESET_HOLD_CYCLE { MODELPARAM_VALUE.RESET_HOLD_CYCLE PARAM_VALUE.RESET_HOLD_CYCLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_HOLD_CYCLE}] ${MODELPARAM_VALUE.RESET_HOLD_CYCLE}
}

