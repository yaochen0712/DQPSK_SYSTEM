//这里是为了丢到Block Designer使用了.v格式 因为Vivado 2024.2尚未支持添加sv模块为rtl block

module tx_top(
    input               clk                 ,
    input               rst_n               ,

    output              o_sample_tick       ,
    input               i_sample_pin        ,

    output              o_tx_error          ,
    
    output  [1:0]       o_tst_IQ_data       ,
    output              o_tst_IQ_stream     ,
    output              o_tst_voted_valid   ,
    output              o_tst_voted_data    ,

    output              o_dbg_flowctrl_err          ,
    output              o_dbg_flow_valid            ,
    output              o_dbg_flow_data             ,

    
    input   [31:0]      i_nco_freqword      ,

    output  [13:0]      o_dac_data                  
);

    parameter SYSTEM_OVERSAMPLE = 12; //72M采样率 要捕获一个6M的信号
    parameter EDGE_DELAY  = 6;
    wire sample_err, modu_err;
    wire coded_stream;
    wire coded_valid;                                                                   
    wire [27:0]     qpsk_data;
    
    tx_sample_coded #(
        .OVER_SAMPLE_COEF   (SYSTEM_OVERSAMPLE),
        .EDGE_DELAY         (EDGE_DELAY)
    )
    u_tx_sample_coded(
        .clk                (clk           ),
        .rst_n              (rst_n         ),    
        .o_sample_tick      (o_sample_tick ),
        .i_sample_bit       (i_sample_pin  ),
        .o_sample_error     (sample_err    ),
        .o_coded_valid      (coded_valid   ),
        
        .o_tst_IQ_data      (o_tst_IQ_data ),
        .o_tst_voted_valid  (o_tst_voted_valid),
        .o_tst_voted_data   (o_tst_voted_data),
        
        .o_dbg_flowctrl_err  (o_dbg_flowctrl_err),
        .o_dbg_flow_valid    (o_dbg_flow_valid  ),
        .o_dbg_flow_data     (o_dbg_flow_data   ),
        
        
        .o_coded_stream     (coded_stream  )
    );

    assign o_tst_IQ_stream = coded_stream;
    
    
    qpsk_stream_modu u_qpsk_modulate(
        .clk             (clk           ),
        .rst_n           (rst_n         ),
        .i_stream_valid  (coded_valid   ),
        .i_stream_bit    (coded_stream  ),
        .i_nco_freqword  (i_nco_freqword),
        .o_modu_err      (modu_err      ),
        .o_qpsk_data     (qpsk_data     ) 
    );

    assign o_dac_data = qpsk_data[21-:14];

endmodule
