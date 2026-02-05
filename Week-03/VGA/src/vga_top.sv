module vga_top (
    input  logic CLOCK_50,       
    input  logic reset_n,        
    output logic [7:0] VGA_R,    // VGA Red (8-bit)
    output logic [7:0] VGA_G,    // VGA Green (8-bit)
    output logic [7:0] VGA_B,    // VGA Blue (8-bit)
    output logic VGA_HS,         // VGA H-Sync
    output logic VGA_VS,         // VGA V-Sync
    output logic VGA_CLK,        // VGA Clock
    output logic VGA_BLANK_N,    // VGA Blank
    output logic VGA_SYNC_N      // VGA Sync
);


    // Internal signals
    logic clk_1Mhz;
    logic [9:0] pixel_x;
    logic [8:0] pixel_y;
    logic active_video, active_video_d;
    logic hsync, vsync;
    logic [7:0] red, green, blue;
    

    // Clock Divider
    clock_divider cdiv (
        .clk_in(CLOCK_50),
        .reset_n(reset_n),
        .clk_out(clk_1Mhz)
    );

    // Instantiate VGA timing module
    vga_timing vga_timing_inst (
        .clk(clk_1Mhz),
        .reset_n(reset_n),
        .hsync(hsync),
        .vsync(vsync),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active_video(active_video)
    );


    // SRAM based BRAM
    frame_buffer buffer(
    .clk(clk_1Mhz),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .red(red),
    .green(green), 
    .blue(blue)
    );

    // VGA DAC outputs
    assign VGA_HS = hsync;
    assign VGA_VS = vsync;
    assign VGA_CLK = clk_1Mhz;
    assign VGA_BLANK_N = active_video_d;
    assign VGA_SYNC_N = 1'b0;  // Not used for separate sync


    always_ff @(posedge clk_1Mhz) begin 
        if(!reset_n) begin
            active_video_d <= 0;
        end else begin
            active_video_d <= active_video;
        end
    end

    // Simple test pattern generator
    // Pattern: Color bars or checkerboard
/*
    always_comb begin
        if (active_video_d) begin
            // Vertical color bars (8 bars)
            case (pixel_x[9:7])  // Divide screen into 8 sections
                3'd0: begin red = 8'hFF; green = 8'hFF; blue = 8'hFF; end // White
                3'd1: begin red = 8'hFF; green = 8'hFF; blue = 8'h00; end // Yellow
                3'd2: begin red = 8'h00; green = 8'hFF; blue = 8'hFF; end // Cyan
                3'd3: begin red = 8'h00; green = 8'hFF; blue = 8'h00; end // Green
                3'd4: begin red = 8'hFF; green = 8'h00; blue = 8'hFF; end // Magenta
                3'd5: begin red = 8'hFF; green = 8'h00; blue = 8'h00; end // Red
                3'd6: begin red = 8'h00; green = 8'h00; blue = 8'hFF; end // Blue
                3'd7: begin red = 8'h00; green = 8'h00; blue = 8'h00; end // Black
            endcase
        end else begin
            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00;
        end
    end
*/
    assign VGA_R = (active_video_d)? red : 8'b0;
    assign VGA_G = (active_video_d)? green : 8'b0;
    assign VGA_B = (active_video_d)? blue : 8'b0;

endmodule
