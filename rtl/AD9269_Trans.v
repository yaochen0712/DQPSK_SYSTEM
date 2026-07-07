`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/21 18:21:41
// Design Name: 
// Module Name: AD9269_Trans
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


module AD9269_Trans
#(
    shift = 16384
)
(
    input clk,
    input [15:0] data_in,
    output reg signed [15:0] data_out
    );

    always @(posedge clk) begin
        data_out = data_in - shift;
    end
endmodule
