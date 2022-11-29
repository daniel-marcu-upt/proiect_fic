module ROM #(parameter N=16)(
	input clk, rst,
	input [15:0] address,
	output reg [15:0] data
);
	reg [15:0] rom [(2**N)-1:0];
	
   initial begin
      //$readmemh("instructions.mem", rom, 0, (2**N)-1);
	end
		

   always @(posedge clk) begin
		if(rst) begin
			//$readmemh("instructions.mem", rom, 0, (2**N)-1);
		end else
			data <= rom[address];
	end
		
		

endmodule
