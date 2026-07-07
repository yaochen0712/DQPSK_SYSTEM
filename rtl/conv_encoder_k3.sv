// 通过valid指示输入，采用K=3, (5,7)_8的编码多项式，码率1/2
module conv_encoder_k3 (
    input  logic clk,
    input  logic rst_n,

    input  logic data_in,
    input  logic valid_in,

    output logic [1:0] data_out,
    output logic valid_out
);

    logic [1:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 2'b0;
            data_out  <= 2'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // G1 = 5_8 = 101_2
            data_out[0] <= data_in ^ shift_reg[0];

            // G2 = 7_8 = 111_2
            data_out[1] <= data_in ^ shift_reg[1] ^ shift_reg[0];
            shift_reg   <= {data_in, shift_reg[1]};
            valid_out   <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
