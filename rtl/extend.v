`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE     
// VSCODE plug-in version: Verilog-Hdl-Format-4.6.20260602
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Please Write Company name
// All rights reserved     
// File name:              
// Last modified Date:     2026/06/27 16:02:34
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Yao chen
// Created date:           2026/06/27 16:02:34
// mail      :             Please Write mail 
// Version:                V1.0
// TEXT NAME:              extend.v
// PATH:                   E:\Workspace\course_release\rtl\extend.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module extend#(
    parameter DIN_WIDTH = 1,
    parameter DOUT_WIDTH = 32
)
(
    input       [DIN_WIDTH-1:0]         i_origin,
    output      [DOUT_WIDTH-1:0]        o_extend                      
);
    localparam coef = DOUT_WIDTH / DIN_WIDTH;
    assign o_extend = {coef{i_origin}};                                                               
                                                                   
endmodule
