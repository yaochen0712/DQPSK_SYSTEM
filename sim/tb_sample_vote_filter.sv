`timescale 1ns/1ps

module tb_sample_vote_filter;

    localparam time CLK_PERIOD      = 10ns;
    localparam int  OVERSAMPLE_COEF = 12;
    localparam int  VOTE_START      = 3;
    localparam int  VOTE_LEN        = 7;

    logic clk;
    logic rst_n;
    logic sample_bit;
    wire  voted_bit;
    wire  voted_valid;

    logic [OVERSAMPLE_COEF-1:0] windows [0:3];
    logic expected_bits [0:3];

    sample_vote_filter #(
        .OVERSAMPLE_COEF (OVERSAMPLE_COEF),
        .VOTE_START      (VOTE_START),
        .VOTE_LEN        (VOTE_LEN)
    ) u_sample_vote_filter (
        .clk           (clk         ),
        .rst_n         (rst_n       ),
        .i_sample_bit  (sample_bit  ),
        .o_voted_bit   (voted_bit   ),
        .o_voted_valid (voted_valid )
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    task automatic drive_window(input logic [OVERSAMPLE_COEF-1:0] value);
        int idx;
        begin
            for (idx = 0; idx < OVERSAMPLE_COEF; idx++) begin
                @(negedge clk);
                sample_bit = value[idx];
            end
        end
    endtask

    int recv_idx;
    int cycle_count;
    int last_valid_cycle;
    bit seen_first_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_idx         <= 0;
            cycle_count      <= 0;
            last_valid_cycle <= 0;
            seen_first_valid <= 1'b0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (voted_valid) begin
                if (voted_bit !== expected_bits[recv_idx]) begin
                    $fatal(1, "voted[%0d] expected %b got %b",
                           recv_idx, expected_bits[recv_idx], voted_bit);
                end

                if (seen_first_valid && ((cycle_count - last_valid_cycle) != OVERSAMPLE_COEF)) begin
                    $fatal(1, "voted_valid gap expected %0d got %0d",
                           OVERSAMPLE_COEF, cycle_count - last_valid_cycle);
                end

                last_valid_cycle <= cycle_count;
                seen_first_valid <= 1'b1;
                recv_idx         <= recv_idx + 1;
            end
        end
    end

    initial begin
        windows[0] = 12'b111111111111;
        windows[1] = 12'b000001111100;
        windows[2] = 12'b111110000011;
        windows[3] = 12'b000000000000;

        expected_bits[0] = 1'b1;
        expected_bits[1] = 1'b1;
        expected_bits[2] = 1'b0;
        expected_bits[3] = 1'b0;
    end

    initial begin
        rst_n      = 1'b0;
        sample_bit = 1'b0;
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        drive_window(windows[0]);
        drive_window(windows[1]);
        drive_window(windows[2]);
        drive_window(windows[3]);

        repeat (4) @(posedge clk);
        if (recv_idx != 4) begin
            $fatal(1, "expected 4 voted outputs, got %0d", recv_idx);
        end

        $display("tb_sample_vote_filter PASS");
        $finish;
    end

endmodule
