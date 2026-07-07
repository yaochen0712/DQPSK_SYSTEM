`timescale 1ns/1ps


module tb_loopback(

    );
    
    parameter int  SEED         = 32'h0000_0022;
    parameter time FINISH_TIME  = 1ms;
    parameter int  STIM_MODE    = 0;   // 0: PRBS, 1: 0101..., 2: all 0, 3: all 1

    localparam time CLK_PERIOD  = 10ns;  // 100 MHz
    localparam int  BIT_DIV     = 12;       // 72 MHz / 12 = 6 Mbps
    localparam int  NCO_BIAS    = 32'd0000_0000;

    logic        clk;
    logic        rst_n;
    logic        bit_input;
    wire         sample_tick;
    wire         tx_error;
    logic [31:0] tx_nco_freq;
    logic [31:0] rx_nco_freq;
    wire  [13:0] dac_data;

    logic [31:0] prbs_lfsr;
    logic [3:0]  bit_div_cnt;
    int unsigned bit_cnt;
    int unsigned bit_one_cnt;
    int unsigned bit_zero_cnt;
    int unsigned bit_toggle_cnt;
    int unsigned tick_cnt;
    int unsigned sampled_one_cnt;
    int unsigned sampled_zero_cnt;
    int unsigned tx_error_cnt;
    int unsigned sample_valid_cnt;
    int unsigned sample_fire_cnt;
    int unsigned flow_valid_cnt;
    int unsigned iq_valid_cnt;
    int unsigned qpsk_accept_cnt;
    int unsigned dac_change_cnt;
    logic        bit_input_d;
    logic        tx_error_d;
    logic [13:0] dac_data_d;

    wire prbs_feedback = prbs_lfsr[31] ^ prbs_lfsr[21] ^ prbs_lfsr[1] ^ prbs_lfsr[0];
    wire prbs_next_bit = prbs_lfsr[0];
    wire stim_next_bit = (STIM_MODE == 0) ? prbs_next_bit :
                         (STIM_MODE == 1) ? ~bit_input   :
                         (STIM_MODE == 2) ? 1'b0         :
                         (STIM_MODE == 3) ? 1'b1         :
                                            prbs_next_bit;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b0;
        #(8 * CLK_PERIOD);
        rst_n = 1'b1;
    end

    // Drive the input bit on the falling edge so tx_top samples a stable value.
    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prbs_lfsr      <= (SEED == 0) ? 32'h1 : SEED[31:0];
            bit_input      <= SEED[0];
            bit_div_cnt    <= '0;
            bit_cnt        <= 0;
            bit_one_cnt    <= 0;
            bit_zero_cnt   <= 0;
            bit_toggle_cnt <= 0;
        end else if (bit_div_cnt == BIT_DIV - 1) begin
            bit_div_cnt <= '0;
            bit_input   <= stim_next_bit;
            prbs_lfsr   <= {prbs_lfsr[30:0], prbs_feedback};
            bit_cnt     <= bit_cnt + 1;

            if (stim_next_bit) begin
                bit_one_cnt <= bit_one_cnt + 1;
            end else begin
                bit_zero_cnt <= bit_zero_cnt + 1;
            end

            if (stim_next_bit !== bit_input) begin
                bit_toggle_cnt <= bit_toggle_cnt + 1;
            end

        end else begin
            bit_div_cnt <= bit_div_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_cnt         <= 0;
            sampled_one_cnt  <= 0;
            sampled_zero_cnt <= 0;
            tx_error_cnt     <= 0;
            sample_valid_cnt <= 0;
            sample_fire_cnt  <= 0;
            flow_valid_cnt   <= 0;
            iq_valid_cnt     <= 0;
            qpsk_accept_cnt  <= 0;
            dac_change_cnt   <= 0;
            bit_input_d      <= 1'b0;
            tx_error_d       <= 1'b0;
            dac_data_d       <= '0;
        end 
        else begin
            bit_input_d <= bit_input;
            tx_error_d  <= tx_error;
            dac_data_d  <= dac_data;
        end
    end

    initial begin
        tx_nco_freq = 32'h4000_0000;
        rx_nco_freq = tx_nco_freq + NCO_BIAS;
        @(posedge rst_n);
        $display("[%0t] tb_tx_top starts PRBS stimulus @ 100 MHz", $time);
        #FINISH_TIME;
        $finish;
    end

    tx_noflow_top dut (
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .i_sample_pin       (bit_input      ),
//        .o_sample_tick      (sample_tick    ),
        .o_tx_error         (tx_error       ),
        .i_nco_freqword     (tx_nco_freq    ),
        .o_dac_data         (dac_data       )
    );

    wire bit_decode_valid;
    wire bit_rx;
    wire [15:0] adc_data;
    // assign adc_data = {{2{dac_data[13]}}, dac_data};
    assign adc_data = { dac_data , 2'b0};
    
    rx_noflow_top dut_rx(
        .clk                (clk                ), 
        .rst_n              (rst_n              ), 
        .o_bit_valid        (bit_decode_valid   ), 
        .o_rx_bit           (bit_rx             ), 
        .o_rx_error         (rx_error           ), 
        .i_nco_freqword     (rx_nco_freq        ), 
        .i_ad_data          (adc_data           )    
    );
endmodule
