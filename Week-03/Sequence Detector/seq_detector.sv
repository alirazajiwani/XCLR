module seq_detector(
	input logic clk,rst_n,in_bit,
	output logic seq_detected
);

typedef enum logic [2:0] {
	S0, S1, S2, S3, S4
}state;

state CS, NS;

always @(posedge clk) begin
	if (!rst_n) CS <= S0;
	else CS <= NS;
end

always_comb begin
	case (CS)
		S0: NS = (in_bit)? S1 : S0;
		S1: NS = (in_bit)? S1 : S2;  
		S2: NS = (in_bit)? S3 : S0;
		S3: NS = (in_bit)? S4 : S2;
		S4: NS = (in_bit)? S1 : S2;
		default: NS = S0;
	endcase
end

always_comb begin
	case (CS)
		S0,S1,S2,S3: seq_detected = 0;
		S4: seq_detected = 1;
		default: seq_detected = 0;
	endcase
end
endmodule