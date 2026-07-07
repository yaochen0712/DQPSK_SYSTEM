`timescale 1ns/1ps

module sample_tick_gen
#(
    parameter int SAMPLE_COEF = 12
)
(
    input  logic clk,
    input  logic rst_n,

    output logic o_sample_tick
);

    localparam int COUNTER_WIDTH = (SAMPLE_COEF <= 1) ? 1 : $clog2(SAMPLE_COEF);

    logic [COUNTER_WIDTH-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter       <= '0;
            o_sample_tick <= 1'b0;
        end else if (counter == SAMPLE_COEF - 1) begin
            counter       <= '0;
            o_sample_tick <= 1'b1;
        end else begin
            counter       <= counter + 1'b1;
            o_sample_tick <= 1'b0;
        end
    end

endmodule
