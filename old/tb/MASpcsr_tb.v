`timescale 1ns / 1ps

module MASpcsr_tb;

wire [7:0] reg3;
wire [7:0] reg2;
wire [7:0] reg1;
wire [7:0] reg0;

reg [15:0] instr;
reg pr;
reg en, rstz, clk;
wire dvdd, dgnd;

MASpcsr uut (
		.reg3(reg3),
		.reg2(reg2),
		.reg1(reg1),
		.reg0(reg0),
		.instr_in(instr),
		.pr(pr),
		.en(en),
		.rstz(rstz),
		.clk(clk),
		.dvdd(dvdd),
		.dgnd(dgnd)	
		);

initial begin

	clk = 0;
	en = 0;
	rstz = 0;
	pr = 0;
	instr = 16'b0;
	#6

	//TEST 1
	$display("Test[1]: ADC R0,R0,3; ADC R1,R1,2; ADD R1,R1,R0");
	en = 1;
	rstz = 1;
	pr = 1;
	#10
	instr = 16'h0003;
	#10
	instr = 16'h0502;
	#10
	instr = 16'h1500;
	#10
	// programming done
	pr = 0; //set mode as run
	#50
	if (reg1 != 8'd5) begin
		$display("reg1 = %d. Expected value was 5!", reg1);
		$finish;
	end
	$display("OKAY!");

	//TEST 2
	$display("Test[2]: MUL R2,R1,R0; ADC R1,R1,-3; SRA R2,R2,R1; AND R0,R2,R1");
	pr = 1;
	instr = 16'h0000;
	#10
	instr = 16'h2900;
	#10
	instr = 16'h05fd;
	#10
	instr = 16'h3a01;
	#10
	instr = 16'h4201;
	#10
	pr = 0; // set mode as run
	#100
	if (reg0 != 8'd2) begin
		$display("reg0 = %d. Expected value was 2!", reg0);
		$finish;
	end
	if (reg1 != 8'd2) begin
		$display("reg1 = %d. Expected value was 2!", reg1);
		$finish;
	end	
	if (reg2 != 8'd3) begin
		$display("reg2 = %d. Expected value was 3!", reg2);
		$finish;
	end
	$display("OKAY!");

	//TEST 3
	$display("Test[3]: Fibonacci Sequence, using JMP, SW and LW instructions");
	en = 0;
	rstz = 0;
	#10
	en = 1;
	rstz = 1;
	pr = 1;
	instr = 16'h0000;
	#10
	instr = 16'h0501; // ADC R1,R1,1
	#10	
	instr = 16'h9700; // SW R1,R3,0
	#10
	instr = 16'h8300; // LW R0,R3,0
	#10
	instr = 16'h9700; // SW R1,R3,0
	#10
	instr = 16'h1500; // ADD R1,R1,R0
	#10
	instr = 16'hd93c; // LTC R2,R1,60
	#10
	instr = 16'h0ff8; // ADC R3,R3,-8
	#10
	instr = 16'h2b02; // MUL R2,R3,R2
	#10
	instr = 16'h0f08; // ADC R3,R3,8
	#10
	instr = 16'hf201; // JMP R2,1	
	#10
	pr = 0;
	#1000
	$display("OKAY!");

	$display("The Unit Under Test passed all proposed functionality tests! Hooray!");
	#10 $finish;
	
end


always #5 clk = ~clk;

endmodule
