module counter#( parameter N = 8)(
	input logic clk, rst_n, en, up_dn, //up = 1, dn = 0
	output logic [N-1:0] count
);


always @ (posedge clk) begin
	if (!rst_n) count <= 0;
	else begin
		if (en) count <= (up_dn)? (count + 1) : (count - 1); 
	end
end

endmodule 
