module encoder_tb;

	logic [7:0] in;
	logic [2:0] out;

	bit [2:0] expected;

	int pass = 0;
	int fail = 0;

	encoder_8to3 dut (
		.in(in),
		.out(out)
	);

	task check;
		begin
			if (out === expected) begin
				pass++;
				$display("PASS: in=%b | out=%0d | exp=%0d", in, out, expected);
			end
			else begin
				fail++;
				$display("FAIL: in=%b | out=%0d | exp=%0d", in, out, expected);
			end
		end
	endtask

	initial begin
		for (int i = 0; i < 8; i++) begin
			in = 8'b1 << i;
			expected = i[2:0];
			#1;
			check();
		end

		repeat (3) begin
			in = $random;
			expected = 0;
			for (int i = 7; i >= 0; i--)
				if (in[i]) begin
					expected = i[2:0];
					break;
				end
			#1;
			check();
		end

		$display("Encoder Test Summary: PASS=%0d FAIL=%0d", pass, fail);
		$finish;
	end

endmodule

