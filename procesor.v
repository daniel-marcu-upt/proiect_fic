module procesor #(parameter RAM_SIZE=16, parameter ROM_SIZE=8)(
	input clk, rst,
	input [15:0] data_in,
	output [15:0] data_out
);
wire [15:0] instr;
wire [ROM_SIZE-1:0] rom_addr;
wire [RAM_SIZE-1:0] ram_addr;
wire [15:0] ram_in, ram_out;

ROM #(ROM_SIZE) rom (clk, rst, rom_addr, instr);
RAM #(RAM_SIZE) ram (clk, we, ram_addr, ram_in, ram_out);
CONTROL_UNIT #(RAM_SIZE, ROM_SIZE) control_unit(clk, rst, rom_addr, instr, ram_addr, we, ram_out, ram_in);

endmodule




module tb;

	reg clk, rst;
	reg [15:0]data_in;
	wire [15:0]data_out;
	procesor p(clk, rst, data_in, data_out);

	initial begin
		clk=0;
		rst=1;
		#100;
		rst=0;
	end
	initial
		forever begin
			#50;
			clk=~clk;
		end
	
endmodule
