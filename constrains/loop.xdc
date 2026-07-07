set_property PACKAGE_PIN H16        [get_ports SYSCLK]
set_property IOSTANDARD LVCMOS33    [get_ports SYSCLK] 

set_property IOSTANDARD LVCMOS33    [get_ports rst_n]
set_property PACKAGE_PIN F19        [get_ports rst_n]
set_property PULLTYPE PULLUP        [get_ports rst_n]

# DAC2
set_property IOSTANDARD LVCMOS33    [get_ports {dac2_data[*]}   ]
set_property DRIVE 16               [get_ports {dac2_data[*]}   ]
set_property SLEW FAST              [get_ports {dac2_data[*]}   ]
set_property PACKAGE_PIN V12        [get_ports {dac2_data[13]}  ]
set_property PACKAGE_PIN W14        [get_ports {dac2_data[12]}  ]
set_property PACKAGE_PIN W13        [get_ports {dac2_data[11]}  ]
set_property PACKAGE_PIN Y16        [get_ports {dac2_data[10]}  ]
set_property PACKAGE_PIN N15        [get_ports {dac2_data[9]}   ]
set_property PACKAGE_PIN Y17        [get_ports {dac2_data[8]}   ]
set_property PACKAGE_PIN N16        [get_ports {dac2_data[7]}   ]
set_property PACKAGE_PIN P18        [get_ports {dac2_data[6]}   ]
set_property PACKAGE_PIN R16        [get_ports {dac2_data[5]}   ]
set_property PACKAGE_PIN N17        [get_ports {dac2_data[4]}   ]
set_property PACKAGE_PIN R17        [get_ports {dac2_data[3]}   ]
set_property PACKAGE_PIN U14        [get_ports {dac2_data[2]}   ]
set_property PACKAGE_PIN P19        [get_ports {dac2_data[1]}   ]
set_property PACKAGE_PIN U15        [get_ports {dac2_data[0]}   ]

# set_property SLEW FAST              [get_ports {SAMPLE_PIN}   ]
# set_property PACKAGE_PIN D18        [get_ports SAMPLE_PIN] #IO35_3_N
#IO35_6_P
set_property PACKAGE_PIN F16        [get_ports SAMPLE_PIN]  
set_property IOSTANDARD LVCMOS33    [get_ports SAMPLE_PIN]

set_property IOSTANDARD LVCMOS33    [get_ports {adc_a_data[*]}]
set_property PACKAGE_PIN K19        [get_ports {adc_a_data[0]}]
set_property PACKAGE_PIN J19        [get_ports {adc_a_data[1]}]
set_property PACKAGE_PIN J18        [get_ports {adc_a_data[2]}]
set_property PACKAGE_PIN H18        [get_ports {adc_a_data[3]}]
set_property PACKAGE_PIN M14        [get_ports {adc_a_data[4]}]
set_property PACKAGE_PIN M15        [get_ports {adc_a_data[5]}]
set_property PACKAGE_PIN L15        [get_ports {adc_a_data[6]}]
set_property PACKAGE_PIN L14        [get_ports {adc_a_data[7]}]
set_property PACKAGE_PIN L20        [get_ports {adc_a_data[8]}]
set_property PACKAGE_PIN L19        [get_ports {adc_a_data[9]}]
set_property PACKAGE_PIN M20        [get_ports {adc_a_data[10]}]
set_property PACKAGE_PIN M19        [get_ports {adc_a_data[11]}]
set_property PACKAGE_PIN N20        [get_ports {adc_a_data[12]}]
set_property PACKAGE_PIN P20        [get_ports {adc_a_data[13]}]
set_property PACKAGE_PIN T20        [get_ports {adc_a_data[14]}]
set_property PACKAGE_PIN U20        [get_ports {adc_a_data[15]}]

# set_property LOC BUFGCTRL_X0Y79     [get_cells adc_a_data_IBUF[0]_BUFG_inst]
set_property IOSTANDARD LVCMOS33    [get_ports adc_a_clock]
set_property PACKAGE_PIN L16        [get_ports adc_a_clock]

# set_property SLEW FAST              [get_ports {BIT_OUT}  ]
# set_property PACKAGE_PIN H15        [get_ports BIT_OUT] # IO35_19_P
# IO_35_17N
set_property PACKAGE_PIN H20        [get_ports BIT_OUT] 
set_property IOSTANDARD LVCMOS33    [get_ports BIT_OUT] 

