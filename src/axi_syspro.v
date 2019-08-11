`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/29 00:10:06
// Design Name: 
// Module Name: axi_syspro
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

//`define C_S00_AXI_DATA_WIDTH 64
//`define C_S00_AXI_ADDR_WIDTH 12
	module thinpad_qusim_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 64,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 12
	)(
        input wire  s00_axi_aclk,                  ///
		input wire  s00_axi_aresetn,               ///
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,   //
		input wire [2 : 0] s00_axi_awprot,  //??
		input wire  s00_axi_awvalid,    //
		output wire  s00_axi_awready,     //
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,     //
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,  //
		input wire  s00_axi_wvalid,     //
		output wire  s00_axi_wready,     //
		output wire [1 : 0] s00_axi_bresp,   //
		output wire  s00_axi_bvalid,   //
		input wire  s00_axi_bready,    //
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,    //
		input wire [2 : 0] s00_axi_arprot,     //??
		input wire  s00_axi_arvalid,   //
		output wire  s00_axi_arready,   //
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,   //
		output wire [1 : 0] s00_axi_rresp,    //
		output wire  s00_axi_rvalid,      //
		input wire  s00_axi_rready          //
    );
reg [11:0] awaddr, araddr;
wire rst, xvalid, yvalid;
reg [1:0] wstate, rstate;

reg awready, wready, bvalid, arready, rvalid;
//reg [1:0] bresp, rresp;
//reg [63:0] rdata;
wire ready;
wire working;

assign s00_axi_awready = awready;
assign s00_axi_wready = wready;
assign s00_axi_bvalid = bvalid;
assign s00_axi_arready = arready;
assign s00_axi_rvalid = rvalid & (((araddr[11:7] == 5'h01) & ready) || (araddr == 12'h108));

assign rst = ~s00_axi_aresetn;
assign xvalid = (wstate == 2'b01) & (s00_axi_wvalid == 1'b1) & (awaddr[11:7] == 5'h00) & (s00_axi_wstrb[3:0] != 4'h0);
///Do need to write in the first matrix
assign yvalid = (wstate == 2'b01) & (s00_axi_wvalid == 1'b1) & (awaddr[11:7] == 5'h00) & (s00_axi_wstrb[7:4] != 4'h0);
///Do need to write in the second matrix
wire start;
assign start = (wstate == 2'b01) & (s00_axi_wvalid == 1'b1) & 
(awaddr == 12'h100) & (s00_axi_wstrb[0] == 1'b1) & (s00_axi_wdata[0] == 1'b1);

wire [3:0] xaddr, yaddr, zaddr;
assign xaddr = awaddr[6:3];
assign yaddr[1:0] = awaddr[6:5];
assign yaddr[3:2] = awaddr[4:3];
assign zaddr[1:0] = araddr[6:5];
assign zaddr[3:2] = araddr[4:3];

wire [31:0] xdata, ydata;
wire [31:0] xmask, ymask;

assign xmask[7:0] = {8{s00_axi_wstrb[0]}};
assign xmask[15:8] = {8{s00_axi_wstrb[1]}};
assign xmask[23:16] = {8{s00_axi_wstrb[2]}};
assign xmask[31:24] = {8{s00_axi_wstrb[3]}};

assign ymask[7:0] = {8{s00_axi_wstrb[4]}};
assign ymask[15:8] = {8{s00_axi_wstrb[5]}};
assign ymask[23:16] = {8{s00_axi_wstrb[6]}};
assign ymask[31:24] = {8{s00_axi_wstrb[7]}};

assign xdata = s00_axi_wdata[31:0] & xmask;
assign ydata = s00_axi_wdata[63:32] & ymask;
    
assign s00_axi_bresp = 2'b00;
assign s00_axi_rresp = 2'b00;

assign s00_axi_rdata[63:32] = 32'h00000000;
wire [31:0] zdata;
wire [31:0] status;
assign status[0] = working;
assign status[31:1] = 31'h00000000;
assign s00_axi_rdata[31:0] = (araddr != 12'h108)? (zdata) : (status);

SysArrProcessor cop(.clk(s00_axi_aclk), .g_rst(rst), .start(start), .xaddr(xaddr), .yaddr(yaddr), .zaddr(zaddr), 
.xvalid(xvalid), .yvalid(yvalid), .xdata(xdata), .ydata(ydata), .result(zdata), .ready(ready), .flag(working));

always @(posedge s00_axi_aclk) begin
    if (s00_axi_aresetn == 1'b0) begin
        wstate <= 2'b00;
        rstate <= 2'b00;
        awaddr <= 12'h000;
        araddr <= 12'h000;
        awready <= 1'b1;
        wready <= 1'b0;
        bvalid <= 1'b0;
        arready <= 1'b1;
        rvalid <= 1'b0;
        //rdata <= 64'h0000000000000000;
        //bresp <= 2'b00;
        //rresp <= 2'b00;
    end else begin
        if (wstate == 2'b00 && s00_axi_awvalid == 1'b1) begin               //waiting for address
            wstate <= 2'b01;
            awaddr <= s00_axi_awaddr;
            awready <= 1'b0;
            wready <= 1'b1;
        end else if (wstate == 2'b01 && s00_axi_wvalid == 1'b1) begin               //waiting for data
            wstate <= 2'b10;
            wready <= 1'b0;
            bvalid <= 1'b1;
        end else if (wstate == 2'b10 && s00_axi_bready == 1'b1) begin                                       //written in 1 cycle
            wstate <= 2'b00;
            bvalid <= 1'b0;
            awaddr <= 12'h000;
            awready <= 1'b1;
        end
        
        if (rstate == 2'b00 && s00_axi_arvalid == 1'b1) begin                //waiting for address
            rstate <= 2'b01;
            araddr <= s00_axi_araddr;
            arready <= 1'b0;
            rvalid <= 1'b1;
        end else if (rstate == 2'b01 && s00_axi_rready == 1'b1) begin          //took the data
            arready <= 1'b1;
            rvalid <= 1'b0;
            rstate <= 2'b00;
            //araddr <= 12'h000;
        end
    end
end
    
endmodule
