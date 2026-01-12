module reg32_tb();
logic clk, rst_n, load;
logic [31:0] d;
logic [31:0] q;

// DUT Insantiation

reg32 dut (
	.clk(clk),
	.rst_n(rst_n),
	.load(load),
	.d(d),
	.q(q)
);

// Clock Generation

always #10 clk = ~clk;


// Stimulus

initial begin
	clk = 0;
	rst_n = 0;
	load = 0;
	d = 0;
	
	#10;
	rst_n = 1;
	load = 1;
	
	
	repeat (2) begin
		@(negedge clk);
		d = $random;
	end
	
	#20;
	rst_n = 1;
	
	repeat (2) begin
		@(negedge clk);
		d = $random;
	end
	
	
	#50;
	$finish;
end


// RESET ASSERTION 
property reset_clears_q; 
	@(posedge clk) (!rst_n) |=> (q == 0);  
endproperty 

assert property (reset_clears_q) 
	else $error("RESET FAILED: q != 0 at time %0t", $time); 
	
//LOAD ASSERTION 
property load_check; 
	@(posedge clk) (rst_n && load) |=> (q == $past(d)); 
endproperty 

assert property (load_check) 
	else $error("LOAD FAILED: q != d at time %0t", $time); 

// HOLD ASSERTION  
property hold_check; 
	@(posedge clk) (rst_n && !load) |=> (q == $past(d)); 
endproperty 

assert property (hold_check) 
	else $error("HOLD FAILED: q(t)!= q(t-1) at time %0t", $time);

endmodule