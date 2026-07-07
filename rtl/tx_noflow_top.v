
module tx_noflow_top(
    input               clk                 ,
    input               rst_n               ,

    // output              o_sample_tick       ,
    input               i_sample_pin        ,

    output              o_tx_error          ,
    
    output  [1:0]       o_tst_IQ_data       ,
    output              o_tst_IQ_valid      ,

    output              o_tst_voted_valid   ,
    output              o_tst_voted_data    ,
    
    input   [31:0]      i_nco_freqword      ,

    output  [13:0]      o_dac_data    
);
    parameter OVER_SAMPLE_COEF  =  12   ;
    parameter EDGE_DELAY        =   6   ;

    wire sample_en;
    wire sample_bit_sync;
    wire sample_bit_voted;

    bit_sync_2ff u_sample_bit_sync(
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .i_async_bit    (i_sample_pin   ),
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

    assign o_tst_voted_valid    = sample_en             ;
    assign o_tst_voted_data     = sample_bit_voted      ;

    wire [1:0] coded_data; //Q,I 0:1;
    wire coded_valid;
    wire [1:0] diff_coded_data;
    assign o_tst_IQ_data = diff_coded_data;
    wire diff_coded_valid;
    assign o_tst_IQ_valid = diff_coded_valid;

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

    wire [31:0] I_filtered  ;
    wire [31:0] Q_filtered  ;

    wire [7:0]  carry_sin   ;
    wire [7:0]  carry_cos   ;

    wire [27:0] qpsk_i      ;
    wire [27:0] qpsk_q      ;

    wire signed [7:0] I_data, Q_data;

    assign Q_data = (diff_coded_data[0] == 0) ? {7'h7F,1'b1} : {7'h00,1'b1};
    assign I_data = (diff_coded_data[1] == 0) ? {7'h7F,1'b1} : {7'h00,1'b1};

    //目前没有用插值 可以进一步优化
    //I路成形滤波
    rcosfilter rcosfilter_I (
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_data_tvalid     (1'b1           ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (               ), // output wire s_axis_data_tready
        .s_axis_data_tdata      (I_data         ), // input wire [7 : 0] s_axis_data_tdata
        .m_axis_data_tvalid     (               ), // output wire m_axis_data_tvalid
        .m_axis_data_tdata      (I_filtered     )  // output wire [23 : 0] m_axis_data_tdata
    );

    rcosfilter rcosfilter_Q (
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_data_tvalid     (1'b1           ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (               ), // output wire s_axis_data_tready
        .s_axis_data_tdata      (Q_data         ), // input wire [7 : 0] s_axis_data_tdata
        .m_axis_data_tvalid     (               ), // output wire m_axis_data_tvalid
        .m_axis_data_tdata      (Q_filtered     )  // output wire [23 : 0] m_axis_data_tdata
    );

    dds_mod_cos tx_nco_cos(
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_phase_tdata     (i_nco_freqword ),
        .s_axis_phase_tvalid    (1'b1           ),

        .m_axis_data_tdata      (carry_cos      ),
        .m_axis_data_tvalid     (               )
    );

    dds_mod_sin tx_nco_sin(
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_phase_tdata     (i_nco_freqword ),
        .s_axis_phase_tvalid    (1'b1           ),

        .m_axis_data_tdata      (carry_sin      ),
        .m_axis_data_tvalid     (               )
    );

        //I路滤波后与cos载波相乘, 成形滤波结果低位截断、相当于增益降低
    mul_mod mul_mod_I(
        .CLK                    (clk                ),            // input wire CLK
        .A                      (I_filtered[24-:20] ),           // input wire [19 : 0] A
        .B                      (carry_cos          ),           // input wire [7 : 0] B
        .P                      (qpsk_i             )            // output wire [27 : 0] P
    );
        
    //Q路滤波后与sin载波相乘
    //位宽配置同I路一致
    mul_mod mul_mod_Q(
        .CLK                    (clk                ),             // input wire CLK
        .A                      (Q_filtered[24-:20] ),            // input wire [19 : 0] A
        .B                      (carry_sin          ),            // input wire [7 : 0] B
        .P                      (qpsk_q             )             // output wire [27 : 0] P
    ); 

    wire [27:0] qpsk_data;
    parameter QPSK_MSB = 23;
    
    //IQ两路信号叠加
    assign qpsk_data = qpsk_i + qpsk_q;
    assign o_dac_data = qpsk_data[QPSK_MSB-:14];

endmodule
