`timescale 1ns/1ps

module tb_sample_sync_tick;

    localparam time CLK_PERIOD  = 10ns;
    localparam int  SAMPLE_COEF = 6;

    logic clk;
    logic rst_n;
    logic async_bit;
    wire  sync_bit;
    wire  sample_tick;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    bit_sync_2ff u_bit_sync (
        .clk        (clk       ),
        .rst_n      (rst_n     ),
        .i_async_bit(async_bit ),
        .o_sync_bit (sync_bit  )
    );

    sample_tick_gen #(
        .SAMPLE_COEF(SAMPLE_COEF)
    ) u_sample_tick_gen (
        .clk          (clk        ),
        .rst_n        (rst_n      ),
        .o_sample_tick(sample_tick)
    );

    int cycle_count;
    int tick_count;
    int last_tick_cycle;
    bit seen_first_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count     <= 0;
            tick_count      <= 0;
            last_tick_cycle <= 0;
            seen_first_tick <= 1'b0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (sample_tick) begin
                tick_count <= tick_count + 1;
                if (seen_first_tick && ((cycle_count - last_tick_cycle) != SAMPLE_COEF)) begin
                    $fatal(1, "sample_tick gap expected %0d got %0d",
                           SAMPLE_COEF, cycle_count - last_tick_cycle);
                end
                last_tick_cycle <= cycle_count;
                seen_first_tick <= 1'b1;
            end
        end
    end

    initial begin
        rst_n     = 1'b0;
        async_bit = 1'b0;
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        async_bit = 1'b1;
        @(posedge clk);
        #1;
        if (sync_bit !== 1'b0) begin
            $fatal(1, "sync_bit changed after one clock, expected two-stage delay");
        end

        @(posedge clk);
        #1;
        if (sync_bit !== 1'b1) begin
            $fatal(1, "sync_bit did not update after two clocks");
        end

        repeat (24) @(posedge clk);
        if (tick_count < 4) begin
            $fatal(1, "expected at least 4 sample ticks, got %0d", tick_count);
        end

        $display("tb_sample_sync_tick PASS");
        $finish;
    end

endmodule
