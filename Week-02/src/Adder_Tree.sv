module Adder_Tree (
	input logic clk, reset,
	input logic [7:0] A, B,
	output logic [15:0] P
);

// Input Register

logic [7:0] a, b;

always_ff @ (posedge clk) begin	
	if (reset) begin
		a <= 0;
		b <= 0;
	end
	else begin
		a <= A;
		b <= B;
	end
end

// Partial Products

logic [15:0] pp [7:0];
logic [15:0] a_ext;
genvar i;

assign  a_ext = {8'b0, a};

generate
	for (i = 0 ; i < 8 ; i ++) begin : partialproducts
		assign pp[i] = b[i]? (a_ext << i) : 16'b0;
	end
endgenerate

// Adder Tree 

// Level 1(8->4)
logic [15:0] s1 [3:0];

generate
	for (i = 0 ; i < 8 ; i = i + 2) begin : level1
		assign s1[i/2] = pp[i]+pp[i+1];
	end
endgenerate

// Level 2(4->2)
logic [15:0] s2 [1:0];

generate
	for (i = 0 ; i < 4 ; i = i + 2) begin : level2
		assign s2[i/2] = s1[i]+s1[i+1];
	end
endgenerate

// Level 3(2->1)
logic [15:0] p;

assign p = s2[0] + s2[1];

// Output Register

always_ff @ (posedge clk) begin	
	if (reset) P <= 0;
	else P <= p;
end

endmodule 