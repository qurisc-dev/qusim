`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/22 02:14:14
// Design Name: 
// Module Name: arrRegArray
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


module arrRegArray(
    input clk,
    input rst,
    input g_rst,
    input flag,
    input wire[3:0] index,
    input wire[31:0] input_data,
    input input_valid,
    output wire[127:0] output_data,
    output reg ready
    );

reg [3:0] emit;
wire [3:0] is_valid;
reg [2:0] counter;

wire [1:0] hindex;
assign hindex = index[3:2];

genvar i;
generate
for (i = 0; i < 4; i = i + 1) begin
    arrReg areg(.clk(clk), .g_rst(g_rst), .rst(rst), .emit(emit[i]), .index(index[1:0]), 
    .input_data(input_data), .valid(is_valid[i]), .data(output_data[i*32+31:i*32]));
    assign is_valid[i] = (input_valid == 1'b1 && (hindex == i));
end
endgenerate

always @(posedge clk) begin
    if (rst == 1'b1 || g_rst == 1'b1) begin
        counter <= 3'h0;
        emit <= 4'h0;
        ready <= 1'b0;
    end
    else begin
        if (flag == 1'b1) begin
            if (counter < 3'h4) begin
               counter <= counter + 1;
               emit[counter] <= 1'b1;
               if (counter == 4'h1) ready <= 1'b1;
            end 
        end
    end
end
endmodule
