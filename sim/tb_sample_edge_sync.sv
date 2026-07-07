`timescale 1ns/1ps

module tb_sample_edge_sync;

    localparam time CLK_PERIOD = 10ns;
    localparam int  OVERSAMPLE = 12;
    localparam int  EDGE_DELAY = 4;

    logic clk, rst_n, sample_bit;
    wire  sampled_bit, sampled_valid;

    sample_edge_sync #(
        .OVERSAMPLE_COEF(OVERSAMPLE),
        .EDGE_DELAY     (EDGE_DELAY)
    ) dut (
        .clk            (clk         ),
        .rst_n          (rst_n       ),
        .i_sample_bit   (sample_bit  ),
        .o_sampled_bit  (sampled_bit ),
        .o_sampled_valid(sampled_valid)
    );

    initial forever #(CLK_PERIOD/2) clk = ~clk;

    int  valid_count;
    int  cycle_count;
    int  last_valid_cycle;
    bit  check_gap;  // 只在 free-run 连续段内检查间隔

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_count      <= 0;
            cycle_count      <= 0;
            last_valid_cycle <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (sampled_valid) begin
                if (check_gap && valid_count > 0) begin
                    if ((cycle_count - last_valid_cycle) !== OVERSAMPLE)
                        $fatal(1, "[%0d] gap expected %0d got %0d",
                               valid_count, OVERSAMPLE, cycle_count - last_valid_cycle);
                end
                // 第一次 valid 必须采到 1（验证上升沿锁相生效）
                if (valid_count == 0 && sampled_bit !== 1'b1)
                    $fatal(1, "bit[0] expected 1 got %b", sampled_bit);
                last_valid_cycle <= cycle_count;
                valid_count      <= valid_count + 1;
            end
        end
    end

    initial begin
        clk        = 0;
        rst_n      = 0;
        sample_bit = 0;
        check_gap  = 0;

        repeat(4) @(negedge clk);
        rst_n = 1;

        // 上升沿 → 锁相，EDGE_DELAY 后出第一个 valid
        @(negedge clk); sample_bit = 1;

        // 等第一个 valid（DELAY 状态）走完，然后才开始检查间隔
        repeat(EDGE_DELAY + 2) @(negedge clk);
        check_gap = 1;  // 进入 free-run 段，检查每两次 valid 间隔 = OVERSAMPLE

        // 连续 free-run 验证：跑 3 个周期
        repeat(OVERSAMPLE * 3) @(negedge clk);
        check_gap = 0;

        // 下降沿：sample_bit → 0，等 free-run 采到 0
        @(negedge clk); sample_bit = 0;
        repeat(OVERSAMPLE + 2) @(negedge clk);

        // 新上升沿 → 重锁相，关掉 gap check 跨越重锁相边界
        @(negedge clk); sample_bit = 1;
        repeat(EDGE_DELAY + 2) @(negedge clk);
        check_gap = 1;  // 重锁相后再次进入 free-run，重新检查间隔
        repeat(OVERSAMPLE * 2) @(negedge clk);
        check_gap = 0;

        if (valid_count < 6)
            $fatal(1, "expected >=6 valid outputs, got %0d", valid_count);

        $display("tb_sample_edge_sync PASS");
        $finish;
    end

endmodule
