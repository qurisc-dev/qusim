`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/14 16:22:54
// Design Name: 
// Module Name: arrStation
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

`define Zero 32'h00000000
`define True 1'b1
`define False 1'b0

module arrStation(
input wire[31:0] dataA,
input wire[31:0] dataB,
input clk,
input rst,
input g_rst,
input dataReady,                //Input A and B must be synchronized
output reg[31:0] dataAOut,
output reg[31:0] dataBOut,
output reg dataOutReady,
output reg[31:0] result,
output reg resultOutReady
    );

//reg[31:0] a[7:0];
//reg[31:0] b[7:0];
reg[2:0] counter;
//reg[31:0] buffer[7:0];
//reg[8:0] bufferReady;       //An extra bit for wire-connecting

reg [31:0] buff;
reg buffReady;
//reg[7:0] srcReady;
parameter SIZE = 3'h4;

wire[31:0] wr;
wire multReady;
//reg[3:0] bufCounter;
//reg[3:0] addCounter;

wire mult_res_tready;
wire acc_res_tready;

wire aresetn;
assign aresetn = (~rst) & (~g_rst);
//wire grst = (~g_rst) & (aresetn) ;

//assign mult_res_tready = `True;
assign acc_res_tready = `True;
floating_point_0 mult(
      .s_axis_a_tvalid(dataReady),            // input wire s_axis_a_tvalid
      .s_axis_b_tvalid(dataReady),            // input wire s_axis_a_tvalid
      .aclk(clk),
      .aresetn(aresetn),
      .s_axis_a_tdata(dataA),              // input wire [31 : 0] s_axis_a_tdata
      //.s_axis_a_tvalid(wReady),            // input wire s_axis_a_tvalid
      .s_axis_b_tdata(dataB),              // input wire [31 : 0] s_axis_a_tdata
      //.m_axis_result_tvalid(out_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(wr),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tvalid(multReady)
      //.m_axis_result_tready(mult_res_tready)
    );
    wire acc_valid;
    reg acc_input_valid;
    reg[31:0] acc_input_data;
    wire[31:0] acc_data;
    
    reg result_valid;
    wire acc_result_valid;
    reg[2:0] result_counter;
    wire[31:0] acc_result;
    assign acc_valid = acc_input_valid;
    assign acc_data = acc_input_data;
    
wire tlast;
assign tlast = 1'b0;
floating_point_4 acc(
     .aclk(clk),                                        // input wire aclk
     .aresetn(aresetn),
  .s_axis_a_tvalid(acc_valid),                  // input wire s_axis_a_tvalid
  .s_axis_a_tdata(acc_data),                    // input wire [31 : 0] s_axis_a_tdata
  .s_axis_a_tlast(tlast),                    // input wire s_axis_a_tlast
  //.s_axis_operation_tvalid(data_valid),  // input wire s_axis_operation_tvalid
  //.s_axis_a_tready(),  // output wire s_axis_operation_tready
  //.s_axis_operation_tdata(s_axis_operation_tdata),    // input wire [7 : 0] s_axis_operation_tdata
 .m_axis_result_tvalid(acc_result_valid),        // output wire m_axis_result_tvalid
  .m_axis_result_tready(acc_res_tready),        // input wire m_axis_result_tready
  .m_axis_result_tdata(acc_result)          // output wire [31 : 0] m_axis_result_tdata
 // .m_axis_result_tlast()          // output wire m_axis_result_tlast
);

integer i;
always @(posedge clk) begin
    if (rst == `True || g_rst == `True) begin
        result <= `Zero;
        resultOutReady <= `False;
        counter <= 3'h0;
        dataAOut <= `Zero;
        dataBOut <= `Zero;
        dataOutReady <= `False;
        //bufCounter <= 4'h0;
        //bufferReady <= 9'h000;
        //addCounter <= 4'h0;
        buffReady <= `False;
        acc_input_data <= `Zero;
        acc_input_valid <= `False;
        result_counter <= 3'h0;
        result_valid <= `False;
        //for (i = 0; i < SIZE; i = i + 1) buffer[i] <= `Zero;
        buff <= `Zero;
        ///set a and b to 0???
        ///set srcReady
    end else begin
        /*if ((addCounter != SIZE) && (bufferReady[addCounter] == `True)) begin
            addCounter <= addCounter + 1;
            acc_input_valid <= `True;
            acc_input_data <= buffer[addCounter];
        end*/
        if (buffReady == `True) begin
            acc_input_valid <= `True;
            acc_input_data <= buff;
        end
        if (multReady == `True) begin
            buff <= wr;
            buffReady <= `True;
        end
        /*if ((acc_result_valid == `True) && (result_counter != SIZE)) begin
            result_counter
        end else begin
        
        end*/
        if (acc_result_valid == `True && result_counter < SIZE) begin
            result_counter <= result_counter + 1;
            if (result_counter == SIZE - 1) begin
                result <= acc_result;
                resultOutReady <= `True;
            end
        end
        if (counter != SIZE) begin
            if (dataReady == `True) begin
                dataAOut <= dataA;
                dataBOut <= dataB;
                dataOutReady <= `True;
                //a[counter] <= dataA;
                //b[counter] <= dataB;
                //srcReady[counter] <= `True;
                counter <= counter + 1;
            end
        end else begin
            dataOutReady <= `False;
        end
    end
end

  
endmodule
