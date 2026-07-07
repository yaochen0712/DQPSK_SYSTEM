`timescale 1ns/1ps

module tb_gardner_threshold;

    localparam time CLK_PERIOD = 10ns;

    logic        clk;
    logic        rst_n;
    logic        strobe_flag;
    logic [19:0] interpolate_I;
    logic [19:0] interpolate_Q;
    wire         sync_out_I;
    wire         sync_out_Q;
    wire         sync_flag;
    wire  [15:0] wn;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    gardner_ted #(
        .OVSAMP_COEF        (12),
        .DECISION_THRESHOLD (20'd26214)
    ) dut (
        .clk           (clk          ),
        .rst_n         (rst_n        ),
        .strobe_flag   (strobe_flag  ),
        .interpolate_I (interpolate_I),
        .interpolate_Q (interpolate_Q),
        .sync_out_I    (sync_out_I   ),
        .sync_out_Q    (sync_out_Q   ),
        .sync_flag     (sync_flag    ),
        .wn            (wn           )
    );

    task automatic drive_strobe_and_check(
        input logic [19:0] i_value,
        input logic [19:0] q_value,
        input logic        expected_sync
    );
        begin
            @(negedge clk);
            interpolate_I = i_value;
            interpolate_Q = q_value;
            strobe_flag   = 1'b1;
            @(posedge clk);
            #1;
            if (sync_flag !== expected_sync) begin
                $fatal(1, "expected sync_flag=%b got %b", expected_sync, sync_flag);
            end
            @(negedge clk);
            strobe_flag   = 1'b0;
        end
    endtask

    initial begin
        rst_n         = 1'b0;
        strobe_flag   = 1'b0;
        interpolate_I = '0;
        interpolate_Q = '0;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        drive_strobe_and_check(20'd1000, 20'd1000, 1'b0);
        drive_strobe_and_check(20'd40000, 20'd40000, 1'b0);
        drive_strobe_and_check(20'd40000, 20'd40000, 1'b1);

        $display("tb_gardner_threshold PASS");
        $finish;
    end

endmodule
