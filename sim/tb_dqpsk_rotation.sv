`timescale 1ns/1ps

module tb_dqpsk_rotation;

    localparam time CLK_PERIOD  = 10ns;
    localparam int  NUM_SYMBOLS = 12;

    logic       clk;
    logic       rst_n;
    logic [1:0] in_data;
    logic       in_valid;
    wire  [1:0] encoded_data;
    wire        encoded_valid;

    logic [1:0] test_data [NUM_SYMBOLS];

    wire [1:0] rot0_data;
    wire [1:0] rot1_data;
    wire [1:0] rot2_data;
    wire [1:0] rot3_data;

    wire [1:0] dec0_data;
    wire [1:0] dec1_data;
    wire [1:0] dec2_data;
    wire [1:0] dec3_data;
    wire       dec0_valid;
    wire       dec1_valid;
    wire       dec2_valid;
    wire       dec3_valid;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    function automatic [1:0] rotate_symbol(input [1:0] symbol, input int rot);
        logic signed_i;
        logic signed_q;
        logic next_i;
        logic next_q;
        int step;
        begin
            next_i = symbol[1];
            next_q = symbol[0];
            for (step = 0; step < rot; step++) begin
                signed_i = next_i;
                signed_q = next_q;
                next_i = ~signed_q;
                next_q =  signed_i;
            end
            rotate_symbol = {next_i, next_q};
        end
    endfunction

    assign rot0_data = rotate_symbol(encoded_data, 0);
    assign rot1_data = rotate_symbol(encoded_data, 1);
    assign rot2_data = rotate_symbol(encoded_data, 2);
    assign rot3_data = rotate_symbol(encoded_data, 3);

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

    iq_differential_decoder #(.WIDTH(2)) u_decoder_rot0 (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_diff_data  (rot0_data    ),
        .i_diff_valid (encoded_valid),
        .o_data       (dec0_data    ),
        .o_valid      (dec0_valid   )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_rot1 (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_diff_data  (rot1_data    ),
        .i_diff_valid (encoded_valid),
        .o_data       (dec1_data    ),
        .o_valid      (dec1_valid   )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_rot2 (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_diff_data  (rot2_data    ),
        .i_diff_valid (encoded_valid),
        .o_data       (dec2_data    ),
        .o_valid      (dec2_valid   )
    );

    iq_differential_decoder #(.WIDTH(2)) u_decoder_rot3 (
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .i_diff_data  (rot3_data    ),
        .i_diff_valid (encoded_valid),
        .o_data       (dec3_data    ),
        .o_valid      (dec3_valid   )
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
        test_data[0]  = 2'b00;
        test_data[1]  = 2'b01;
        test_data[2]  = 2'b11;
        test_data[3]  = 2'b10;
        test_data[4]  = 2'b00;
        test_data[5]  = 2'b11;
        test_data[6]  = 2'b01;
        test_data[7]  = 2'b10;
        test_data[8]  = 2'b11;
        test_data[9]  = 2'b00;
        test_data[10] = 2'b10;
        test_data[11] = 2'b01;
    end

    int send_idx;
    int recv_idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_idx <= 0;
        end else if (dec0_valid) begin
            if (dec0_data !== test_data[recv_idx]) begin
                $fatal(1, "rot0 decoded[%0d] expected %b got %b", recv_idx, test_data[recv_idx], dec0_data);
            end

            if (recv_idx > 0) begin
                if (dec1_data !== test_data[recv_idx]) begin
                    $fatal(1, "rot90 decoded[%0d] expected %b got %b", recv_idx, test_data[recv_idx], dec1_data);
                end
                if (dec2_data !== test_data[recv_idx]) begin
                    $fatal(1, "rot180 decoded[%0d] expected %b got %b", recv_idx, test_data[recv_idx], dec2_data);
                end
                if (dec3_data !== test_data[recv_idx]) begin
                    $fatal(1, "rot270 decoded[%0d] expected %b got %b", recv_idx, test_data[recv_idx], dec3_data);
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

        $display("tb_dqpsk_rotation PASS");
        $finish;
    end

endmodule
