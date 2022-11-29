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


`define NOP 6'd0
`define ADD 6'd1
`define SUB 6'd2
`define SHL 6'd3
`define BRZ 6'd5

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
		case(opcode)
		//TOOD tratam toate cazurile
		//TODO tratam opcode
		`ADD: begin
			A=X;
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
