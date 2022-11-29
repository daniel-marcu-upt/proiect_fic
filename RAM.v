module RAM #(parameter N=16) (
	input clk, we,
	input [N-1:0] address,
	input [15:0] in,
	output reg [15:0] out
);
	reg [15:0] ram [(2**N)-1:0] ;
	always @(clk) begin
		if(we)
			ram[address] = in;
		out = ram[address];
	end

endmodule
