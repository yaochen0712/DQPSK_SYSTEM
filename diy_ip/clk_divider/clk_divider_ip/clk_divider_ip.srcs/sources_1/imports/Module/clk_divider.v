/*
 * @Author: TQ-V85Sn 
 * @Date: 2022-01-27 13:16:29 
 * @Last Modified by: TQ-V85Sn
 * @Last Modified time: 2022-02-06 10:41:30
 */

// 适用于分频倍数较大时的简易时钟分频器

//  CNT_MAX至少为2，即至少为2分频
//      在计数值等于CNT_MAX-1时，flag为高电平
//      而对于使用该标志位的系统而言，是在计数值归零时，flag才有效，即当计数值归零时，使用该标志位的系统就有效一次


module clk_divider#(
    parameter DIVIDE_RATE = 12, // 分频倍数
    parameter PULSE_DELAY = 3, // 相较于 clk_out 的上升沿，pulse_out 的上升沿的延迟
    parameter COUNT_WIDTH = 16  // 计数器位宽
) (
    input   wire    sys_clk,
    input   wire    rst_n,  
    output  reg     clk_out,
    output  reg     pulse_out
);
	localparam DIVIDE_RATE_HALF = DIVIDE_RATE / 2;
    reg [COUNT_WIDTH - 1 : 0] clk_cnt;

    // 计数器计数
    always @(posedge sys_clk or negedge rst_n) begin
        if(rst_n == 0) //复位有效
            clk_cnt <= 0;
        else if(clk_cnt == (DIVIDE_RATE - 1)) //计数值满
            clk_cnt <= 0;
        else //没有事件，正常计数
            clk_cnt <= clk_cnt + 1;
    end

    // 时钟输出 
    always @(posedge sys_clk or negedge rst_n) begin
        if(rst_n == 0) //复位有效
			clk_out <= 0;
        else if(clk_cnt < DIVIDE_RATE_HALF) 
            clk_out <= 1;
        else 
            clk_out <= 0;
    end

    // 标志位 
    always @(posedge sys_clk or negedge rst_n) begin
        if(rst_n == 0) //复位有效
			pulse_out <= 0;
        else if(clk_cnt == PULSE_DELAY) //计数值满
            pulse_out <= 1;
        else //没有事件
            pulse_out <= 0;
    end

endmodule // divider_8bits
