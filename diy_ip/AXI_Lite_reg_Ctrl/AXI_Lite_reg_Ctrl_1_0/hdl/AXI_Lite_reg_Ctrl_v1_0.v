
`timescale 1 ns / 1 ps

	module AXI_Lite_reg_Ctrl_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI_RegCtrl
		parameter integer C_S_AXI_RegCtrl_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_RegCtrl_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg0_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg1_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg2_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg3_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg4_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg5_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg6_in,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg7_in,
		
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg0_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg1_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg2_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg3_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg4_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg5_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg6_out,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] reg7_out,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI_RegCtrl
		input wire  s_axi_regctrl_aclk,
		input wire  s_axi_regctrl_aresetn,
		input wire [C_S_AXI_RegCtrl_ADDR_WIDTH-1 : 0] s_axi_regctrl_awaddr,
		input wire [2 : 0] s_axi_regctrl_awprot,
		input wire  s_axi_regctrl_awvalid,
		output wire  s_axi_regctrl_awready,
		input wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] s_axi_regctrl_wdata,
		input wire [(C_S_AXI_RegCtrl_DATA_WIDTH/8)-1 : 0] s_axi_regctrl_wstrb,
		input wire  s_axi_regctrl_wvalid,
		output wire  s_axi_regctrl_wready,
		output wire [1 : 0] s_axi_regctrl_bresp,
		output wire  s_axi_regctrl_bvalid,
		input wire  s_axi_regctrl_bready,
		input wire [C_S_AXI_RegCtrl_ADDR_WIDTH-1 : 0] s_axi_regctrl_araddr,
		input wire [2 : 0] s_axi_regctrl_arprot,
		input wire  s_axi_regctrl_arvalid,
		output wire  s_axi_regctrl_arready,
		output wire [C_S_AXI_RegCtrl_DATA_WIDTH-1 : 0] s_axi_regctrl_rdata,
		output wire [1 : 0] s_axi_regctrl_rresp,
		output wire  s_axi_regctrl_rvalid,
		input wire  s_axi_regctrl_rready
	);
// Instantiation of Axi Bus Interface S_AXI_RegCtrl
	AXI_Lite_reg_Ctrl_v1_0_S_AXI_RegCtrl # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_RegCtrl_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_RegCtrl_ADDR_WIDTH)
	) AXI_Lite_reg_Ctrl_v1_0_S_AXI_RegCtrl_inst (
		.reg0_in(reg0_in),
		.reg1_in(reg1_in),
		.reg2_in(reg2_in),
		.reg3_in(reg3_in),
		.reg4_in(reg4_in),
		.reg5_in(reg5_in),
		.reg6_in(reg6_in),
		.reg7_in(reg7_in),

		.reg0_out(reg0_out),
		.reg1_out(reg1_out),
		.reg2_out(reg2_out),
		.reg3_out(reg3_out),
		.reg4_out(reg4_out),
		.reg5_out(reg5_out),
		.reg6_out(reg6_out),
		.reg7_out(reg7_out),
		
		.S_AXI_ACLK(s_axi_regctrl_aclk),
		.S_AXI_ARESETN(s_axi_regctrl_aresetn),
		.S_AXI_AWADDR(s_axi_regctrl_awaddr),
		.S_AXI_AWPROT(s_axi_regctrl_awprot),
		.S_AXI_AWVALID(s_axi_regctrl_awvalid),
		.S_AXI_AWREADY(s_axi_regctrl_awready),
		.S_AXI_WDATA(s_axi_regctrl_wdata),
		.S_AXI_WSTRB(s_axi_regctrl_wstrb),
		.S_AXI_WVALID(s_axi_regctrl_wvalid),
		.S_AXI_WREADY(s_axi_regctrl_wready),
		.S_AXI_BRESP(s_axi_regctrl_bresp),
		.S_AXI_BVALID(s_axi_regctrl_bvalid),
		.S_AXI_BREADY(s_axi_regctrl_bready),
		.S_AXI_ARADDR(s_axi_regctrl_araddr),
		.S_AXI_ARPROT(s_axi_regctrl_arprot),
		.S_AXI_ARVALID(s_axi_regctrl_arvalid),
		.S_AXI_ARREADY(s_axi_regctrl_arready),
		.S_AXI_RDATA(s_axi_regctrl_rdata),
		.S_AXI_RRESP(s_axi_regctrl_rresp),
		.S_AXI_RVALID(s_axi_regctrl_rvalid),
		.S_AXI_RREADY(s_axi_regctrl_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
