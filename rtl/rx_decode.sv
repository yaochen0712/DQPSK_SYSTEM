//主要功能: 接收解调的串行bit 转换2bit流 输入解码器输出
//接收端数据流:
//  i_coded_data(串行1bit) -> serpar_trans(1->2bit并串转换) -> conv_decoder_k3(Viterbi解码) -> o_cover_data

module rx_decode(
    input                               clk             ,
    input                               rst_n           ,

    input   [1:0]                       i_coded_data    ,
    input                               i_coded_valid   ,
    output                              o_coded_ready   ,

    output                              o_cover_error   ,
    output  logic                       o_cover_valid   ,
    output  logic                       o_cover_data                
);
    wire [1:0] diff_decoded_data;
    wire       diff_decoded_valid;

    iq_differential_decoder #(
        .WIDTH          (2)
    )
    u_iq_diff_decoder(
        .clk            (clk               ),
        .rst_n          (rst_n             ),
        .i_diff_data    (i_coded_data      ),
        .i_diff_valid   (i_coded_valid     ),
        .o_data         (diff_decoded_data ),
        .o_valid        (diff_decoded_valid)
    );

    //由于卷积编码器初始化要等到晚点稳定 此处加一个valid的延迟使能
    localparam CONV_WAIT_CYCLE = 16'h0090;//仿真便于观察用的 实际下板子烧可以给久一点
    logic [16:0]    wait_counter;
    logic           wait_finished;
    assign wait_finished = (wait_counter == '0);
    always_ff @( posedge clk or negedge rst_n ) begin : WAIT_COUNTING
        if(~rst_n)begin
            wait_counter <= CONV_WAIT_CYCLE - 1;
        end
        else begin
            wait_counter <= wait_finished ? wait_counter : wait_counter - 1;
        end
    end

    wire [1:0] protected_data;
    assign protected_data = wait_finished ? diff_decoded_data : '0;


    // Viterbi解码器: K=3, (5,7)_8, 将2bit编码数据解码为1bit原始数据
    conv_decoder_k3 u_decoder(
        .clk            (clk            ),
        .rst_n          (rst_n          ),

        .data_in        (protected_data ),  // 2bit编码输入
        .valid_in       (diff_decoded_valid),  // 输入有效

        .data_out       (o_cover_data   ),  // 解码后1bit数据
        .valid_out      (o_cover_valid  )   // 解码输出有效
    );

    // 错误输出: 串并转换错误或解码器错误
    assign o_coded_ready = 1'b1;            // 始终准备接收输入
    assign o_cover_error = 1'b0;

endmodule
