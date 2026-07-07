`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/28 21:22:07
// Design Name: 
// Module Name: verilog_delay
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module verilog_delay
#(
parameter DELAY_CYCLE = 32
)
(
    input clk,
    input i_delay_in,
    output o_delay_out,
    output [DELAY_CYCLE-1:0] tst_shift_reg
    );

// 移位寄存器实现延迟
reg [DELAY_CYCLE-1:0] shift_reg;
assign tst_shift_reg = shift_reg;

always @(posedge clk) begin
    shift_reg <= {shift_reg[DELAY_CYCLE-2:0], i_delay_in};
end

assign o_delay_out = shift_reg[DELAY_CYCLE-1];

endmodule
