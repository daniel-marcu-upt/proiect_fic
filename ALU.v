
`define INIT 8'd0
`define WAIT 8'd1 


`define NOP 6'd0
`define ADD 6'd1
`define SUB 6'd2
`define SHL 6'd3

module ALU (input clk, 
	input bgn,
	input [5:0] opcode,
	input [15:0] A, B,
	output reg [15:0] acc1, acc2,
	output zero, negative, carry, overflow,
	output reg rdy
);
	reg [7:0] state, state_next;
	reg [5:0] op;
	reg [15:0] a, b;
	
	ALU_H al(op, a, b, X, Y, zero, negative, carry, overflow, r);
	
	always @(posedge clk) begin
		state <= state_next;
	end
	
	always @(state, opcode) begin
		if(state == `INIT) begin
			if(bgn) begin
				rdy = 1'b0;
				a=A;
				b=B;
				op=opcode;
				state_next = `WAIT;
			end
		end else if(state == `WAIT) begin
			if(r) begin
				acc1=X;
				acc2=Y;
				state_next = `INIT;
				rdy = 1'b1;
				op=0;
			end
		end	
	end
	
endmodule



module ALU_H (
	input [5:0] opcode,
	input [15:0] A, B,
	output reg [15:0] X, Y,
	output zero, negative, carry, overflow,
	output reg rdy
);

	always @(opcode) begin
		rdy=0;
		case (opcode)
			//TODO tratam opcode
			`NOP: rdy=1'b1;
			`ADD: begin 
				X=A+B;
				rdy=1'b1;
			end
			`SUB: begin 
				X=A-B;
				rdy=1'b1;
			end
			`SHL: begin
				X=A<<B;
				rdy=1'b1;
			end
		endcase
	end

assign carry=(A<B);
assign overflow=(B<A);
assign zero = (X==0) & (Y==0);
assign negative = (X[7] & (Y==0)) | (Y[7]);

endmodule
