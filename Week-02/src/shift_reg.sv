module shift_reg#(parameter N = 8)(
	input logic clk, rst_n, shift_en, dir, d_in,  //dir = 0 (left), dir = 1 (right)
	output logic [N-1:0] q_out
);


always @ (posedge clk) begin
	if (!rst_n) q_out <= 0;
	else begin
		if (shift_en) q_out <= (dir)? {d_in , q_out[N-1:1]} : {q_out[N-2:0], d_in} ;  
	end
end

endmodule 
