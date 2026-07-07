/*
 * @Author: TQ-V85Sn 
 * @Date: 2023-01-23 21:57:35 
 * @Last Modified by: TQ-V85Sn
 * @Last Modified time: 2023-01-23 22:00:25
 */

`timescale 1ns/1ns

// 简易的通用测试平台
 
module tb_reset();

	reg sys_clk, rst_n;

    wire  rst_n_out_0;
    wire  rst_n_out_1;
    wire  rst_n_out_2;
    wire  rst_n_out_3;
    wire  rst_n_out_4;

	initial begin
		sys_clk = 1;
		rst_n <= 1;
		#20
		rst_n <= 0;
		#20
		rst_n <= 1;

		#101
		rst_n <= 0;
		#7
		rst_n <= 1;

	end

	always #5 sys_clk = ~sys_clk;

	//---------------------reset_control_inst----------------------
	reset_control #(
		.OUTPUT_WIDTH		(8'd5),
		.RESET_HOLD_CYCLE	(8'd2)
	)reset_control_inst(
		.sys_clk (sys_clk),
		.rst_n (rst_n),
		.rst_n_out_0 (rst_n_out_0),
		.rst_n_out_1 (rst_n_out_1),
		.rst_n_out_2 (rst_n_out_2),
		.rst_n_out_3 (rst_n_out_3),
		.rst_n_out_4 (rst_n_out_4)
	);

endmodule