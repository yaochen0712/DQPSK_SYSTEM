
//////////////////////////////////////////////////////////////////////////////////
//现在是valid指示 第一次是Q 第二次是I
//////////////////////////////////////////////////////////////////////////////////
module iq_div_fix
    (
        input wire          clk             ,
        input wire          rst_n           ,
        input wire          i_ser_data      ,
        input               i_ser_valid     ,
        
        output logic [1:0]  o_Idata         ,
        output logic [1:0]  o_Qdata         ,
        output logic        o_qpsk_valid  
    );
    
    logic sample_ibit;//当这个为1的时候当前采样i路bit
    logic q_buffer;
    logic [1:0] iq_buffer;

    always_ff @( posedge clk or negedge rst_n ) begin : bit_update
        if(~rst_n)begin
            sample_ibit <= '0;
        end
        else begin
            sample_ibit <= i_ser_valid ? (~sample_ibit) : sample_ibit;
        end
    end
    
    logic IQ_finished                   ;
    assign IQ_finished = sample_ibit & i_ser_valid;

    //这里相当于延迟打一排
    always_ff @( posedge clk ) begin
        o_qpsk_valid <= IQ_finished     ;
    end 

    always_ff @( posedge clk or negedge rst_n ) begin : Q_BUF
        if(~rst_n)begin
            q_buffer <= '0              ;
        end
        else if(i_ser_valid & (~sample_ibit))begin
            q_buffer <= i_ser_data      ;
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin : IQ_ALIGN
        if(~rst_n)begin
            iq_buffer <= '0             ;
        end
        else if(IQ_finished)begin
            iq_buffer[0] <= q_buffer    ;
            iq_buffer[1] <= i_ser_data  ;
        end
    end                                        

        //转换为双极性输出
    assign o_Idata = (iq_buffer[1] == 1'b0)? 2'b11:2'b01; 
    assign o_Qdata = (iq_buffer[0] == 1'b0)? 2'b11:2'b01; 
endmodule
