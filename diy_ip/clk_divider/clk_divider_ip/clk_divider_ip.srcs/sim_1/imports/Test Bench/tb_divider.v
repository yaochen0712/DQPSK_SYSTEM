/*
 * @Author: TQ-V85Sn 
 * @Date: 2022-01-27 13:45:53 
 * @Last Modified by: TQ-V85Sn
 * @Last Modified time: 2022-01-27 13:58:10
 */

`timescale 1ns/1ns

module tb_divider ();

    reg sys_clk, rst_n;
    wire clk_out, pulse_out;

    initial begin
        sys_clk = 1;
        rst_n <= 0;
        #20
        rst_n <= 1;
    end

    always #10 sys_clk = ~sys_clk;

    //--------------------divider_inst--------------------
    clk_divider#(
        .DIVIDE_RATE(64),
        .PULSE_DELAY(10),
        .COUNT_WIDTH(16)
    ) divider_inst(
        .sys_clk    (sys_clk),
        .rst_n      (rst_n),
        .clk_out    (clk_out),
        .pulse_out  (pulse_out)
    );

endmodule