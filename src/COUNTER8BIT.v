`timescale 100ps / 1ps

module COUNTER_8b (
		output reg [7:0] count, // counter output: current count value
		input [7:0] value, // value to be loaded, in load mode
		input ld, // 1 to load the input value; 0 to count;
		input en, // module enable
		input rstz, // module reset
		input clk, // system clock
		inout dvdd, // digital supply
		inout dgnd // digital ground
		);

wire counter_en = en && rstz;

always @(posedge clk)begin: counter_register
	
	if (!counter_en)
		count <= 8'b0;
	else begin
		if (!ld)
			count <= count + 1;
		else
			count <= value;	
	end	
end

endmodule
