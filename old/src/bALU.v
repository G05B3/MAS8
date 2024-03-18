`timescale 100 ps / 1 ps

module ALU_8b (
		output reg [7:0] reg3, // value of register R3
		output reg [7:0] reg2, // value of register R2
		output reg [7:0] reg1, // value of register R1
		output reg [7:0] reg0, // value of register R0
		output [7:0] radr, // value of address register (for jumps and mem accesses)
		input [7:0] din, // data input for loading
		input [3:0] opcode, // opcode
		input [1:0] rd, // destination register
		input [1:0] ra, // register RA
		input [7:0] c, // second input (either RB or a constant C); for operations with RB only the 2 LSBs count
		input en, // enables the module
		input rstz, // system reset; resets all registers
		input clk, // system clock
		inout dvdd, // digital supply
		inout dgnd // digital ground
		);


wire [1:0] rb;

assign rb = c[1:0];

wire [7:0] rra;
wire [7:0] rrb;

assign rra = ra[1] ? (ra[0] ? reg3 : reg2) : (ra[0] ? reg1 : reg0);
assign rrb = rb[1] ? (rb[0] ? reg3 : reg2) : (rb[0] ? reg1 : reg0);

// Arithmetic Results
wire [7:0] ratm;
wire [7:0] radc;
wire [7:0] radd;
wire [7:0] rmul;
wire [7:0] rsra;

wire [7:0] rsra1;
wire [7:0] rsra2;
wire [7:0] rsra3;
wire [7:0] rsra4;
wire [7:0] rsra5;
wire [7:0] rsra6;
wire [7:0] rsra7;

wire rbig;

assign rbig = rrb[7] | rrb[6] | rrb[5] | rrb[4] | rrb[3];

assign radc = rra + c;
assign radd = rra + rrb;
assign rmul = rra * rrb;

assign rsra1 = {rra[7], rra[7:1]};
assign rsra2 = {rra[7], rra[7], rra[7:2]};
assign rsra3 = {rra[7], rra[7], rra[7], rra[7:3]};
assign rsra4 = {rra[7], rra[7], rra[7], rra[7], rra[7:4]};
assign rsra5 = {rra[7], rra[7], rra[7], rra[7], rra[7], rra[7:5]};
assign rsra6 = {rra[7], rra[7], rra[7], rra[7], rra[7], rra[7], rra[7:6]};
assign rsra7 = {rra[7], rra[7], rra[7], rra[7], rra[7], rra[7], rra[7], rra[7]};

// Shift Right Arithmetic through a multiplexer
assign rsra = rbig ? 8'b0 : ( rrb[2] ? (rrb[1] ? (rrb[0] ? rsra7 : rsra6) : (rrb[0] ? rsra5 : rsra4)) : (rrb[1] ? (rrb[0] ? rsra3 : rsra2) : (rrb[0] ? rsra1 : rra)));

// Arithmetic Results
assign ratm = opcode[1] ? (opcode[0] ? rsra : rmul) : (opcode[0] ? radd : radc);

// Logic Results
wire [7:0] rlog;
wire [7:0] rand;
wire [7:0] ror;
wire [7:0] rnot;
wire [7:0] rxor;

assign rand = rra & rrb;
assign ror = rra | rrb;
assign rnot = ~rra;
assign rxor = rra ^ rrb;

// Logic Results
assign rlog = opcode[1] ? (opcode[0] ? rxor : rnot) : (opcode[0] ? ror : rand);

// Conditional Results
wire [7:0] rcnd;
wire [7:0] rlt;
wire [7:0] rltc;

assign rlt = rra < rrb;
assign rltc = rra < c;

// Conditional Results
assign rcnd = opcode[0] ? rltc : rlt;

// ALU Result
wire [7:0] res;
assign res = opcode[3] ? (opcode[2] ? rcnd : din) : (opcode[2] ? rlog : ratm);
 
wire jmp;
wire sw;
wire lw;
wire jr;
assign jmp = opcode[3] & opcode[2] & opcode[1] & opcode[0]; // 1111
assign sw = opcode[3] & !opcode[2] & !opcode[1] & opcode[0]; // 1001
assign lw = opcode[3] & !opcode[2] & !opcode[1] & !opcode[0]; // 1000
assign jr = en & (jmp | sw | lw); // enable for address register

wire write_en3, write_en2, write_en1, write_en0;
assign write_en3 = en & rd[1] & rd[0] & !jmp & !sw;
assign write_en2 = en & rd[1] & !rd[0] & !jmp & !sw;
assign write_en1 = en & !rd[1] & rd[0] & !jmp & !sw;
assign write_en0 = en & !rd[1] & !rd[0] & !jmp & !sw;

always @(posedge clk) begin: register3
	if (!rstz) begin// reset
		reg3 <= 8'b0;
	end
	else
		if (write_en3)
			reg3 <= res;
end

always @(posedge clk) begin: register2
	if (!rstz) begin// reset
		reg2 <= 8'b0;
	end
	else
		if (write_en2)
			reg2 <= res;
end

always @(posedge clk) begin: register1
	if (!rstz) begin// reset
		reg1 <= 8'b0;
	end
	else
		if (write_en1)
			reg1 <= res;
end

always @(posedge clk) begin: register0
	if (!rstz) begin// reset
		reg0 <= 8'b0;
	end
	else
		if (write_en0)
			reg0 <= res;
end

assign radr = rstz ? (jr ? radc : 8'h01) : 8'b0;

endmodule
