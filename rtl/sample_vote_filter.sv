`timescale 1ns/1ps

module sample_vote_filter
#(
    parameter int OVERSAMPLE_COEF = 12,
    parameter int VOTE_START      = 3,
    parameter int VOTE_LEN        = 7
)
(
    input  logic clk,
    input  logic rst_n,

    input  logic i_sample_bit,
    output logic o_voted_bit,
    output logic o_voted_valid
);

    localparam int COUNT_WIDTH = (OVERSAMPLE_COEF <= 1) ? 1 : $clog2(OVERSAMPLE_COEF);
    localparam int SUM_WIDTH   = $clog2(VOTE_LEN + 1);
    localparam int VOTE_END    = VOTE_START + VOTE_LEN - 1;
    localparam int VOTE_TH     = (VOTE_LEN / 2) + 1;

    logic [COUNT_WIDTH-1:0] sample_count;
    logic [SUM_WIDTH-1:0]   vote_sum;

    wire in_vote_window = (sample_count >= VOTE_START) && (sample_count <= VOTE_END);
    wire window_last    = (sample_count == OVERSAMPLE_COEF - 1);
    wire [SUM_WIDTH-1:0] vote_sum_next = vote_sum + (in_vote_window && i_sample_bit);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count  <= '0;
            vote_sum      <= '0;
            o_voted_bit   <= 1'b0;
            o_voted_valid <= 1'b0;
        end else begin
            o_voted_valid <= 1'b0;

            if (window_last) begin
                o_voted_bit   <= (vote_sum_next >= VOTE_TH);
                o_voted_valid <= 1'b1;
                sample_count  <= '0;
                vote_sum      <= '0;
            end else begin
                sample_count <= sample_count + 1'b1;
                vote_sum     <= vote_sum_next;
            end
        end
    end

endmodule
