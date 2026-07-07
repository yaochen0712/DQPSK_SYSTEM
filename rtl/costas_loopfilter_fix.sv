
//////////////////////////////////////////////////////////////////////////////////
// Description: COSTAS环中的环路滤波器, 一阶IIR低通滤波器
// 系统函数H(z) = c1+{[c2*z^(-1)]/[1-z^(-1)]}
// 时域差分方程y(n)-y(n-1) = c1*x(n)+(c2-c1)*x(n-1) = c1*(x(n)-x(n-1))+c2*x(n-1)
//////////////////////////////////////////////////////////////////////////////////


module costas_loopfilter_fix
#(
    parameter D_WIDTH = 43,
    parameter STEP_CHANGE_CYCLE  =  2000, //控制两阶段costas系数的切换时间点
    parameter PHASE_WIDTH = 32,

    // c1/c2 shift values are the total power-of-two coefficients.
    // For example, CAPTURE_C1_SHIFT = 8 means c1 = 2^-8.
    parameter int unsigned CAPTURE_C1_SHIFT = 16,
    parameter int unsigned CAPTURE_C2_SHIFT = 10,
    parameter int unsigned TRACK_C1_SHIFT   = 32,
    parameter int unsigned TRACK_C2_SHIFT   = 13
)
(
        input wire                      clk             ,
        input wire                      rst_n           ,
        
        input wire [D_WIDTH - 1:0]      pd_err          , 
        
        output wire[PHASE_WIDTH - 1:0]  pd              //滤波器输出, 与相位控制字位宽相同
);
    
    localparam int unsigned SCALE_WIDTH = (D_WIDTH > PHASE_WIDTH) ? D_WIDTH : PHASE_WIDTH;

    reg  signed [D_WIDTH - 1    :0]  pd_err_d        ; //pd_err打一拍, 作为x(n-1)
    wire signed [D_WIDTH - 1    :0]  pd_err_s        ;
    wire signed [D_WIDTH - 1    :0]  pd_err_sub      ; //x(n)-x(n-1)
    reg  signed [PHASE_WIDTH - 1:0]  pd_sub          ; //y(n)-y(n-1)
    
    //滤波相位控制字输出寄存器, (相位控制字位宽)
    reg signed [PHASE_WIDTH - 1:0]  pd_reg          ; 
    
    //更新速度计数器, 依据该计数器的值选择不同的C1\C2参数组
    reg [31:0]   cnt_update     ;

    function automatic signed [PHASE_WIDTH - 1:0] scale_error;
        input signed [D_WIDTH - 1:0] value;
        input int unsigned coef_shift;

        reg signed [SCALE_WIDTH - 1:0] extended_value;
        reg signed [SCALE_WIDTH - 1:0] shifted_value;
        begin
            extended_value = value;

            if(coef_shift >= SCALE_WIDTH) begin
                shifted_value = {SCALE_WIDTH{value[D_WIDTH - 1]}};
            end else begin
                shifted_value = extended_value >>> coef_shift;
            end

            scale_error = $signed(shifted_value[PHASE_WIDTH - 1:0]);
        end
    endfunction
    
    //cnt_update
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cnt_update <= 'd0;
        end else if(cnt_update == (STEP_CHANGE_CYCLE - 1)) begin //前2000个点使用较大的系数
            cnt_update <= cnt_update;
        end else begin
            cnt_update <= cnt_update + 'd1;
        end
    end

    //pd_err_d
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pd_err_d <= 'd0;
        end else begin
            pd_err_d <= pd_err_s;
        end
    end
    
    //滤波器输出
    //pd输出pd_reg结果
    assign pd = pd_reg;
    
    
    //pd_reg
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pd_reg <= 'd0;
        end else begin
            pd_reg <= pd_reg + pd_sub;  //y(n) = y(n-1)+[y(n)-y(n-1)]
        end
    end
    
    //x(n)-x(n-1)
    assign pd_err_s = $signed(pd_err);
    assign pd_err_sub = pd_err_s - pd_err_d; 

    //y(n)-y(n-1)=c1*(x(n)-x(n-1))+c2*x(n-1)
    always_comb begin
        if(cnt_update == (STEP_CHANGE_CYCLE - 1)) begin //跟踪状态使用小参数
            pd_sub = scale_error(pd_err_sub, TRACK_C1_SHIFT)
                   + scale_error(pd_err_d,   TRACK_C2_SHIFT);
        end 
        else begin //捕获状态使用大参数
            pd_sub = scale_error(pd_err_sub, CAPTURE_C1_SHIFT)
                   + scale_error(pd_err_d,   CAPTURE_C2_SHIFT);
        end
    end
    
    
endmodule
