module Multiplier8x8(
	input logic clk, EA, EB, rst,
	input logic [7:0] A, B,
	output logic [15:0] P
);
logic [7:0] A_out, B_out;
logic [15:0] P_out;

ff#(8) ff1(.clk(clk),.reset(rst),.enable(EA),.d(A),.q(A_out));
ff#(8) ff2(.clk(clk),.reset(rst),.enable(EB),.d(B),.q(B_out));
ff#(16) ff3(.clk(clk),.reset(rst),.enable(1),.d(P_out),.q(P));

Multiplier M1(.a(A_out),.b(B_out),.p(P_out));

endmodule


module ff#(parameter N)(
	input logic clk, reset, enable, 
	input logic [N-1:0] d,
	output logic [N-1:0] q
);

always @(posedge clk) begin
	if (reset) q <= 0;
	else q <= (enable)? d : q;
end


endmodule

module Multiplier(
	input  logic [7:0]  a,
	input  logic [7:0]  b,
	output logic [15:0] p
);

logic [7:0] pp [7:0];     // partial products
logic [15:0] sum [7:0];  // intermediate sums
logic [7:0] carry;       // carries between stages

genvar i;

// Generate partial products
generate
	for (i = 0; i < 8; i++) begin : GEN_PP
		AND_chain #(8) ands (
			.a(a),
			.b(b[i]),
			.z(pp[i])
		);
	end
endgenerate


// First row (no addition)
assign sum[0] = {8'b0, pp[0]};


// Array of ripple adders
generate
	for (i = 1; i < 8; i++) begin : GEN_ADD
		RCA #(16) rcas (
			.a(sum[i-1]),
			.b({pp[i], {i{1'b0}}}),
			.cin(1'b0),
			.s(sum[i]),
			.cout(carry[i])
		);
	end
endgenerate

// Final product
assign p = sum[7];

endmodule


module RCA #(parameter N = 8)(
	input  logic [N-1:0] a,
	input  logic [N-1:0] b,
	input  logic         cin,
	output logic [N-1:0] s,
	output logic         cout
);

logic [N:0] c;
assign c[0] = cin;

genvar i;
generate
	for (i = 0; i < N; i++) begin : GEN_FA
		FA fa (
			.a(a[i]),
			.b(b[i]),
			.cin(c[i]),
			.s(s[i]),
			.cout(c[i+1])
		);
	end
endgenerate

assign cout = c[N];

endmodule


module AND_chain #(parameter N = 8)(
	input  logic [N-1:0] a,
	input  logic b,
	output logic [N-1:0] z
);
assign z = a & {N{b}};
endmodule


module FA (
	input  logic a,
	input  logic b,
	input  logic cin,
	output logic s,
	output logic cout
);
assign s = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a ^ b));
endmodule
