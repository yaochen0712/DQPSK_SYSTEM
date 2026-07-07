// 弹性流量控制：积累到 FILL_START 项后开始发送，FIFO 变空则暂停等待重新积累。
// 适用于输入 valid 间隔抖动但均值等于 COEF 的场景。
module flow_control_elastic
#(
    parameter COEF       = 5  ,
    parameter DWIDTH     = 2  ,
    parameter FIFO_DEPTH = 128,
    parameter FILL_START = FIFO_DEPTH / 4  // 开始发送的最低填充深度
)
(
    input                           clk             ,
    input                           rst_n           ,

    output                          o_flow_ready    ,
    input                           i_flow_valid    ,
    input  [DWIDTH-1:0]             i_flow_data     ,

    output                          o_info_fifoempty,
    output                          o_info_fifofull ,

    output logic                    o_ctrl_flow_valid,
    output logic [DWIDTH-1:0]       o_ctrl_flow_data
);
    localparam PTR_W = $clog2(FIFO_DEPTH);

    logic [DWIDTH-1:0]  fifo_array [FIFO_DEPTH];
    logic [PTR_W:0]     head_ptr, end_ptr;

    wire fifo_empty = (head_ptr == end_ptr);
    wire fifo_full  = (head_ptr[PTR_W-1:0] == end_ptr[PTR_W-1:0]) &
                      (head_ptr[PTR_W] ^ end_ptr[PTR_W]);
    wire [PTR_W:0] fill_level = end_ptr - head_ptr;

    assign o_flow_ready     = ~fifo_full;
    assign o_info_fifoempty = fifo_empty;
    assign o_info_fifofull  = fifo_full;

    // 弹性控制：达到阈值才开始发，FIFO 空则停止等待重新积累
    logic fill_ok;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fill_ok <= 1'b0;
        else if (!fill_ok && fill_level >= PTR_W'(FILL_START))
            fill_ok <= 1'b1;
        else if (fill_ok && fifo_empty)
            fill_ok <= 1'b0;
    end

    logic [31:0] counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) counter <= '0;
        else        counter <= (counter == COEF - 1) ? '0 : counter + 1;
    end

    wire out_valid = (counter == COEF - 2) & fill_ok;
    always_ff @(posedge clk) o_ctrl_flow_valid <= out_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= '0;
            end_ptr  <= '0;
            foreach (fifo_array[i]) fifo_array[i] <= '0;
        end else begin
            if (i_flow_valid & o_flow_ready) begin
                fifo_array[end_ptr[PTR_W-1:0]] <= i_flow_data;
                end_ptr <= end_ptr + 1;
            end
            if (out_valid & ~fifo_empty) begin
                o_ctrl_flow_data <= fifo_array[head_ptr[PTR_W-1:0]];
                head_ptr <= head_ptr + 1;
            end
        end
    end

endmodule
