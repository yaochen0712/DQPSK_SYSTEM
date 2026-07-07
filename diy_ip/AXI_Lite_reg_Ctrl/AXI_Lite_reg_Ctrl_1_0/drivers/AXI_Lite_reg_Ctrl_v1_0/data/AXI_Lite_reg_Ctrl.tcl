

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "AXI_Lite_reg_Ctrl" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_RegCtrl_BASEADDR" "C_S_AXI_RegCtrl_HIGHADDR"
}
