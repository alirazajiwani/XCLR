module frame_buffer (
    input logic clk,
    input logic [9:0] pixel_x,  // 0-159 used
    input logic [8:0] pixel_y,   // 0-99 used
    output logic [7:0] red, green, blue
);
    logic [23:0] frame [0:15999];
    logic [13:0] addr;
    logic [23:0] pixel;
    
    initial begin
        $readmemh("SourceImage.hex", frame);
    end
    
    assign addr = (pixel_y * 160) + pixel_x;
    
    always_ff @(posedge clk) begin
        pixel <= frame[addr];
    end
    
    assign red   = pixel[23:16];
    assign green = pixel[15:8];
    assign blue  = pixel[7:0];
endmodule