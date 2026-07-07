//主要功能:采样，编码，转换成bit流且等间隔配合valid打出

module tx_sample_coded
#(
    parameter OVER_SAMPLE_COEF  =  12,
    parameter EDGE_DELAY        =   6
)
(
    input                               clk                         ,
    input                               rst_n                       ,

    output                              o_sample_tick               ,
    input                               i_sample_bit                ,

    output logic                        o_sample_error              ,
    
    output logic                        o_tst_voted_valid           ,
    output logic                        o_tst_voted_data            ,
    
    output                              o_dbg_flowctrl_err          ,
    output                              o_dbg_flow_valid            ,
    output                              o_dbg_flow_data             ,
    
    output logic  [1:0]                 o_tst_IQ_data               ,

    output logic                        o_coded_valid               , 
    output logic                        o_coded_stream                              
);
    logic sample_en;
    logic sample_bit_sync;
    logic sample_bit_voted;

    bit_sync_2ff u_sample_bit_sync(
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .i_async_bit    (i_sample_bit   ),
        .o_sync_bit     (sample_bit_sync)
    );

    sample_edge_sync #(
        .OVERSAMPLE_COEF(OVER_SAMPLE_COEF),
        .EDGE_DELAY     (EDGE_DELAY)
    )
    u_sample_edge_sync(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .i_sample_bit    (sample_bit_sync ),
        .o_sampled_bit   (sample_bit_voted),
        .o_sampled_valid (sample_en       )
    );

    
    flow_control_elastic #(
        .COEF       ( OVER_SAMPLE_COEF      ),
        .DWIDTH     ( 1                     )
    )
    u_tx_flowcontrol_tst(
        .clk                (clk                ), 
        .rst_n              (rst_n              ), 
        .o_flow_ready       ( ), 
        .i_flow_valid       (sample_en          ), 
        .i_flow_data        (sample_bit_voted   ),  
        .o_info_fifoempty   (                   ), 
        .o_info_fifofull    (o_dbg_flowctrl_err ), 
        .o_ctrl_flow_valid  (o_dbg_flow_valid   ), 
        .o_ctrl_flow_data   (o_dbg_flow_data    )
    );

    assign o_tst_voted_valid = sample_en;
    assign o_tst_voted_data  = sample_bit_voted;
    assign o_sample_tick = sample_en;

    logic [1:0] coded_data;
    logic coded_valid;
    logic [1:0] diff_coded_data;
    logic diff_coded_valid;
    assign o_tst_IQ_data = diff_coded_data;

    //没做速率控制的数据
    wire coded_stream_data  ;
    wire coded_stream_valid ;
    wire coded_stream_ready ;
    wire coded_stream_err   ;
    wire flowctrl_err       ;
    assign o_sample_error = flowctrl_err | coded_stream_err;

    conv_encoder_k3 u_encoder(
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .data_in        (sample_bit_voted),
        .valid_in       (sample_en      ),
        .data_out       (coded_data     ),
        .valid_out      (coded_valid    )
    );

    iq_differential_encoder #(
        .WIDTH          (2)
    )
    u_iq_diff_encoder(
        .clk            (clk             ),
        .rst_n          (rst_n           ),
        .i_data         (coded_data      ),
        .i_valid        (coded_valid     ),
        .o_diff_data    (diff_coded_data ),
        .o_diff_valid   (diff_coded_valid)
    );
    
    parser_trans #(
        .PARA_WIDTH     (2),
        .SER_WIDTH      (1)
    )
    u_par2ser(
        .clk             (clk                   ),
        .rst_n           (rst_n                 ),
        .i_para_data     (diff_coded_data       ),
        .i_para_valid    (diff_coded_valid      ),
        .o_para_ready    (                      ),
        .o_ser_data      (coded_stream_data     ),
        .o_ser_valid     (coded_stream_valid    ),
        .i_ser_ready     (coded_stream_ready    ),
        .o_paraser_err   (coded_stream_err      )
    );

    flow_control_elastic #(
        .COEF       ( OVER_SAMPLE_COEF / 2  ),
        .DWIDTH     ( 1                     )
    )
    u_tx_flowcontrol(
        .clk                (clk                ), 
        .rst_n              (rst_n              ), 
        .o_flow_ready       (coded_stream_ready ), 
        .i_flow_valid       (coded_stream_valid ), 
        .i_flow_data        (coded_stream_data  ),  
        .o_info_fifoempty   (                   ), 
        .o_info_fifofull    (flowctrl_err       ), 
        .o_ctrl_flow_valid  (o_coded_valid      ), 
        .o_ctrl_flow_data   (o_coded_stream     )
    );

endmodule
