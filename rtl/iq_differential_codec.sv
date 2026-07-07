`timescale 1ns/1ps

module iq_differential_encoder
#(
    parameter WIDTH = 2
)
(
    input  logic             clk,
    input  logic             rst_n,

    input  logic [WIDTH-1:0] i_data,
    input  logic             i_valid,

    output logic [WIDTH-1:0] o_diff_data,
    output logic             o_diff_valid
);

    logic [1:0] prev_phase;
    logic [1:0] data_phase;
    logic [1:0] next_phase;

    function automatic [1:0] symbol_to_phase(input logic [1:0] symbol);
        begin
            case (symbol)
                2'b11: symbol_to_phase = 2'd0;
                2'b01: symbol_to_phase = 2'd1;
                2'b00: symbol_to_phase = 2'd2;
                2'b10: symbol_to_phase = 2'd3;
                default: symbol_to_phase = 2'd0;
            endcase
        end
    endfunction

    function automatic [1:0] phase_to_symbol(input logic [1:0] phase);
        begin
            case (phase)
                2'd0: phase_to_symbol = 2'b11;
                2'd1: phase_to_symbol = 2'b01;
                2'd2: phase_to_symbol = 2'b00;
                2'd3: phase_to_symbol = 2'b10;
                default: phase_to_symbol = 2'b11;
            endcase
        end
    endfunction

    assign data_phase = symbol_to_phase(i_data[1:0]);
    assign next_phase = prev_phase + data_phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_phase     <= 2'd0;
            o_diff_data    <= '0;
            o_diff_valid   <= 1'b0;
        end else if (i_valid) begin
            prev_phase     <= next_phase;
            o_diff_data    <= phase_to_symbol(next_phase);
            o_diff_valid   <= 1'b1;
        end else begin
            o_diff_valid <= 1'b0;
        end
    end

endmodule

module iq_differential_decoder
#(
    parameter WIDTH = 2
)
(
    input  logic             clk,
    input  logic             rst_n,

    input  logic [WIDTH-1:0] i_diff_data,
    input  logic             i_diff_valid,

    output logic [WIDTH-1:0] o_data,
    output logic             o_valid
);

    logic [1:0] prev_phase;
    logic [1:0] current_phase;
    logic [1:0] data_phase;

    function automatic [1:0] symbol_to_phase(input logic [1:0] symbol);
        begin
            case (symbol)
                2'b11: symbol_to_phase = 2'd0;
                2'b01: symbol_to_phase = 2'd1;
                2'b00: symbol_to_phase = 2'd2;
                2'b10: symbol_to_phase = 2'd3;
                default: symbol_to_phase = 2'd0;
            endcase
        end
    endfunction

    function automatic [1:0] phase_to_symbol(input logic [1:0] phase);
        begin
            case (phase)
                2'd0: phase_to_symbol = 2'b11;
                2'd1: phase_to_symbol = 2'b01;
                2'd2: phase_to_symbol = 2'b00;
                2'd3: phase_to_symbol = 2'b10;
                default: phase_to_symbol = 2'b11;
            endcase
        end
    endfunction

    assign current_phase = symbol_to_phase(i_diff_data[1:0]);
    assign data_phase    = current_phase - prev_phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_phase <= 2'd0;
            o_data     <= '0;
            o_valid    <= 1'b0;
        end else if (i_diff_valid) begin
            o_data     <= phase_to_symbol(data_phase);
            prev_phase <= current_phase;
            o_valid    <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end

endmodule
