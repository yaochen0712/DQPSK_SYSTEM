`timescale 1ns/1ps

// 边沿锁相采样模块
// 检测上升沿后延迟 EDGE_DELAY 拍采样，随后每 OVERSAMPLE_COEF 拍采样一次。
// 每次检测到新上升沿即重新锁相，跟踪 BMC 相位漂移。
module sample_edge_sync
#(
    parameter int OVERSAMPLE_COEF = 12,
    parameter int EDGE_DELAY      = 12      // 上升沿后延迟几拍采样
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic i_sample_bit,             // 已经过 2FF 同步的输入
    output logic o_sampled_bit,
    output logic o_sampled_valid
);

    localparam int CNT_W    = $clog2(OVERSAMPLE_COEF);
    localparam int DLY_CMP  = EDGE_DELAY      - 1;
    localparam int FREE_CMP = OVERSAMPLE_COEF - 1;

    typedef enum logic [1:0] {WAIT_EDGE, DELAY, FREE_RUN} state_t;
    state_t state;

    logic prev_bit;
    logic [CNT_W-1:0] cnt;

    wire rising_edge_det = i_sample_bit & ~prev_bit;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_bit        <= 1'b0;
            cnt             <= '0;
            state           <= WAIT_EDGE;
            o_sampled_bit   <= 1'b0;
            o_sampled_valid <= 1'b0;
        end else begin
            prev_bit        <= i_sample_bit;
            o_sampled_valid <= 1'b0;

            case (state)
                WAIT_EDGE: if (rising_edge_det) begin
                    cnt   <= '0;
                    state <= DELAY;
                end

                DELAY: if (cnt == CNT_W'(DLY_CMP)) begin
                    o_sampled_bit   <= i_sample_bit;
                    o_sampled_valid <= 1'b1;
                    cnt             <= '0;
                    state           <= FREE_RUN;
                end else begin
                    cnt <= cnt + 1'b1;
                end

                FREE_RUN: begin
                    if (cnt == CNT_W'(FREE_CMP)) begin
                        // 采样优先：即使同拍有上升沿也先输出本次采样，
                        // 随后若有边沿则重锁相，避免在采样点丢 bit。
                        o_sampled_bit   <= i_sample_bit;
                        o_sampled_valid <= 1'b1;
                        if (rising_edge_det) begin
                            cnt   <= '0;
                            state <= DELAY;
                        end else begin
                            cnt   <= '0;
                        end
                    end else if (rising_edge_det) begin     // 非采样点重锁相
                        cnt   <= '0;
                        state <= DELAY;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end

                default: state <= WAIT_EDGE;
            endcase
        end
    end

endmodule
