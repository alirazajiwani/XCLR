module barrel_shifter(
	input  logic [31:0] data_in,
	input  logic [4:0]  shift_amt,
	input  logic        dir,       // 0 = left, 1 = right
	output logic [31:0] data_out
);

	logic [31:0] s1, s2, s4, s8, s16;

	always_comb begin
		// shift by 1
		if (!dir)
			s1 = shift_amt[0] ? {data_in[30:0], 1'b0} : data_in;
		else
			s1 = shift_amt[0] ? {1'b0, data_in[31:1]} : data_in;

		// shift by 2
		if (!dir)
			s2 = shift_amt[1] ? {s1[29:0], 2'b0} : s1;
		else
			s2 = shift_amt[1] ? {2'b0, s1[31:2]} : s1;

		// shift by 4
		if (!dir)
			s4 = shift_amt[2] ? {s2[27:0], 4'b0} : s2;
		else
			s4 = shift_amt[2] ? {4'b0, s2[31:4]} : s2;

		// shift by 8
		if (!dir)
			s8 = shift_amt[3] ? {s4[23:0], 8'b0} : s4;
		else
			s8 = shift_amt[3] ? {8'b0, s4[31:8]} : s4;

		// shift by 16
		if (!dir)
			s16 = shift_amt[4] ? {s8[15:0], 16'b0} : s8;
		else
			s16 = shift_amt[4] ? {16'b0, s8[31:16]} : s8;

		data_out = s16;
	end

endmodule

