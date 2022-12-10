module CONTROL_UNIT #(parameter RAM_SIZE=16, parameter ROM_SIZE=16)
(
	input clk, rst,
	output [ROM_SIZE-1:0]rom_address,
	input [15:0]instr,
	output reg [RAM_SIZE-1:0] ram_address,
	output reg we,
	input [15:0] ram_in,
	output reg [15:0] ram_out
);

`define INIT 3'b000
`define FETCH 3'b001
`define DECODE 3'b010
`define WAIT 3'b011
`define HLT_STATE 3'b100

	
//puteti lasa MUL, DIV, MOD momentan
	
`define HLT 5'b00000 
	
`define ADD 5'b00001 
`define SUB 5'b00010 
`define LSR 5'b00011 
`define LSL 5'b00100 
`define RSR 5'b00101 
`define RSL 5'b00110 
`define MUL 5'b00111 
`define DIV 5'b01000 
`define MOD 5'b01001 
`define AND 5'b01010 
`define OR  5'b01011 
`define XOR 5'b01100 
`define NOT 5'b01101 
`define CMP 5'b01110 
`define TST 5'b01111 
`define INC 5'b10000 
`define DEC 5'b10001 
	
`define MOV 5'b10010
//le poti lasa pe astea 2 momentan
`define STR 5'b10011
`define LDR 5'b10100
	
`define BRZ 5'b10101
`define BRN 5'b10110
`define BRC 5'b10111
`define BRO 5'b11000
`define BRA 5'b11001

//le poti lasa pe astea 4 momentan
`define PUSH 5'b11010
`define POP  5'b11011
`define JMP  5'b11100 //sau CALL
`define RET  5'b11101

//instructiune pentru INPUT/OUTPUT
//INP -> 111100
//OUT -> 111101
//sintaxa: OUT X/Y, 1/2/3 (dec/hex/bin)
//pentru OUT e simplu, facem un $display("%d/h/b", X/Y);
`define SER 5'b11110
	
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

ALU alu(clk, rst, bgn, opcode, A, B, acc1, acc2, zero, negative, carry, overflow, rdy);

reg [2:0] state, state_next;

always @(posedge clk) begin
	if(rst)
		state <= `INIT;
	else
		state <= state_next;
end

always @(state, rdy) begin
	if(state == `INIT)begin
		state_next = `FETCH;
		PC=0;
		X=0;
		Y=0;
		SP=(2**RAM_SIZE)-1;
		A=0;
		B=0;
		bgn=0;
		ram_address=0;
		we=0;
		ram_out=0;
	end else if(state == `FETCH)begin
		state_next = `DECODE;
	end else if(state == `DECODE) begin
		state_next = `WAIT;
		bgn = 1'b0;
		case(opcode[5:1])
		//TOOD tratam toate cazurile
		//TODO tratam opcode
		`ADD, `SUB, `LSR, `LSL, `RSR, `RSL, `MUL, `DIV, `MOD, `AND, `OR, `XOR, `NOT, `CMP, `TST, `INC, `DEC, `LDR: begin
			if(r)
				A=Y;
			else
				A=X;
			if(~opcode[0])
				B=imm;
			else
				if(imm)
					B=Y;
				else
					B=X;
			bgn = 1'b1;
			state_next = `WAIT;
		end
		`MOV: begin 
			if(opcode[0])
				if(r)
					Y=X;
				else 
					X=Y;
			else
				if(r)
					Y=imm;
				else
					X=imm;
			bgn = 1'b0;
			state_next = `FETCH;
			PC=PC+1;
		end
		`STR: begin
			if(opcode[0])
				if(imm)
					ram_address=Y;
				else 
					ram_address=X;
			else
				ram_address=imm;
				if(r)
					ram_out=Y;
				else
					ram_out=X;
			bgn = 1'b0;
			state_next = `FETCH;
			PC=PC+1;
		end
		`NOP: begin
			bgn = 1'b1;
			state_next = `WAIT;
		end
		`SER: begin
			if(opcode[0])begin
				if(r)begin
					if(imm==1)
						$display("Y=%d", Y);
					else if(imm==2)
						$display("Y=%h", Y);
					else if(imm==3)
						$display("Y=%b", Y);
				end else begin
					if(imm==1)
						$display("X=%d", X);
					else if(imm==2)
						$display("X=%h", X);
					else if(imm==3)
						$display("X=%b", X);
				end
			end
			bgn = 1'b0;
			state_next = `FETCH;
			PC=PC+1;
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
		`BRN: begin
			if(negative) begin
				PC = br_address;
				state_next = `FETCH;
			end else begin
				PC = PC + 1;
				state_next = `FETCH;
			end
		end
		`BRC: begin
			if(carry) begin
				PC = br_address;
				state_next = `FETCH;
			end else begin
				PC = PC + 1;
				state_next = `FETCH;
			end
		end
		`BRO: begin
			if(overflow) begin
				PC = br_address;
				state_next = `FETCH;
			end else begin
				PC = PC + 1;
				state_next = `FETCH;
			end
		end
		`BRA: begin
				PC = br_address;
				state_next = `FETCH;
		end
		`HLT: begin
				state_next = `HLT_STATE;
		end
		default: state_next = `HLT_STATE;
		//daca avem ALU, facem state_next = `WAIT, altfel `FETCH
		endcase
	end else if(state == `WAIT) begin //stare pentru ALU
		state_next = `WAIT;
		if(rdy) begin
			case(opcode[5:1])
			`ADD, `SUB, `LSR, `LSL, `RSR, `RSL, `MOD, `AND, `OR, `XOR, `NOT, `CMP, `TST, `INC, `DEC, `MUL, `DIV: begin
			if(r)
				Y=acc1;
			else 
				X=acc1;
			end
			// `LDR: begin
			// //implement LDR
			// end
			endcase
			//TODO salvare valori din alu in registrii
			//adica X/Y=acc1/acc2, in functie de opcode
			bgn = 1'b0;
			state_next = `FETCH;
			PC = PC + 1;
		end
	end
	else
		state_next = `HLT_STATE;
end

endmodule
