`timescale 1ns/1ps

module tb_iq_differential_codec;

    localparam time CLK_PERIOD = 10ns;
    localparam int  NUM_SYMBOLS = 10;

    logic       clk;
    logic       rst_n;
    logic [1:0] in_data;
    logic       in_valid;
    wire  [1:0] encoded_data;
    wire        encoded_valid;
    wire  [1:0] decoded_data;
    wire        decoded_valid;

    logic [1:0] test_data [NUM_SYMBOLS];

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    iq_differential_encoder #(
        .WIDTH(2)
    ) u_encoder (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_data       (in_data      ),
        .i_valid      (in_valid     ),
        .o_diff_data  (encoded_data ),
        .o_diff_valid (encoded_valid)
    );

    iq_differential_decoder #(
        .WIDTH(2)
    ) u_decoder (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_diff_data  (encoded_data ),
        .i_diff_valid (encoded_valid),
        .o_data       (decoded_data ),
        .o_valid      (decoded_valid)
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
        test_data[0] = 2'b00;
        test_data[1] = 2'b01;
        test_data[2] = 2'b11;
        test_data[3] = 2'b10;
        test_data[4] = 2'b10;
        test_data[5] = 2'b00;
        test_data[6] = 2'b11;
        test_data[7] = 2'b01;
        test_data[8] = 2'b00;
        test_data[9] = 2'b10;
    end

    int send_idx;
    int recv_idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_idx <= 0;
        end else if (decoded_valid) begin
            if (decoded_data !== test_data[recv_idx]) begin
                $fatal(1, "decoded[%0d] expected %b got %b", recv_idx, test_data[recv_idx], decoded_data);
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

        $display("tb_iq_differential_codec PASS");
        $finish;
    end

endmodule
