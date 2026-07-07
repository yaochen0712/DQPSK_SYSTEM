module parser_trans
#(
    parameter PARA_WIDTH = 32,
    parameter SER_WIDTH  = 2
)
(
    input                           clk             ,
    input                           rst_n           ,

    input  [PARA_WIDTH - 1:0]       i_para_data     ,
    input                           i_para_valid    ,
    output logic                    o_para_ready    ,

    output logic [SER_WIDTH - 1:0]  o_ser_data      ,
    output logic                    o_ser_valid     ,
    input                           i_ser_ready     ,

    output logic                    o_paraser_err   
);
    localparam PS_COEF = PARA_WIDTH / SER_WIDTH;
    localparam COUNT_MAX = PS_COEF - 1;
    logic [$clog2(PS_COEF):0] counter;
    logic [PARA_WIDTH - 1:0] para_buffer;
    logic busy;
    logic para_fired;
    logic ser_fired;

    assign para_fired = i_para_valid & o_para_ready;
    assign ser_fired  = i_ser_ready & o_ser_valid;

    assign o_para_ready = ~busy;
    assign o_ser_valid   = busy;
    assign o_ser_data    = busy ? para_buffer[(counter * SER_WIDTH)+:SER_WIDTH] : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            busy    <= 1'b0;
        end else begin
            if (para_fired) begin
                counter <= '0;
                busy    <= 1'b1;
            end else if (ser_fired) begin
                if (counter == COUNT_MAX) begin
                    counter <= '0;
                    busy    <= 1'b0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_paraser_err <= 1'b0;
        end else if (o_ser_valid & i_para_valid) begin
            o_paraser_err <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            para_buffer <= '0;
        end else if (para_fired) begin
            para_buffer <= i_para_data;
        end
    end

endmodule
