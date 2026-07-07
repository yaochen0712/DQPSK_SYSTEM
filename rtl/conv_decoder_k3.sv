// Viterbi解码器，K=3, (5,7)_8
module conv_decoder_k3 (
    input  logic clk,
    input  logic rst_n,
    input  logic [1:0] data_in,
    input  logic valid_in,
    output logic data_out,
    output logic valid_out
);

    localparam NUM_STATES   = 4;
    localparam TB_DEPTH     = 15;
    localparam METRIC_WIDTH = 8;
    localparam [METRIC_WIDTH-1:0] INF_METRIC = {2'b01, {(METRIC_WIDTH-2){1'b1}}};

    logic [METRIC_WIDTH-1:0] metric     [NUM_STATES];
    logic [METRIC_WIDTH-1:0] new_metric [NUM_STATES];
    logic [NUM_STATES-1:0]   path_mem   [TB_DEPTH];
    logic [NUM_STATES-1:0]   survivor;
    logic [3:0] ptr;
    logic [3:0] count;

    function automatic [1:0] calc_output;
        input [1:0] state;
        input bit_in;
        logic [2:0] temp;
        temp = {bit_in, state};
        calc_output[0] = ^(temp & 3'b101);  // G1 = 5_8
        calc_output[1] = ^(temp & 3'b111);  // G2 = 7_8
    endfunction

    function automatic [1:0] hamming;
        input [1:0] a, b;
        hamming = (a[0] ^ b[0]) + (a[1] ^ b[1]);
    endfunction

    integer i, j, k;
    logic [METRIC_WIDTH-1:0] m0, m1;
    logic [1:0] out0, out1;

    // ACS：枚举每个目标状态j，从两个前驱中选优
    always_comb begin
        for (j = 0; j < NUM_STATES; j++) begin
            out0 = calc_output({j[0], 1'b0}, j[1]);
            out1 = calc_output({j[0], 1'b1}, j[1]);
            m0 = metric[{j[0], 1'b0}] + hamming(out0, data_in);
            m1 = metric[{j[0], 1'b1}] + hamming(out1, data_in);
            survivor[j]    = (m0 <= m1);
            new_metric[j]  = survivor[j] ? m0 : m1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_STATES; i++) metric[i] <= (i == 0) ? '0 : INF_METRIC;
            for (i = 0; i < TB_DEPTH; i++) path_mem[i] <= '0;
            ptr       <= 0;
            count     <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            metric        <= new_metric;
            path_mem[ptr] <= survivor;
            ptr           <= (ptr + 1 >= TB_DEPTH) ? 4'd0 : ptr + 4'd1;
            count         <= (count < TB_DEPTH) ? count + 1 : TB_DEPTH;
            valid_out     <= (count >= TB_DEPTH - 1);
        end else begin
            valid_out <= 0;
        end
    end

    logic [1:0] min_state;
    logic [3:0] tb_ptr;
    logic [1:0] trace_state [TB_DEPTH];

    // 最优状态查找 + 回溯
    always_comb begin
        min_state = 0;
        for (k = 1; k < NUM_STATES; k++) begin
            if (metric[k] < metric[min_state]) min_state = k[1:0];
        end

        tb_ptr = (ptr == 0) ? TB_DEPTH - 1 : ptr - 1;
        trace_state[TB_DEPTH-1] = min_state;

        for (k = TB_DEPTH - 1; k > 0; k--) begin
            trace_state[k-1] = {trace_state[k][0], ~path_mem[tb_ptr][trace_state[k]]};
            tb_ptr = (tb_ptr == 0) ? TB_DEPTH - 1 : tb_ptr - 1;
        end

        data_out = trace_state[0][1];
    end

endmodule
