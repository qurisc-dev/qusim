`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/14 19:28:43
// Design Name: 
// Module Name: arrReg
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

module arrReg(
    input clk,
    input rst,
    input g_rst,
    input emit,
    input wire[1:0] index,
    input wire[31:0] input_data,
    input valid,
    output reg[31:0] data,
    output reg ready
    );
    
reg [31:0] x[3:0];             ////??????? + 1????
reg [2:0] counter;
integer i;
always @(posedge clk) begin
    if (g_rst == 1'b1) begin                ///global reset
        for (i = 0; i < 4; i = i + 1) x[i] <= 32'h00000000;
        data <= 32'h00000000;
        ready <= 1'b0;
        counter <= 3'h0;
    end else if (rst == 1'b1) begin         ///partial reset but preserving data
        ready <= 1'b0;
        counter <= 3'h0;
    end else begin
        if (emit == 1'b1) begin
            if (counter == 3'h4) begin
                ready <= 1'b0;
                data <= 32'h00000000;
            end else begin
                counter <= counter + 1;
                data <= x[counter];
                ready <= 1'b1;
            end 
        end
        if (valid == 1'b1) begin
            x[index] <= input_data;
        end
    end
end




endmodule
