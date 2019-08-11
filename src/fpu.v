`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/04 09:08:29
// Design Name: 
// Module Name: fpu
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


module fpu(
    input wire[31:0] a,
    input wire[31:0] b,
    input valida,
    input validb,
    input aclk,
    output wire[31:0] c,
    output wire out_valid
    );
    wire oready;
    assign oready = 1'b1;
   floating_point_0 mult(
      .s_axis_a_tvalid(valida),            // input wire s_axis_a_tvalid
      .aclk(aclk),
      .s_axis_a_tdata(a),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(validb),            // input wire s_axis_a_tvalid
      .s_axis_b_tdata(b),              // input wire [31 : 0] s_axis_a_tdata
      .m_axis_result_tvalid(out_valid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata(c),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tready(oready)
    );
endmodule
