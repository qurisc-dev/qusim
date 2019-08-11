`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/22 02:10:44
// Design Name: 
// Module Name: SysArrProcessor
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


module SysArrProcessor(
    input clk,
    input g_rst,
    input start,
    input [3:0] xaddr,
    input [3:0] yaddr,
    input xvalid,
    input yvalid,
    input [31:0] xdata,
    input [31:0] ydata,
    input [3:0] zaddr,
    output reg flag,
    output ready,
    output [31:0] result
    );
wire [127:0] wx_data;
wire [127:0] wy_data;
wire xready, yready, input_ready;
wire jobDone;
reg rst;

assign input_ready = xready & yready;
arrRegArray wx(.clk(clk), .g_rst(g_rst), .rst(rst), .flag(flag), .index(xaddr), .input_data(xdata),
.input_valid(xvalid), .output_data(wx_data), .ready(xready));
arrRegArray wy(.clk(clk), .g_rst(g_rst), .rst(rst), .flag(flag), .index(yaddr), .input_data(ydata),
.input_valid(yvalid), .output_data(wy_data), .ready(yready));
SysArr wz(.clk(clk), .rst(rst), .dataReady(input_ready), .dataAIn(wx_data), 
.dataBIn(wy_data), .outputReady(ready), .jobDone(jobDone), .index(zaddr), .data(result), .g_rst(g_rst));

reg [1:0] temp;
always @(posedge clk) begin
    if (g_rst == 1'b1) begin                      ///global reset
        temp <= 2'b00;
        flag <= 1'b0;
        rst <= 1'b0;
    end else begin
         if (temp == 2'b00) begin    
            if (start == 1'b1 && flag == 1'b0) begin ///request and not working
               temp <= 2'b01;
               rst <= 1'b1;                          ///reset worker
            end else if (flag == 1'b1) begin      ///working
                if (jobDone == 1'b1) flag <= 1'b0;        ///job done
            end
         end else if (temp == 2'b01) begin
            temp <= 2'b10;                          ///wait for worker to be reset
         end else if (temp == 2'b10) begin
            rst <= 1'b0;                           ///enable worker
            temp <= 2'b11;
         end else if (temp == 2'b11) begin
            flag <= 1'b1;
            temp <= 2'b00;
         end
     end
end
endmodule
