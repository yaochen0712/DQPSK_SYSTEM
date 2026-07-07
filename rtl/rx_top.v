//这里是为了丢到Block Designer使用了.v格式 因为Vivado 2024.2尚未支持添加sv模块为rtl block

module rx_top(
    input                   clk             ,
    input                   rst_n           ,

    input  [15:0]           i_ad_data       ,
    input                   i_ad_valid      ,

    input  [31:0]           i_nco_freqword  ,

    output                  o_bit_valid     ,
    output                  o_rx_bit        ,

    output [1:0]            o_tst_IQ_data   ,
    output                  o_rx_error      ,

    output [15:0]           o_dbg_filtered_I,  // 成型滤波后I路 16bit
    output [15:0]           o_dbg_filtered_Q,  // 成型滤波后Q路 16bit
    output [15:0]           o_dbg_gardner_wn,  // Gardner环路滤波器输出
    output [31:0]           o_dbg_pd        ,
    output                  o_dbg_strobe       // Gardner有效插值时刻

);
    parameter SYSTEM_OVERSAMPLE = 12; //72M采样率 要捕获一个6M的信号
    parameter DECISION_THRESHOLD = 20'd64 ;//防噪声                                                                       
    wire [1:0] IQ_coded_stream_raw;
    wire [1:0] IQ_coded_stream;
    localparam RX_INVERT_Q = 1'b1;

    assign IQ_coded_stream = {IQ_coded_stream_raw[1],
                              IQ_coded_stream_raw[0] ^ RX_INVERT_Q};
    assign o_tst_IQ_data = IQ_coded_stream;
    wire coded_valid    ;

    qpsk_stream_demo #(
        .SYMBOL_OVERSAMRATE (SYSTEM_OVERSAMPLE)
    )
    u_qpsk_stream_demo(
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .i_adc_signal       (i_ad_data          ),
        .i_adc_valid        (i_ad_valid         ),
        .nco_word           (i_nco_freqword     ),
        .o_demo_valid       (coded_valid        ),
        .o_demo_bits        (IQ_coded_stream_raw),
        .o_dbg_filtered_I   (o_dbg_filtered_I   ),
        .o_dbg_filtered_Q   (o_dbg_filtered_Q   ),
        .o_dbg_gardner_wn   (o_dbg_gardner_wn   ),
        .o_dbg_pd           (o_dbg_pd           ),
        .o_dbg_strobe       (o_dbg_strobe       )
    );

    //这里做差分编码

    rx_decode u_rx_decoder(
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .i_coded_valid      (coded_valid    ),
        .i_coded_data       (IQ_coded_stream),
        .o_coded_ready      (),

        .o_cover_error      (o_rx_error     ),
        .o_cover_valid      (o_bit_valid    ),
        .o_cover_data       (o_rx_bit       )
    );

endmodule
