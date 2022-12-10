module ROM #(parameter N=16)(
	input clk, rst,
	input [N-1:0] address,
	output reg [15:0] data
);
	reg [15:0] rom [0:(2**N)-1];
	
   initial begin
	      $readmemh("C:\\Users\\d\\Documents\\poli\\proiect_fic\\instructions.mem", rom);

	end
		

   always @(posedge clk) begin
		if(rst) begin
			data <= rom[0];
		end else
			data <= rom[address];
	end
		
		
endmodule
