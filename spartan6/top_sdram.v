//`timescale 1ps/1ps
module top_sdram (input clk48,rx,rst_n, output H_SYNC,V_SYNC,cnt_status,
output [15:0]RGB,
output [SDRADDR_WIDTH-1:0] addr,
output [BANK_WIDTH-1:0]    bank_addr,
inout  [15:0]             data,
output clock_enable,cs_n,ras_n,cas_n,we_n,data_mask_low,data_mask_high,SDRAM_clk
 );

parameter end_of_data=19221;
parameter maxword=19223;    ///dfdf640*480/16-1   
parameter read_start=30;    //dddd




parameter ROW_WIDTH = 13;
parameter COL_WIDTH = 9;
parameter BANK_WIDTH = 2;

parameter SDRADDR_WIDTH = ROW_WIDTH > COL_WIDTH ? ROW_WIDTH : COL_WIDTH;
parameter HADDR_WIDTH = BANK_WIDTH + ROW_WIDTH + COL_WIDTH;


wire [HADDR_WIDTH-1:0]   wr_addr;
wire  [15:0]              wr_data;
wire                      wr_enable;

wire  [HADDR_WIDTH-1:0]   rd_addr;
wire [15:0]              rd_data;
wire                     rd_enable;
wire                     rd_ready;

wire                     busy;
//reg                      rst_n;
wire                      clk;
reg                     V_SYNC_pre,en_from_vga_X_pre;
wire                    new_frame;

pll pll25_175(clk48,clk);


assign SDRAM_clk=clk;
/* SDRAM SIDE */
/*
wire [SDRADDR_WIDTH-1:0] addr;
wire [BANK_WIDTH-1:0]    bank_addr;
wire  [15:0]             data;
wire                     clock_enable;
wire                     cs_n;
wire                     ras_n;
wire                     cas_n;
wire                     we_n;
wire                     data_mask_low;
wire                     data_mask_high;

wire [3:0] Dqm;

assign Dqm={1'b1,1'b1,data_mask_high,data_mask_low};

mt48lc2m32b2 sdram (
 
 .Dq(data),
 .Addr(addr), 
 .Ba(bank_addr), 
 .Clk(clk), 
.Cke(clock_enable), 
 .Cs_n(cs_n), 
 .Ras_n(ras_n), 
 .Cas_n(cas_n), 
 .We_n(we_n), 
 .Dqm(Dqm)
 
 );
 
*/
 sdram_controller contr  (
    /* HOST INTERFACE */
    wr_addr,
    wr_data,
    wr_enable,

    rd_addr,
    rd_data,
    rd_ready,
    rd_enable,

    busy, rst_n, clk,

    /* SDRAM SIDE */
    addr, bank_addr, data, clock_enable, cs_n, ras_n, cas_n, we_n,
    data_mask_low, data_mask_high
);


wire o_Rx_DV;

wire [7:0]o_Rx_Byte;


 uart_rx  #(218) uart_rx //25175M/115200
  (
   .i_Clock(clk),
   .i_Rx_Serial(rx),
   .o_Rx_DV(o_Rx_DV),
   .o_Rx_Byte(o_Rx_Byte)
   );


reg cnt_mem_buf;

reg [7:0]mem_buf_H,mem_buf_L;

always@(posedge clk or negedge rst_n)
if(rst_n==0) cnt_mem_buf<=0;
else 
if(o_Rx_DV==1) 
cnt_mem_buf<= !cnt_mem_buf;


always@(posedge clk or negedge rst_n)

	if(rst_n==0) mem_buf_L<=0;
	else if(cnt_mem_buf==0&&o_Rx_DV==1) mem_buf_L<=o_Rx_Byte;



always@(posedge clk or negedge rst_n)

	if(rst_n==0) mem_buf_H<=0;
	else if(cnt_mem_buf==1&&o_Rx_DV==1) mem_buf_H<=o_Rx_Byte;



reg [23:0]half_word_cnt;
assign cnt_status=(half_word_cnt==0);
always@(posedge clk or negedge rst_n)
	if(rst_n==0) half_word_cnt<=0;
	else 
	
    if(cnt_mem_buf==1&&o_Rx_DV==1&&half_word_cnt>=end_of_data) 

	half_word_cnt<=0;	
	
	else
	
	if(cnt_mem_buf==1&&o_Rx_DV==1)
	

	half_word_cnt<=half_word_cnt+1;
	
	
	

////////////////////write controller//////////////////////////
assign wr_data={mem_buf_H,mem_buf_L};

assign wr_addr=half_word_cnt-1;

assign wr_enable=(half_word_cnt>0&&cnt_mem_buf==0);
//////////////////////////////////////
wire   we,re,fifo_empty,fifo_full;
 
wire  [15:0] data_out; 
 
reg [23:0]read_cnt; 
always@(posedge clk or negedge rst_n)
	if(rst_n==0) read_cnt<=maxword;
		else if(/*(read_cnt==maxword&&rd_ready==1&&fifo_full==0)*/new_frame==1||half_word_cnt!=0) read_cnt<=maxword;//?
			else if(half_word_cnt==0&&rd_ready==1&&fifo_full==0) read_cnt<=read_cnt-1;

 assign rd_addr=read_cnt;


//////////////////////REAd_control////
fifo #(16) fifo_to_vga(
.data_in(rd_data), 
.clk(clk),
.reset(rst_n),
.we((rd_ready==1)&&(fifo_full==0)),
.re(re), 
.data_out(data_out) , 
.fifo_empty(fifo_empty),
.fifo_full(fifo_full)

);


//reg en_from_vga_pre;
wire en_from_vga;
//always@(posedge clk)
//en_from_vga_pre<=en_from_vga;



reg [3:0]bit_cnt;
 
always@(posedge clk or negedge rst_n)
if(rst_n==0) bit_cnt<=15;
else if(new_frame==1) bit_cnt<=15;
else if(en_from_vga==1) bit_cnt<=bit_cnt-1;


assign re=bit_cnt[3:0]==0&&(fifo_empty==0)&&(en_from_vga==1);




assign rd_enable=(half_word_cnt==0);
wire    [10:0] oCurrent_X,oCurrent_Y;

wire RGB1;
assign RGB1=data_out[bit_cnt[3:0]];

assign RGB= RGB1? 16'hFFFF:16'h0000;


wire en_from_vga_X;
assign en_from_vga=(en_from_vga_X==1)&&oCurrent_Y>0&&oCurrent_X>0||en_from_vga_X_pre==1&&oCurrent_Y>0;



VGA_SYNC  vga(
//vga connect
                  .CLK(clk),
						.SYNC_RST_N(half_word_cnt==0),
					   .H_SYNC_CLK(H_SYNC),//
					   .V_SYNC_CLK(V_SYNC),//
						.oCurrent_X(oCurrent_X),//
						.oCurrent_Y(oCurrent_Y),//10
					   .oSYNC_COLOR(en_from_vga_X)//1
);

always@(posedge clk)
	V_SYNC_pre<=V_SYNC;
	
always@(posedge clk)
	en_from_vga_X_pre<=en_from_vga_X;	
	
assign new_frame=V_SYNC==1&&V_SYNC_pre==0&&oCurrent_Y==0; 

/////////////////////////////////////////////////	
//initial 
//begin
//clk=0;
//rst_n=0;

//wr_addr=0;
//wr_data=0;
//wr_enable=0;

//rd_addr=0;
//rd_enable=0;

//en_from_vga=1;
//#200000 rst_n=1;
//#10000 wr_enable=1;

//end

//always #5000 clk=!clk;

//always@ (negedge  we_n )
//wr_addr<=wr_addr+1;

endmodule