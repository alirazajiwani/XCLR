module clock_divider (    
    input  logic clk_in,
    input  logic reset_n,
    output logic clk_out
);
    
    logic [4:0] counter;
    
    always_ff @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= '0;
            clk_out <= 1'b0;
        end
        else begin
            if (counter == 18) begin 
                counter <= '0;
                clk_out <= ~clk_out;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule