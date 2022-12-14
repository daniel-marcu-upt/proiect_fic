`define INIT 8'd0
`define LOAD 8'd1
`define WAIT 8'd2 

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
`define NOP 5'b11111

module ALU (
            input clk,
				input rst,
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
	 wire [15:0] x, y;
    
    ALU_H al(op, a, b, x, y, zero, negative, carry, overflow, r);
    
    always @(posedge clk) begin
		 if(rst)begin 
			state <= `INIT;
		 end else begin
         state <= state_next;
	    end
    end
    
    always @(state, opcode, bgn, r) begin
		  if(state == `INIT)begin
				op=0;
				a=0;
				b=0;
				acc1=0;
				acc2=0;
				rdy=0;
				state_next = `LOAD;
        end else if(state == `LOAD) begin
            if(bgn) begin
					 acc1=0;
					 acc2=0;
                rdy = 1'b0;
                a=A;
                b=B;
                op=opcode;
                state_next = `WAIT;
            end
        end else if(state == `WAIT) begin
            if(r) begin
                acc1=x;
                acc2=y;
                state_next = `LOAD;
                rdy = 1'b1;
                op={`NOP, 1'b0};
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
    integer i;
    always @(opcode) begin
        rdy=0;
        case (opcode[5:1])
            `ADD: begin 
                X=A+B;
                rdy=1'b1;
            end
            `SUB: begin 
                X=A-B;
                rdy=1'b1;
            end
            `MUL: begin 
		            {Y, X}=A*B;
                rdy=1'b1;
            end
            `DIV: begin 
                X=A/B;
		            Y=A%B;
                rdy=1'b1;
            end
            `MOD: begin 
                Y=A/B;
		            X=A%B;
                rdy=1'b1;
            end
            `LSR: begin
                X=A>>B;
                rdy=1'b1;
            end
            `LSL: begin
                X=A<<B;
                rdy=1'b1;
            end
            `RSR: begin
					X=A;
					for(i=0; i<16;i=i+1)begin
						if(i<B)
                    X={X[0],X[15:1]};
						else
							X=X;
					end
               rdy=1'b1;
            end
            `RSL: begin
					X=A;
					for(i=0; i<16;i=i+1)begin
						if(i<B)
                    X={X[14:0],X[15]};
						else
							X=X;
					end                    
               rdy=1'b1;
            end
            `AND: begin
                X=A&B;
                rdy=1'b1;
            end
            `OR: begin
                X=A|B;
                rdy=1'b1;
            end
            `XOR: begin
                X=A^B;
                rdy=1'b1;
            end
            `NOT: begin
                X=~A;
                rdy=1'b1;
            end
            `CMP: begin
                X=A-B;
                rdy=1'b1;
            end
            `TST: begin
                X=A&B;
                rdy=1'b1;
            end
            `INC: begin
                X=A+1;
                rdy=1'b1;
            end
            `DEC: begin
                X=A-1;
                rdy=1'b1;
            end
            `NOP: rdy=1'b1;
        endcase
    end

    assign carry=(A < B);
    assign overflow=(B < A);
    assign zero=(X == 0) & (Y == 0);
    assign negative=(X[15] & (Y == 0)) | (Y[15]);

endmodule
