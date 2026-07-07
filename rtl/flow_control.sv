//采样用的80M时钟 降采样5倍进行
//预期会是一次性接收连续拉高16个周期的输入 然后按照顺序一个个输出，每隔五次出一个
//采用一个大于一帧（32bit,这里留64bit）,本质是一个FIFO再缓冲一级

module flow_control
#(
    parameter COEF  = 5  ,
    parameter DWIDTH = 2
)
(
    input                               clk                 ,
    input                               rst_n               ,

    output                              o_flow_ready        ,
    input                               i_flow_valid        ,
    input   [DWIDTH-1:0]                 i_flow_data         ,

    output                              o_info_fifoempty    ,
    output                              o_info_fifofull     ,

    output  logic                       o_ctrl_flow_valid   ,
    output  logic [DWIDTH-1:0]           o_ctrl_flow_data    

);
    localparam fifo_depth =128;
    logic [DWIDTH-1:0] fifo_array [fifo_depth];
    logic [$clog2(fifo_depth):0] head_ptr,end_ptr;
    logic fifo_empty,fifo_full;
    assign o_info_fifoempty = fifo_empty;
    assign o_info_fifofull  = fifo_full ;
    assign o_flow_ready     = ~fifo_full;
    assign fifo_empty = (head_ptr == end_ptr);
    assign fifo_full  = (head_ptr[ $clog2(fifo_depth) - 1:0 ] == end_ptr[ $clog2(fifo_depth) - 1:0 ])
                            & (head_ptr[ $clog2(fifo_depth)] ^ end_ptr[ $clog2(fifo_depth)]);

    logic init_wait_status;//这个时候还没有输入valid还在一个等待
    always_ff @( posedge clk or negedge rst_n ) begin : wait_status;
        if(~rst_n)begin
            init_wait_status <= '0;
        end
        else begin
            if(i_flow_valid == 1'b1)begin
                init_wait_status <= 1'b1;
            end
        end
    end

    logic [31:0] counter; //这个永远是五个周期发起一次
    always_ff @( posedge clk or negedge rst_n ) begin : valid_declock
        if(~rst_n)begin
            counter <= '0;
        end
        else begin
            counter <= (counter == COEF - 1) ? '0 : counter + 1 ;
        end
    end

    wire out_valid;
    assign out_valid = (counter == COEF - 2) & init_wait_status;//提前一拍 然后valid和指针都在第五拍更新
    always_ff @( posedge clk ) begin : valid_update
        o_ctrl_flow_valid <= out_valid;
    end

    always_ff @( posedge clk or negedge rst_n ) begin : pointer_fifo_update
        if(~rst_n)begin
            head_ptr            <=  '0;
            end_ptr             <=  '0;
            foreach(fifo_array[i]) begin
                fifo_array[i] <= '0;
            end
        end
        else begin
            if(i_flow_valid & o_flow_ready)begin
                fifo_array[end_ptr[ $clog2(fifo_depth) - 1:0 ]] <= i_flow_data;
                end_ptr <= end_ptr + 1;
            end
            if(out_valid & ~fifo_empty)begin
                head_ptr <= head_ptr + 1;
                o_ctrl_flow_data <= fifo_array[head_ptr[ $clog2(fifo_depth) - 1:0 ]];
            end
        end
    end


endmodule
