//这里将valid的串行数据比特流进行IQ映射，然后成型乘以本征得到QPSK数据流给DAC

module qpsk_stream_modu(
    input wire          clk             ,
    input wire          rst_n           ,

    input               i_stream_valid  ,
    input               i_stream_bit    ,

    input  [31:0]       i_nco_freqword  ,

    output wire         o_modu_err      ,

    output wire [27:0]  o_qpsk_data        
);
    wire signed[1:0] I,Q;
    wire        symbol_valid;

    wire [31:0] I_filtered  ;
    wire [31:0] Q_filtered  ;

    wire [7:0]  carry_sin   ;
    wire [7:0]  carry_cos   ;

    wire [27:0] qpsk_i      ;
    wire [27:0] qpsk_q      ;
    //I/Q分流
    iq_div_fix
    iq_div_inst(
        .clk            (clk                ),
        .rst_n          (rst_n              ),
        
        .i_ser_data     (i_stream_bit       ),
        .i_ser_valid    (i_stream_valid     ),

        .o_Idata        (I                  ),
        .o_Qdata        (Q                  ),
        .o_qpsk_valid   (symbol_valid       )
    );

    //目前没有用插值 可以进一步优化
    //I路成形滤波
    rcosfilter rcosfilter_I (
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_data_tvalid     (1'b1           ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (               ), // output wire s_axis_data_tready
        .s_axis_data_tdata      ({{6{I[1]}},I}  ), // input wire [7 : 0] s_axis_data_tdata
        .m_axis_data_tvalid     (               ), // output wire m_axis_data_tvalid
        .m_axis_data_tdata      (I_filtered     )  // output wire [23 : 0] m_axis_data_tdata
    );

    //Q路成形滤波
    rcosfilter rcosfilter_Q (
        .aclk                   (clk            ), // input wire aclk
        .aresetn                (rst_n          ),
        .s_axis_data_tvalid     (1'b1           ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (               ), // output wire s_axis_data_tready
        .s_axis_data_tdata      ({{6{Q[1]}},Q}  ), // input wire [7 : 0] s_axis_data_tdata
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

    //IQ两路信号叠加
    assign o_qpsk_data = qpsk_i + qpsk_q;

endmodule
