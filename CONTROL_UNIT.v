module CONTROL_UNIT #(parameter RAM_SIZE=16, parameter ROM_SIZE=16)
(
	input clk, rst,
	output [ROM_SIZE-1:0]rom_address,
	input [15:0]instr,
	output reg [RAM_SIZE-1:0] ram_address,
	output reg we,
	input [15:0] ram_in,
	output [15:0] ram_out
);

`define FETCH 2'b00
`define DECODE 2'b01
`define WAIT 2'b10
`define HLT_STATE 2'b11

`define BRZ 5'b11001
`define BRN 5'b11010
`define BRC 5'b11011
`define BRO 5'b11100
`define BRA 5'b11000

//le poti lasa pe astea 4 momentan
`define PUSH 5'b11000
`define POP  5'b10001
`define JMP  5'b10010 //sau CALL
`define RET  5'b10011

`define MOV 5'b01100
//le poti lasa pe astea 2 momentan
`define STR 5'b01101
`define LDR 5'b01110

//puteti lasa MUL, DIV, MOD momentan
`define ADD 5'b00001 
`define SUB 5'b00010 
`define LSR 5'b00011 
`define LSL 5'b00100 
`define RSR 5'b00101 
`define RSL 5'b00110 
`define MOV 5'b00111 
`define MUL 5'b01000 
`define DIV 5'b01001 
`define MOD 5'b01010 
`define AND 5'b01011 
`define OR  5'b01100 
`define XOR 5'b01101 
`define NOT 5'b01110 
`define CMP 5'b01111 
`define TST 5'b10000 
`define INC 5'b10001 
`define DEC 5'b10010 
`define HLT 5'b00000 
`define NOP 5'b11111 


wire [15:0] acc1, acc2; //registru accumulator
reg [15:0] A, B; //input ALU
wire zero, negative, carry, overflow; //flag
wire rdy; //semnal rdy (ALU il pune pe 1 atunci cand e gata operatia)
reg bgn;

reg [15:0] X, Y; //registrii general use
reg [15:0] PC; // PC ia din ROM
reg [15:0] SP; // SP ia din RAM

wire [5:0] opcode; //opcode
wire r;
wire [8:0] imm;
wire [9:0] br_address;

assign opcode = instr[15:10]; // opcode este mereu ultimii 6 biti din instructiune
assign r = instr[10:9]; //registrul cu care lucram
assign imm = instr[8:0]; // valoarea imediata
assign br_address = instr[9:0]; // adresa de jump

assign rom_address = PC;

ALU alu(clk, bgn, opcode, A, B, acc1, acc2, zero, negative, carry, overflow, rdy);

reg [2:0] state, state_next;

always @(posedge clk) begin
	if(rst) begin
		state <= `FETCH;
	end else
		state <= state_next;
end

always @(state) begin
	if(state == `FETCH)begin
		state_next = `DECODE;
	end else if(state == `DECODE) begin
		state_next = `WAIT;
		case(opcode[5:1])
		//TOOD tratam toate cazurile
		//TODO tratam opcode
		`ADD: begin
			A=X;
			if(opcode[0])
				B=imm;
			else
				B=Y;
			bgn = 1'b1;
			state_next = `WAIT;
		end
		`BRZ: begin
			if(zero) begin
				PC = br_address;
				state_next = `FETCH;
			end else begin
				PC = PC + 1;
				state_next = `FETCH;
			end
		end
		default: X=X;
		//daca avem ALU, facem state_next = `WAIT, altfel `FETCH
		endcase
	end else if(state == `WAIT) begin //stare pentru ALU
		state_next = `WAIT;
		if(rdy) begin
			bgn = 1'b0;
			state_next = `FETCH;
			PC = PC + 1;
		end
	end
end

endmodule
