module adder32(
	input logic [31:0] a, b, 
	input logic cin,
	output logic [31:0] s,
	output logic cout
);

assign {cout,s} = a + b + cin;

endmodule



