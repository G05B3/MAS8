`timescale 100ps / 1ps

module mem_256x8 (
			output [7:0] dout, // output data from the memory
			input [7:0] din, // input data to write on the memory
			input [7:0] addr, // address for the data to be written / read
			input rw, // 1 for read mode, 0 for write mode
			input en, // enables the module
			input rstz, // resets the memory
			input clk, // system clock
			inout dvdd, // digital supply
			inout dgnd // digital ground
			);

reg [7:0] register [0:255];
integer i;

wire write_en;
assign write_en = en & !rw;

wire read_en;
assign read_en = en & rw;

always @(posedge clk) begin: set_memory_registers
	if (!rstz) begin// reset memory
		for (i = 0; i < 256; i=i+1) begin
			register[i] <= 1'b0;
		end
	end
	else if (write_en) begin // write to memory line
		register[addr] <= din;
	end	
end

assign dout = read_en ? register[addr] : 8'b0; // set output data

endmodule
