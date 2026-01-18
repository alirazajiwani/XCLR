module barrel_shifter_tb;

	logic [31:0] data_in;
	logic [4:0]  shift_amt;
	logic        dir;
	logic [31:0] data_out;

	bit [31:0] expected;

	int pass = 0;
	int fail = 0;

	barrel_shifter dut (
		.data_in(data_in),
		.shift_amt(shift_amt),
		.dir(dir),
		.data_out(data_out)
	);

	task check;
		begin
			if (data_out === expected) begin
				pass++;
				$display("PASS: data=%h shift=%0d dir=%b | out=%h | exp=%h",
				         data_in, shift_amt, dir, data_out, expected);
			end
			else begin
				fail++;
				$display("FAIL: data=%h shift=%0d dir=%b | out=%h | exp=%h",
				         data_in, shift_amt, dir, data_out, expected);
			end
		end
	endtask

	initial begin
		data_in = 32'hA5A5A5A5;

		for (int i = 0; i < 32; i++) begin
			shift_amt = i;
			dir = 0;
			expected = data_in << i;
			#1;
			check();

			dir = 1;
			expected = data_in >> i;
			#1;
			check();
		end

		repeat (3) begin
			data_in   = $random;
			shift_amt = $random;
			dir       = $random;
			#1;
			expected = dir ? (data_in >> shift_amt) : (data_in << shift_amt);
			check();
		end

		$display("Barrel Shifter Test Summary: PASS=%0d FAIL=%0d", pass, fail);
		$finish;
	end

endmodule

