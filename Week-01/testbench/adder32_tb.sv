module adder32_tb;

	logic [31:0] a, b;
	logic        cin;
	logic [31:0] s;
	logic        cout;
	bit [32:0] expected;

	int pass = 0;
	int fail = 0;

	adder32 dut (
		.a(a),
		.b(b),
		.cin(cin),
		.s(s),
		.cout(cout)
	);

	task check;
		begin
			expected = a + b + cin;
			if ({cout, s} === expected) begin
				pass++;
				$display("PASS: a=%h b=%h cin=%b | s=%h cout=%b | exp=%h",
				         a, b, cin, s, cout, expected);
			end else begin
				fail++;
				$display("FAIL: a=%h b=%h cin=%b | s=%h cout=%b | exp=%h",
				         a, b, cin, s, cout, expected);
			end
		end
	endtask

	initial begin
		a = 0; b = 0; cin = 0; #1; check();
		a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; cin = 0; #1; check();
		a = 32'hFFFFFFFF; b = 1; cin = 0; #1; check();
		a = 32'h80000000; b = 32'h80000000; cin = 0; #1; check();

		repeat (3) begin
			a   = $random;
			b   = $random;
			cin = $random;
			#1;
			check();
		end

		$display("Adder Test Summary: PASS=%0d FAIL=%0d", pass, fail);
		$finish;
	end

endmodule

