`define RT 6'b000000
`define addi 6'b000001
`define slti 6'b000010
`define lw 6'b000011
`define sw 6'b000100
`define beq 6'b000101
`define j 6'b000110
`define jal 6'b000111
`define jr 6'b001000

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
	Branch,
	MemRead,
	MemWrite,
	MemtoReg,
	AluOperation
	);
	input 				clk,rst;
	input      [5:0] 	opcode,func;
	output reg [1:0]	RegDst,Jmp;
	output reg		    DataC,Regwrite,AluSrc,Branch,MemRead,MemWrite,MemtoReg;
	output reg [2:0]    AluOperation;

	always@(opcode,func) begin
		    {RegDst,Jmp,DataC,Regwrite,AluSrc,Branch,MemRead,MemWrite,MemtoReg,AluOperation}=0;
			case(opcode) 
				`RT: begin
					RegDst=2'b01;
					Regwrite=1;
					AluOperation=func[2:0];
				 end
				`addi: begin
					Regwrite=1;
					AluSrc=1;
					AluOperation=3'b010;
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
					DataC=1;
					Regwrite=1;
					Jmp=2'b01;
				 end
				`jr: begin
					Jmp=2'b10;
				 end
			endcase
	end
endmodule
