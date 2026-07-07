//主要功能：IQ解调 同步 最后输出IQ数据

module qpsk_stream_demo#(
    parameter SYMBOL_OVERSAMRATE    = 4         ,
    parameter STEP_CHANGE_CYCLE     = 32'd2000  ,
    parameter DECISION_THRESHOLD    = 20'd4
)
(
    input wire          clk             ,
    input wire          rst_n           ,

    input wire  [15:0]  i_adc_signal    ,
    input wire          i_adc_valid     ,
    input logic [31:0]  nco_word        ,
    
    output wire         o_demo_valid    ,
    output wire [1:0]   o_demo_bits     ,

    output wire [15:0]  o_dbg_filtered_I,  // 成型滤波后I路 MSB 16bit，用于ILA
    output wire [15:0]  o_dbg_filtered_Q,  // 成型滤波后Q路 MSB 16bit
    output wire [15:0]  o_dbg_gardner_wn,  // Gardner环路滤波器输出
    output wire [31:0]  o_dbg_pd        ,  // PHASE
    output wire         o_dbg_strobe       // Gardner有效插值时刻
);


    parameter PD_WIDTH = 32;

    wire  [32-1:0]  phase_detect   ;
    wire  [7:0]     nco_sin     ;
    wire  [7:0]     nco_cos     ;
    
    wire  [23:0]    demo_I      ;
    wire  [23:0]    demo_Q      ;

    assign o_dbg_pd = phase_detect;

    dds_demo_sin_fix u_nco_sin(
        .aclk       (clk        ),
        .aresetn    (rst_n      ),

        .s_axis_phase_tvalid    (1'b1),
        .s_axis_phase_tdata     ({{32'hFFFF_FFFF-phase_detect},nco_word}),

        .m_axis_data_tvalid     (),
        .m_axis_data_tdata      (nco_sin)   
    );

    dds_demo_cos_fix u_nco_cos(
        .aclk       (clk        ),
        .aresetn    (rst_n      ),

        .s_axis_phase_tvalid    (1'b1),
        .s_axis_phase_tdata     ({{32'hFFFF_FFFF-phase_detect},nco_word}),

        .m_axis_data_tvalid     (),
        .m_axis_data_tdata      (nco_cos)   
    );

    mul_demod_fix u_mul_I(
        .CLK        (clk            ),
        .A          (nco_cos        ),
        .B          (i_adc_signal   ),
        .P          (demo_I         )
    );

    mul_demod_fix u_mul_Q(
        .CLK        (clk            ),
        .A          (nco_sin        ),
        .B          (i_adc_signal   ),
        .P          (demo_Q         )
    );
    
    logic valid_pipe;
    always_ff @(posedge clk )begin
        valid_pipe <= i_adc_valid;
    end

    localparam FILTERED_WIDTH = 43; 
    wire [FILTERED_WIDTH - 1:0] demo_filtered_I;
    wire [FILTERED_WIDTH - 1:0] demo_filtered_Q;

    rccos_demod_fir u_rcc_fir_I(
        .aclk                   (clk                ),
        .aresetn                (rst_n              ),

        .s_axis_data_tvalid     (valid_pipe         ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (                   ), // output wire s_axis_data_tready
        .s_axis_data_tdata      (demo_I             ), // input wire [7 : 0] s_axis_data_tdata

        .m_axis_data_tvalid     (                   ), // output wire m_axis_data_tvalid
        .m_axis_data_tdata      (demo_filtered_I    )  // output wire [23 : 0] m_axis_data_tdata
    );

    rccos_demod_fir u_rcc_fir_Q(
        .aclk                   (clk                ),
        .aresetn                (rst_n              ),

        .s_axis_data_tvalid     (valid_pipe         ), // input wire s_axis_data_tvalid
        .s_axis_data_tready     (                   ), // output wire s_axis_data_tready
        .s_axis_data_tdata      (demo_Q             ), // input wire [7 : 0] s_axis_data_tdata

        .m_axis_data_tvalid     (                   ), // output wire m_axis_data_tvalid
        .m_axis_data_tdata      (demo_filtered_Q    )  // output wire [23 : 0] m_axis_data_tdata
    );

    wire [(FILTERED_WIDTH + 1):0] phase_err;

    phase_detector_fix #(
        .D_WIDTH(FILTERED_WIDTH)
        )
    u_phaseloop_filter(
        .filtered_I     (demo_filtered_I    ), //I路经过低通滤波后信号
        .filtered_Q     (demo_filtered_Q    ), //Q路经过低通滤波后信号

        .phase_error    (phase_err          )  //输出的相位误差
    );

    costas_loopfilter_fix#(
        .D_WIDTH            (45         ),
        .PHASE_WIDTH        (PD_WIDTH   ),
        .STEP_CHANGE_CYCLE  (STEP_CHANGE_CYCLE  )
    )
    u_costas_filter(
        .clk            (clk            ),
        .rst_n          (rst_n          ),

        .pd_err         (phase_err      ),
        .pd             (phase_detect   )
    );

    localparam GARDNER_SLICE_MSB = 40;
    wire sync_flag;
    wire sync_I;
    wire sync_Q;

    gardner_sync
    #(
        .OVSAMP_COEF        (SYMBOL_OVERSAMRATE),
        .DECISION_THRESHOLD  (DECISION_THRESHOLD)
    )
    gardner_sync_inst(
        .clk            (clk                ),
        .rst_n          (rst_n              ),
        .data_in_I      (demo_filtered_I[GARDNER_SLICE_MSB -: 15] ),
        .data_in_Q      (demo_filtered_Q[GARDNER_SLICE_MSB -: 15] ),

        .sync_out_I     (sync_I             ),
        .sync_out_Q     (sync_Q             ),
        .sync_flag      (sync_flag          ),
        .o_dbg_wn       (o_dbg_gardner_wn   ),
        .o_dbg_strobe   (o_dbg_strobe       )
    );

    assign o_demo_bits     = {sync_I,sync_Q};
    assign o_demo_valid    = sync_flag;
    assign o_dbg_filtered_I = demo_filtered_I[GARDNER_SLICE_MSB -: 16];
    assign o_dbg_filtered_Q = demo_filtered_Q[GARDNER_SLICE_MSB -: 16];
                                                                   
endmodule
