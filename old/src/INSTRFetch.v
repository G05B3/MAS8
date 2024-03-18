`timescale 100ps / 1ps

module INSTRFetch (
			output [15:0] instr, // output 16 bit instruction
			input [15:0] iin, // input instruction
			input [7:0] radr, // jump addres
			input en, // enables the module
			input pr, // 1 for programming mode, 0 for run mode
			input rstmemz, // memory reset
			input clk, // system clock
			inout dvdd, // digital supply
			inout dgnd // digital gorund	
			);

wire [7:0] count;

wire rw;
assign rw = !pr;

wire is_jmp;
assign is_jmp = instr[15] & instr[14] & instr[13] & instr[12] & rw; // opcode = "1111" and we are on read mode

wire [7:0] nextPC;
assign nextPC = count + radr;

reg pr_1d;
always @(posedge clk) begin: set_pr_1d
	pr_1d <= pr;
end

wire rstcntz;
assign rstcntz = !(pr ^ pr_1d); // xnor of pr and pr_1d

COUNTER_8b cnt (
		.count(count),
		.value(nextPC),
		.ld(is_jmp),
		.en(en),
		.rstz(rstcntz),
		.clk(clk),
		.dvdd(dvdd),
		.dgnd(dgnd)
		);

mem_256x16 mem (
		.dout(instr),
		.din(iin),
		.addr(count),
		.rw(rw),
		.en(en),
		.rstz(rstmemz),
		.clk(clk),
		.dvdd(dvdd),
		.dgnd(dgnd)
		);

endmodule
