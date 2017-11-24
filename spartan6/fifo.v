module fifo#(parameter w=32 )(input [w-1:0]data_in, input clk,reset,we,re, output [w-1:0]data_out , output fifo_empty,fifo_full);

reg [w-1:0] mem [3:0];

reg [2:0] cnt;
reg [1:0] read_pointer, write_pointer;

assign fifo_empty = (cnt==0);
assign fifo_full  =  (cnt==4);


always@(posedge clk or negedge reset)
begin	
		
	if(reset==0) 
	begin 
		cnt<=0;
		read_pointer<=0;
		write_pointer<=0;
		
	end
	
	else

	if(we==1&&re==1) 
	begin
	write_pointer<=write_pointer+1;
	read_pointer<=read_pointer+1;
	end
	
	else
	begin
	   
		if(we==1)
			
		begin	
			write_pointer<=write_pointer+1;
			cnt<=cnt+1;
		end
		
		if(re==1)
		
		begin
			read_pointer<=read_pointer+1;
			cnt<=cnt-1;
		
		end 
		
	end	
	
end
wire [1:0] read_pre;
assign read_pre=  (read_pointer==0)? 3 : read_pointer-1;
	
assign data_out=mem[read_pointer];///?

always@(posedge clk or negedge reset)
	if(reset==0) 
	begin
		mem[0]<=0;
		mem[1]<=0;
	    	mem[2]<=0;
	    	mem[3]<=0;
	end
	else if(we)  mem[write_pointer]<=data_in;
	
endmodule	
	
	
	
	
	
	
	
	


