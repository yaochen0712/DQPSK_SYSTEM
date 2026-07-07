# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "COUNT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DIVIDE_RATE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PULSE_DELAY" -parent ${Page_0}


}

proc update_PARAM_VALUE.COUNT_WIDTH { PARAM_VALUE.COUNT_WIDTH } {
	# Procedure called to update COUNT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COUNT_WIDTH { PARAM_VALUE.COUNT_WIDTH } {
	# Procedure called to validate COUNT_WIDTH
	return true
}

proc update_PARAM_VALUE.DIVIDE_RATE { PARAM_VALUE.DIVIDE_RATE } {
	# Procedure called to update DIVIDE_RATE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIVIDE_RATE { PARAM_VALUE.DIVIDE_RATE } {
	# Procedure called to validate DIVIDE_RATE
	return true
}

proc update_PARAM_VALUE.PULSE_DELAY { PARAM_VALUE.PULSE_DELAY } {
	# Procedure called to update PULSE_DELAY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PULSE_DELAY { PARAM_VALUE.PULSE_DELAY } {
	# Procedure called to validate PULSE_DELAY
	return true
}


proc update_MODELPARAM_VALUE.DIVIDE_RATE { MODELPARAM_VALUE.DIVIDE_RATE PARAM_VALUE.DIVIDE_RATE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIVIDE_RATE}] ${MODELPARAM_VALUE.DIVIDE_RATE}
}

proc update_MODELPARAM_VALUE.PULSE_DELAY { MODELPARAM_VALUE.PULSE_DELAY PARAM_VALUE.PULSE_DELAY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PULSE_DELAY}] ${MODELPARAM_VALUE.PULSE_DELAY}
}

proc update_MODELPARAM_VALUE.COUNT_WIDTH { MODELPARAM_VALUE.COUNT_WIDTH PARAM_VALUE.COUNT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COUNT_WIDTH}] ${MODELPARAM_VALUE.COUNT_WIDTH}
}

