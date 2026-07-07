/*
 * @Author: TQ-V85Sn 
 * @Date: 2023-01-23 21:17:49 
 * @Last Modified by: TQ-V85Sn
 * @Last Modified time: 2023-01-23 22:41:59
 */

// 异步复位同步释放控制器(输入输出均为低有效)

module reset_control #(
	parameter	OUTPUT_WIDTH	 = 3,
	parameter	RESET_HOLD_CYCLE = 2
) (
	input	wire	sys_clk,
	input	wire	rst_n,
	
    output	wire  rst_n_out_0,
    output	wire  rst_n_out_1,
    output	wire  rst_n_out_2,
    output	wire  rst_n_out_3,
    output	wire  rst_n_out_4,
    output	wire  rst_n_out_5,
    output	wire  rst_n_out_6,
    output	wire  rst_n_out_7,
    output	wire  rst_n_out_8,
    output	wire  rst_n_out_9,
    output	wire  rst_n_out_10,
    output	wire  rst_n_out_11,
    output	wire  rst_n_out_12,
    output	wire  rst_n_out_13,
    output	wire  rst_n_out_14,
    output	wire  rst_n_out_15,
    output	wire  rst_n_out_16,
    output	wire  rst_n_out_17,
    output	wire  rst_n_out_18,
    output	wire  rst_n_out_19,
    output	wire  rst_n_out_20,
    output	wire  rst_n_out_21,
    output	wire  rst_n_out_22,
    output	wire  rst_n_out_23,
    output	wire  rst_n_out_24,
    output	wire  rst_n_out_25,
    output	wire  rst_n_out_26,
    output	wire  rst_n_out_27,
    output	wire  rst_n_out_28,
    output	wire  rst_n_out_29,
    output	wire  rst_n_out_30,
    output	wire  rst_n_out_31,
    output	wire  rst_n_out_32,
    output	wire  rst_n_out_33,
    output	wire  rst_n_out_34,
    output	wire  rst_n_out_35,
    output	wire  rst_n_out_36,
    output	wire  rst_n_out_37,
    output	wire  rst_n_out_38,
    output	wire  rst_n_out_39,
    output	wire  rst_n_out_40,
    output	wire  rst_n_out_41,
    output	wire  rst_n_out_42,
    output	wire  rst_n_out_43,
    output	wire  rst_n_out_44,
    output	wire  rst_n_out_45,
    output	wire  rst_n_out_46,
    output	wire  rst_n_out_47,
    output	wire  rst_n_out_48,
    output	wire  rst_n_out_49,
    output	wire  rst_n_out_50,
    output	wire  rst_n_out_51,
    output	wire  rst_n_out_52,
    output	wire  rst_n_out_53,
    output	wire  rst_n_out_54,
    output	wire  rst_n_out_55,
    output	wire  rst_n_out_56,
    output	wire  rst_n_out_57,
    output	wire  rst_n_out_58,
    output	wire  rst_n_out_59,
    output	wire  rst_n_out_60,
    output	wire  rst_n_out_61,
    output	wire  rst_n_out_62,
    output	wire  rst_n_out_63
);
	(* keep = "true" *)
	reg [63 : 0] rst_n_out = 64'hFFFF_FFFF_FFFF_FFFF;
	//3个DFF作同步释放，故复位信号至少持续2个时钟周期，最高位输出
	reg [RESET_HOLD_CYCLE - 1 : 0] rst_buf = (1 << RESET_HOLD_CYCLE) - 1;

	always @(posedge sys_clk or negedge rst_n) begin
		if(rst_n == 0)
			rst_buf <= 0;
		else begin
			if(RESET_HOLD_CYCLE == 1)
				rst_buf <= 1'b1;	
			else 
				rst_buf <= {rst_buf[RESET_HOLD_CYCLE - 2 : 0], 1'b1};	
		end
	end
	
//	integer i;
//	always @(posedge sys_clk or negedge rst_n) begin
//		for (i = 0; i < 64; i = i + 1) begin
//			if(rst_n == 0)
//				rst_n_out[i] <= 0;
//			else 
//				rst_n_out[i] <= rst_buf[RESET_HOLD_CYCLE - 1];
//		end
//	end
	
	genvar i;
	generate
		for (i = 0; i < OUTPUT_WIDTH; i = i + 1) begin
			always @(posedge sys_clk or negedge rst_n) begin
				if(rst_n == 0)
					rst_n_out[i] <= 0;
				else 
					rst_n_out[i] <= rst_buf[RESET_HOLD_CYCLE - 1];
			end
		end
	endgenerate

	
    assign rst_n_out_0 = rst_n_out[0];
    assign rst_n_out_1 = rst_n_out[1];
    assign rst_n_out_2 = rst_n_out[2];
    assign rst_n_out_3 = rst_n_out[3];
    assign rst_n_out_4 = rst_n_out[4];
    assign rst_n_out_5 = rst_n_out[5];
    assign rst_n_out_6 = rst_n_out[6];
    assign rst_n_out_7 = rst_n_out[7];
    assign rst_n_out_8 = rst_n_out[8];
    assign rst_n_out_9 = rst_n_out[9];
    assign rst_n_out_10 = rst_n_out[10];
    assign rst_n_out_11 = rst_n_out[11];
    assign rst_n_out_12 = rst_n_out[12];
    assign rst_n_out_13 = rst_n_out[13];
    assign rst_n_out_14 = rst_n_out[14];
    assign rst_n_out_15 = rst_n_out[15];
    assign rst_n_out_16 = rst_n_out[16];
    assign rst_n_out_17 = rst_n_out[17];
    assign rst_n_out_18 = rst_n_out[18];
    assign rst_n_out_19 = rst_n_out[19];
    assign rst_n_out_20 = rst_n_out[20];
    assign rst_n_out_21 = rst_n_out[21];
    assign rst_n_out_22 = rst_n_out[22];
    assign rst_n_out_23 = rst_n_out[23];
    assign rst_n_out_24 = rst_n_out[24];
    assign rst_n_out_25 = rst_n_out[25];
    assign rst_n_out_26 = rst_n_out[26];
    assign rst_n_out_27 = rst_n_out[27];
    assign rst_n_out_28 = rst_n_out[28];
    assign rst_n_out_29 = rst_n_out[29];
    assign rst_n_out_30 = rst_n_out[30];
    assign rst_n_out_31 = rst_n_out[31];
    assign rst_n_out_32 = rst_n_out[32];
    assign rst_n_out_33 = rst_n_out[33];
    assign rst_n_out_34 = rst_n_out[34];
    assign rst_n_out_35 = rst_n_out[35];
    assign rst_n_out_36 = rst_n_out[36];
    assign rst_n_out_37 = rst_n_out[37];
    assign rst_n_out_38 = rst_n_out[38];
    assign rst_n_out_39 = rst_n_out[39];
    assign rst_n_out_40 = rst_n_out[40];
    assign rst_n_out_41 = rst_n_out[41];
    assign rst_n_out_42 = rst_n_out[42];
    assign rst_n_out_43 = rst_n_out[43];
    assign rst_n_out_44 = rst_n_out[44];
    assign rst_n_out_45 = rst_n_out[45];
    assign rst_n_out_46 = rst_n_out[46];
    assign rst_n_out_47 = rst_n_out[47];
    assign rst_n_out_48 = rst_n_out[48];
    assign rst_n_out_49 = rst_n_out[49];
    assign rst_n_out_50 = rst_n_out[50];
    assign rst_n_out_51 = rst_n_out[51];
    assign rst_n_out_52 = rst_n_out[52];
    assign rst_n_out_53 = rst_n_out[53];
    assign rst_n_out_54 = rst_n_out[54];
    assign rst_n_out_55 = rst_n_out[55];
    assign rst_n_out_56 = rst_n_out[56];
    assign rst_n_out_57 = rst_n_out[57];
    assign rst_n_out_58 = rst_n_out[58];
    assign rst_n_out_59 = rst_n_out[59];
    assign rst_n_out_60 = rst_n_out[60];
    assign rst_n_out_61 = rst_n_out[61];
    assign rst_n_out_62 = rst_n_out[62];
    assign rst_n_out_63 = rst_n_out[63];


endmodule