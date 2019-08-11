`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/14 20:15:57
// Design Name: 
// Module Name: SysArr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define dataAIn(i) dataAIn[i*32+31: i*32]
`define dataBIn(i) dataBIn[i*32+31: i*32]
`define out(i) out[i*32+31:i*32]

module SysArr(
    input clk,
    input rst,
    input g_rst,
    input dataReady,
    input wire[127:0] dataAIn,
    input wire[127:0] dataBIn,
      
    output outputReady,
    output jobDone,
    //input validread,
    input [3:0] index,
    output [31:0] data
    );
    wire [511:0] out;
    wire [31:0] arr[15:0];
    wire [15:0] readyIn;
    wire [15:0] readyOut;
    wire [15:0] resultReadyOut;
    wire [31:0] dataA[15:0];
    wire [31:0] dataB[15:0];
    wire [31:0] dataAOut[15:0];
    wire [31:0] dataBOut[15:0];
    
    assign data = arr[index];
    
    assign readyIn[0] = dataReady;
    assign dataA[0] = `dataAIn(0);
    assign dataB[0] = `dataBIn(0);
    
    assign outputReady = resultReadyOut[index];
    assign jobDone = resultReadyOut[15];
    genvar i;
    generate
    for (i = 0; i < 16; i = i + 1) 
    begin
        assign arr[i] = `out(i);
        arrStation stat(.clk(clk), .rst(rst), .dataReady(readyIn[i]), .dataOutReady(readyOut[i]),
         .dataA(dataA[i]), .dataB(dataB[i]), .dataAOut(dataAOut[i]), .dataBOut(dataBOut[i]), 
         .result(`out(i)), .g_rst(g_rst), .resultOutReady(resultReadyOut[i]));
        if (i - 4 >= 0) begin
            if (i % 4 != 0) begin
                assign readyIn[i] = readyOut[i - 1] | readyOut[i - 4];
                assign dataA[i] = dataAOut[i - 4];
                assign dataB[i] = dataBOut[i - 1];
            end else begin
                assign readyIn[i] = readyOut[i - 4];
                assign dataA[i] = dataAOut[i - 4];
                assign dataB[i] = `dataBIn(i / 4);
            end
        end else begin
            if (i % 4 != 0) begin
                assign readyIn[i] = readyOut[i - 1];
                assign dataA[i] = `dataAIn(i);
                assign dataB[i] = dataBOut[i - 1];
            end
        end

    end
    
    endgenerate
endmodule
