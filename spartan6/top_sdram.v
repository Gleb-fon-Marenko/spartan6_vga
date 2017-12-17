//`timescale 1ps/1ps
module top_sdram (input clk48,rx,rst_n, output H_SYNC,V_SYNC,
output [15:0]RGB
 );  
parameter end_of_all=38462;
//reg                      rst_n;
wire                      clk;
reg                     V_SYNC_pre;
wire                    new_frame,oSYNC_COLOR;

pll pll25_175(clk48,clk);

wire DV;
wire [7:0]data_from_uart,q;
reg [15:0]cnt_w,cnt_r;
//assign DV2=!DV;
always@(posedge clk or negedge rst_n )
if(rst_n==0) cnt_w<=0;
else if( cnt_w!=end_of_all && DV==1 ) cnt_w<=cnt_w+1;

always@(posedge clk or negedge rst_n )
if(rst_n==0) cnt_r<=end_of_all;
else if(new_frame==1 ) cnt_r<=end_of_all;
else
if(re==1&&bit==0) cnt_r<=cnt_r-1;

reg [2:0]bit;

always@(posedge clk or negedge rst_n )
if(rst_n==0) bit<=7;
else if( new_frame==1 ) bit<=7;
else
if(re==1) bit<=bit-1;


 uart_rx #(218) uart ////25170000/115200
  (
   clk,
   rx,
   DV,
   data_from_uart
   );
	
	
 ram ram8(
  clk,
  DV,
  cnt_w,
  data_from_uart,
  clk,
  cnt_r,
  q
);


wire SYNC_RST_N;
assign SYNC_RST_N= (cnt_w>=end_of_all);

//reg V_SYNC_pre;
always@ (posedge clk  )
V_SYNC_pre<=V_SYNC;

//wire new_frame;

assign new_frame=V_SYNC_pre==0&&V_SYNC==1&&oCurrent_Y==0;

assign re=(oSYNC_COLOR&&(oCurrent_Y>0)&&(oCurrent_X>0))||(H_SYNC==0&&H_SYNC_p==1);

reg H_SYNC_p;
always @(posedge clk)
H_SYNC_p<=H_SYNC;

wire    [10:0] oCurrent_X,oCurrent_Y;

assign RGB=  re?q[bit]*16'hFFFF:0;
//assign RGB= rgb/*RGB1&&en_from_vga*/? 16'hFFFF:16'h0000;


VGA_SYNC  vga(
//vga connect
                  .CLK(clk),
						.SYNC_RST_N(SYNC_RST_N),
					   .H_SYNC_CLK(H_SYNC),//
					   .V_SYNC_CLK(V_SYNC),//
						.oCurrent_X(oCurrent_X),//
						.oCurrent_Y(oCurrent_Y),//10
					   .oSYNC_COLOR(oSYNC_COLOR)//1
);
always@(posedge clk)
	V_SYNC_pre<=V_SYNC;
	
	

endmodule