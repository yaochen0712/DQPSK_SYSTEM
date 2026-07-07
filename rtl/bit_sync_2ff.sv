`timescale 1ns/1ps

module bit_sync_2ff (
    input  logic clk,
    input  logic rst_n,

    input  logic i_async_bit,
    output logic o_sync_bit
);

    logic sync_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_d1    <= 1'b0;
            o_sync_bit <= 1'b0;
        end else begin
            sync_d1    <= i_async_bit;
            o_sync_bit <= sync_d1;
        end
    end

endmodule
