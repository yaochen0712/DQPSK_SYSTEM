module serpar_trans
#(
    parameter PARA_COEF     =   16,
    parameter SER_WIDTH     =   2
)
(
    input                           clk                 ,
    input                           rst_n               ,

    input  [SER_WIDTH - 1:0]        i_ser_data          ,
    input                           i_ser_valid         ,

    output logic [(PARA_COEF * SER_WIDTH)-1:0]             o_para_data         ,
    output logic                    o_para_valid        ,
    input                           i_para_ready        ,

    output logic                    o_para_error

);
    logic [$clog2(PARA_COEF):0] counter;
    logic para_fired;
    localparam COUNT_MAX = PARA_COEF - 1;

    assign para_fired = o_para_valid & i_para_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter      <= '0;
            o_para_valid <= 1'b0;
        end else begin
            if (para_fired) begin
                o_para_valid <= 1'b0;
                counter      <= '0;
            end

            if (i_ser_valid && !o_para_valid) begin
                if (counter == COUNT_MAX) begin
                    o_para_valid <= 1'b1;
                    counter      <= '0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_para_error <= 1'b0;
        end else if (i_ser_valid & o_para_valid) begin
            o_para_error <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_para_data <= '0;
        end else if (o_para_error) begin
            o_para_data <= '0;
        end else if (i_ser_valid && !o_para_valid) begin
            o_para_data[(counter * SER_WIDTH)+:SER_WIDTH] <= i_ser_data;
        end
    end

endmodule
