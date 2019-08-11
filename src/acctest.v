`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/17 10:16:42
// Design Name: 
// Module Name: acctest
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


module acctest(
    input rst,
    input clk,
    input data_valid,
    input tlast,
    input wire [31:0] data,
    output wire [31:0] result,
    input wire output_ready,
    output wire result_ready,
    output result_tlast,
    output wire i_ready
    );
    
    floating_point_4 acc(
     .aclk(clk),                                        // input wire aclk
     .aresetn(rst),
  .s_axis_a_tvalid(data_valid),                  // input wire s_axis_a_tvalid
  .s_axis_a_tdata(data),                    // input wire [31 : 0] s_axis_a_tdata
  //.s_axis_a_tlast(s_axis_a_tlast),                    // input wire s_axis_a_tlast
  //.s_axis_operation_tvalid(data_valid),  // input wire s_axis_operation_tvalid
  .s_axis_a_tready(i_ready),  // output wire s_axis_operation_tready
  //.s_axis_operation_tdata(s_axis_operation_tdata),    // input wire [7 : 0] s_axis_operation_tdata
 .m_axis_result_tvalid(result_ready),        // output wire m_axis_result_tvalid
  .m_axis_result_tready(output_ready),        // input wire m_axis_result_tready
  .m_axis_result_tdata(result),          // output wire [31 : 0] m_axis_result_tdata
  .m_axis_result_tlast(result_tlast)          // output wire m_axis_result_tlast
  );
endmodule
