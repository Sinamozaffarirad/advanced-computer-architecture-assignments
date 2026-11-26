`define RT 6'b000000
`define addi 6'b000001
`define slti 6'b000010
`define lw 6'b000011
`define sw 6'b000100
`define beq 6'b000101
`define j 6'b000110
`define jal 6'b000111
`define jr 6'b001000
`define ori 6'b001101
`define lui 6'b001111

module controller(
	clk,
	rst,
	opcode,
	func,
	RegDst,
	Jmp,
	DataC,
	Regwrite,
	AluSrc,
	ZeroExtend,
	Branch,
	MemRead,
	MemWrite,
	MemtoReg,
	AluOperation
	);
	input 				clk,rst;
	input      [5:0] 	opcode,func;
	output reg [1:0]	RegDst,Jmp,DataC;
	output reg		    Regwrite,AluSrc,ZeroExtend,Branch,MemRead,MemWrite,MemtoReg;
	output reg [2:0]    AluOperation;

	always@(opcode,func) begin
		    {RegDst,Jmp,DataC,Regwrite,AluSrc,ZeroExtend,Branch,MemRead,MemWrite,MemtoReg,AluOperation}=0;
			case(opcode) 
				`RT: begin
					RegDst=2'b01;
					Regwrite=1;
					// The starter uses function bits [2:0] as its R-type ALU selector.
					AluOperation=func[2:0];
				 end
				`addi: begin
					Regwrite=1;
					AluSrc=1;
					AluOperation=3'b010;
				 end
				`ori: begin
					Regwrite=1;
					AluSrc=1;
					ZeroExtend=1;
					AluOperation=3'b001;
				 end
				`lui: begin
					Regwrite=1;
					DataC=2'b10;
				 end
				`slti: begin
					Regwrite=1;
					AluSrc=1;
					AluOperation=3'b100;
				 end
				`lw: begin
					Regwrite=1;
					AluSrc=1;
					AluOperation=3'b010;
					MemRead=1;
					MemtoReg=1;
				 end
				`sw: begin
					AluSrc=1;
					AluOperation=3'b010;
					MemWrite=1;
				 end
				`beq: begin
					AluOperation=3'b011;
					Branch=1;
				 end
				`j: begin
					Jmp=2'b01;

				 end
				`jal: begin
					RegDst=2'b10;
					DataC=2'b01;
					Regwrite=1;
					Jmp=2'b01;
				 end
				`jr: begin
					Jmp=2'b10;
				 end
			endcase
	end
endmodule
