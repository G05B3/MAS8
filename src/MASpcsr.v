`timescale 100ps / 1ps

module MASpcsr (
		output [7:0] reg3,
		output [7:0] reg2,
		output [7:0] reg1,
		output [7:0] reg0,
		input [15:0] instr_in,
		input pr,
		input en,
		input rstz,
		input clk,
		input te,
		inout dvdd,
		inout dgnd
		);

wire [15:0] instr_out; // instruction code that goes to the ALU
wire [7:0] radr; // address for both jumps and memory accesses
wire [7:0] mem_in; // input data from the memory to the ALU
wire [7:0] sw_in; // input data to memory on SW instructions
wire is_swz; // 0 when the current instruction is SW (memory on write mode), 1 otherwise

//Wires for Test Mux
wire normal_en;
wire [7:0] wb_r0;
wire [7:0] wb_r1;

assign normal_en = te == 0 ? en : 1;
assign reg0 = te == 0 ? wb_r0 : instr_in[15:8];
assign reg1 = te == 0 ? wb_r1 : instr_in[7:0];

assign is_swz = !instr_out[15] | instr_out[14] | instr_out[13] | !instr_out[12]; // 0 if opcode = "1001", 1 otherwise
assign sw_in = instr_out[11] ? (instr_out[10] ? reg3 : reg2) : (instr_out[10] ? wb_r1 : wb_r0); // mux for memory input, with RD's number as sel

INSTRFetch iftch (
			.instr(instr_out),
			.iin(instr_in),
			.radr(radr),
			.en(normal_en),
			.pr(pr),
			.rstmemz(rstz),
			.clk(clk),
			.dvdd(dvdd),
			.dgnd(dgnd)	
			);

ALU_8b alu (
		.reg3(reg3),
		.reg2(reg2),
		.reg1(wb_r1),
		.reg0(wb_r0),
		.radr(radr),
		.din(mem_in),
		.opcode(instr_out[15:12]),
		.rd(instr_out[11:10]),
		.ra(instr_out[9:8]),
		.c(instr_out[7:0]),
		.en(normal_en),
		.rstz(rstz),
		.clk(clk),
		.dvdd(dvdd),
		.dgnd(dgnd)
		);

mem_256x8 mem (
		.dout(mem_in), // output data from memory goes as input to the ALU
		.din(sw_in),
		.addr(radr),
		.rw(is_swz),
		.en(normal_en),
		.rstz(rstz),
		.clk(clk),
		.dvdd(dvdd),
		.dgnd(dgnd)
		);
	

endmodule
