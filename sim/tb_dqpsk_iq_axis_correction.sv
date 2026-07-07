`timescale 1ns/1ps

module tb_dqpsk_iq_axis_correction;

    localparam time CLK_PERIOD  = 10ns;
    localparam int  NUM_SYMBOLS = 16;

    logic       clk;
    logic       rst_n;
    logic [1:0] in_data;
    logic       in_valid;
    wire  [1:0] encoded_data;
    wire        encoded_valid;

    wire [1:0] mirror_q_data;
    wire [1:0] mirror_q_corrected_data;
    wire [1:0] swap_iq_data;
    wire [1:0] swap_iq_corrected_data;

    wire [1:0] dec_ref_data;
    wire [1:0] dec_mirror_q_raw_data;
    wire [1:0] dec_mirror_q_fixed_data;
    wire [1:0] dec_swap_raw_data;
    wire [1:0] dec_swap_fixed_data;
    wire       dec_ref_valid;
    wire       dec_mirror_q_raw_valid;
    wire       dec_mirror_q_fixed_valid;
    wire       dec_swap_raw_valid;
    wire       dec_swap_fixed_valid;

    logic [1:0] test_data [NUM_SYMBOLS];
    int         recv_idx;
    int         send_idx;
    bit         mirror_q_raw_mismatch_seen;
    bit         swap_raw_mismatch_seen;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    function automatic [1:0] invert_q(input logic [1:0] symbol);
        invert_q = {symbol[1], ~symbol[0]};
    endfunction

    function automatic [1:0] swap_iq(input logic [1:0] symbol);
        swap_iq = {symbol[0], symbol[1]};
    endfunction

    assign mirror_q_data           = invert_q(encoded_data);
    assign mirror_q_corrected_data = invert_q(mirror_q_data);
    assign swap_iq_data            = swap_iq(encoded_data);
    assign swap_iq_corrected_data  = swap_iq(swap_iq_data);

    iq_differential_encoder #(.WIDTH(2)) u_encoder (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_data       (in_data      ),
        .i_valid      (in_valid     ),
        .o_diff_data  (encoded_data ),
        .o_diff_valid (encoded_valid)
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_ref (
        .clk          (clk              ),
        .rst_n        (rst_n            ),
        .i_diff_data  (encoded_data     ),
        .i_diff_valid (encoded_valid    ),
        .o_data       (dec_ref_data     ),
        .o_valid      (dec_ref_valid    )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_mirror_q_raw (
        .clk          (clk                        ),
        .rst_n        (rst_n                      ),
        .i_diff_data  (mirror_q_data              ),
        .i_diff_valid (encoded_valid              ),
        .o_data       (dec_mirror_q_raw_data      ),
        .o_valid      (dec_mirror_q_raw_valid     )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_mirror_q_fixed (
        .clk          (clk                        ),
        .rst_n        (rst_n                      ),
        .i_diff_data  (mirror_q_corrected_data    ),
        .i_diff_valid (encoded_valid              ),
        .o_data       (dec_mirror_q_fixed_data    ),
        .o_valid      (dec_mirror_q_fixed_valid   )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_swap_raw (
        .clk          (clk                    ),
        .rst_n        (rst_n                  ),
        .i_diff_data  (swap_iq_data           ),
        .i_diff_valid (encoded_valid          ),
        .o_data       (dec_swap_raw_data      ),
        .o_valid      (dec_swap_raw_valid     )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_swap_fixed (
        .clk          (clk                    ),
        .rst_n        (rst_n                  ),
        .i_diff_data  (swap_iq_corrected_data ),
        .i_diff_valid (encoded_valid          ),
        .o_data       (dec_swap_fixed_data    ),
        .o_valid      (dec_swap_fixed_valid   )
    );

    task automatic send_symbol(input logic [1:0] value);
        begin
            @(negedge clk);
            in_data  = value;
            in_valid = 1'b1;
            @(negedge clk);
            in_valid = 1'b0;
            in_data  = '0;
        end
    endtask

    initial begin
        test_data[0]  = 2'b11;
        test_data[1]  = 2'b01;
        test_data[2]  = 2'b10;
        test_data[3]  = 2'b00;
        test_data[4]  = 2'b01;
        test_data[5]  = 2'b11;
        test_data[6]  = 2'b10;
        test_data[7]  = 2'b00;
        test_data[8]  = 2'b10;
        test_data[9]  = 2'b01;
        test_data[10] = 2'b00;
        test_data[11] = 2'b11;
        test_data[12] = 2'b01;
        test_data[13] = 2'b10;
        test_data[14] = 2'b11;
        test_data[15] = 2'b00;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_idx                   <= 0;
            mirror_q_raw_mismatch_seen <= 1'b0;
            swap_raw_mismatch_seen     <= 1'b0;
        end else if (dec_ref_valid) begin
            if (!dec_mirror_q_raw_valid || !dec_mirror_q_fixed_valid ||
                !dec_swap_raw_valid || !dec_swap_fixed_valid) begin
                $fatal(1, "decoder valid alignment failed at symbol %0d", recv_idx);
            end

            if (dec_ref_data !== test_data[recv_idx]) begin
                $fatal(1, "ref decoded[%0d] expected %b got %b",
                       recv_idx, test_data[recv_idx], dec_ref_data);
            end

            if (recv_idx > 0) begin
                if (dec_mirror_q_fixed_data !== test_data[recv_idx]) begin
                    $fatal(1, "Q mirror fixed decoded[%0d] expected %b got %b",
                           recv_idx, test_data[recv_idx], dec_mirror_q_fixed_data);
                end

                if (dec_swap_fixed_data !== test_data[recv_idx]) begin
                    $fatal(1, "IQ swap fixed decoded[%0d] expected %b got %b",
                           recv_idx, test_data[recv_idx], dec_swap_fixed_data);
                end

                if (dec_mirror_q_raw_data !== test_data[recv_idx]) begin
                    mirror_q_raw_mismatch_seen <= 1'b1;
                end

                if (dec_swap_raw_data !== test_data[recv_idx]) begin
                    swap_raw_mismatch_seen <= 1'b1;
                end
            end

            recv_idx <= recv_idx + 1;
        end
    end

    initial begin
        rst_n    = 1'b0;
        in_data  = '0;
        in_valid = 1'b0;
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        for (send_idx = 0; send_idx < NUM_SYMBOLS; send_idx++) begin
            send_symbol(test_data[send_idx]);
            repeat (2) @(negedge clk);
        end

        repeat (4) @(negedge clk);

        if (recv_idx != NUM_SYMBOLS) begin
            $fatal(1, "expected %0d decoded symbols, got %0d", NUM_SYMBOLS, recv_idx);
        end

        if (!mirror_q_raw_mismatch_seen) begin
            $fatal(1, "raw Q mirror unexpectedly decoded as if it were equivalent");
        end

        if (!swap_raw_mismatch_seen) begin
            $fatal(1, "raw IQ swap unexpectedly decoded as if it were equivalent");
        end

        $display("tb_dqpsk_iq_axis_correction PASS");
        $finish;
    end

endmodule
