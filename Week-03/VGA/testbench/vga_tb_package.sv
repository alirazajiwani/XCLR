interface vga_if (
    input logic CLOCK_50
);
    logic reset_n;
    logic [7:0] VGA_R;
    logic [7:0] VGA_G;
    logic [7:0] VGA_B;
    logic VGA_HS;
    logic VGA_VS;
    logic VGA_CLK;
    logic VGA_BLANK_N;
    logic VGA_SYNC_N;

    // Modport for DUT
    modport dut (
        input CLOCK_50, reset_n,
        output VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, 
               VGA_CLK, VGA_BLANK_N, VGA_SYNC_N
    );

    // Modport for testbench
    modport tb (
        output reset_n,
        input VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS,
              VGA_CLK, VGA_BLANK_N, VGA_SYNC_N,
        input CLOCK_50
    );

endinterface



package vga_tb_package;

// =============================================================================
// CONFIGURATION CLASS
// =============================================================================
class vga_config;
    // VGA timing parameters (160x100 @60Hz)
    int H_A  = 160;   // Horizontal active
    int H_FP = 8;     // Horizontal front porch
    int H_S  = 8;     // Horizontal sync
    int H_BP = 16;    // Horizontal back porch
    
    int V_A  = 100;   // Vertical active
    int V_FP = 3;     // Vertical front porch
    int V_S  = 6;     // Vertical sync
    int V_BP = 6;     // Vertical back porch
    
    int H_TOTAL;
    int V_TOTAL;
    int TOTAL_PIXELS;
    
    function new();
        H_TOTAL = H_A + H_FP + H_S + H_BP;
        V_TOTAL = V_A + V_FP + V_S + V_BP;
        TOTAL_PIXELS = H_TOTAL * V_TOTAL;
    endfunction
    
    function void display();
        $display("========================================");
        $display("VGA Configuration:");
        $display("  Resolution: %0dx%0d", H_A, V_A);
        $display("  H_Total: %0d, V_Total: %0d", H_TOTAL, V_TOTAL);
        $display("  Total Pixels per Frame: %0d", TOTAL_PIXELS);
        $display("========================================");
    endfunction
endclass

// =============================================================================
// TRANSACTION CLASS
// =============================================================================
class vga_transaction;
    vga_config cfg;
    
    // Pixel data
    logic [9:0] pixel_x;
    logic [8:0] pixel_y;
    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;
    
    // Timing signals
    logic hsync;
    logic vsync;
    logic active_video;
    logic blank_n;
    
    // Frame tracking
    int frame_number;
    bit is_active_region;
    
    function void display(string tag);
        $display("[%0t][%s]: Frame=%0d, Pos(%0d,%0d), RGB(0x%02h,0x%02h,0x%02h), HS=%0b, VS=%0b, Active=%0b", 
            $time, tag, frame_number, pixel_x, pixel_y, red, green, blue, hsync, vsync, active_video);
    endfunction
    
    function bit compare_pixel(vga_transaction tr);
        return (this.red == tr.red && 
                this.green == tr.green && 
                this.blue == tr.blue);
    endfunction
    
endclass

// =============================================================================
// REFERENCE MODEL
// =============================================================================
class vga_reference_model;
    vga_config cfg;
    logic [23:0] frame_buffer [0:15999];
    
    function new(vga_config cfg);
        this.cfg = cfg;
        // Load the same image that the DUT uses
        $readmemh("SourceImage.hex", frame_buffer);
    endfunction
    
    function void get_expected_pixel(input logic [9:0] x, input logic [8:0] y, 
                                      output logic [7:0] r, g, b);
        logic [13:0] addr;
        logic [23:0] pixel;
        
        if (x < cfg.H_A && y < cfg.V_A) begin
            addr = (y * 160) + x;
            pixel = frame_buffer[addr];
            r = pixel[23:16];
            g = pixel[15:8];
            b = pixel[7:0];
        end else begin
            r = 8'h00;
            g = 8'h00;
            b = 8'h00;
        end
    endfunction
    
endclass

// =============================================================================
// COVERAGE CLASS
// =============================================================================
class vga_coverage;
    vga_config cfg;
    vga_transaction tr;
    
    // Coverage groups
    covergroup timing_cg;
        // Horizontal sync coverage
        cp_hsync: coverpoint tr.hsync {
            bins low = {0};
            bins high = {1};
        }
        
        // Vertical sync coverage
        cp_vsync: coverpoint tr.vsync {
            bins low = {0};
            bins high = {1};
        }
        
        // Active video coverage
        cp_active: coverpoint tr.active_video {
            bins inactive = {0};
            bins active = {1};
        }
        
        // Sync states
        cross_sync: cross cp_hsync, cp_vsync {
            bins both_high = binsof(cp_hsync.high) && binsof(cp_vsync.high);
            bins both_low = binsof(cp_hsync.low) && binsof(cp_vsync.low);
            bins hsync_only = binsof(cp_hsync.low) && binsof(cp_vsync.high);
            bins vsync_only = binsof(cp_hsync.high) && binsof(cp_vsync.low);
        }
    endgroup
    
    covergroup pixel_position_cg;
        // Horizontal position coverage
        cp_x_pos: coverpoint tr.pixel_x {
            bins left_edge = {[0:9]};
            bins left_region = {[10:39]};
            bins center = {[40:119]};
            bins right_region = {[120:149]};
            bins right_edge = {[150:159]};
        }
        
        // Vertical position coverage
        cp_y_pos: coverpoint tr.pixel_y {
            bins top_edge = {[0:9]};
            bins top_region = {[10:29]};
            bins middle = {[30:69]};
            bins bottom_region = {[70:89]};
            bins bottom_edge = {[90:99]};
        }
        
        // Corner coverage
        cross_corners: cross cp_x_pos, cp_y_pos {
            bins top_left = binsof(cp_x_pos.left_edge) && binsof(cp_y_pos.top_edge);
            bins top_right = binsof(cp_x_pos.right_edge) && binsof(cp_y_pos.top_edge);
            bins bottom_left = binsof(cp_x_pos.left_edge) && binsof(cp_y_pos.bottom_edge);
            bins bottom_right = binsof(cp_x_pos.right_edge) && binsof(cp_y_pos.bottom_edge);
        }
    endgroup
    
    covergroup color_cg;
        // Red channel coverage
        cp_red: coverpoint tr.red {
            bins black = {8'h00};
            bins dark = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins bright = {[8'hC0:8'hFE]};
            bins full = {8'hFF};
        }
        
        // Green channel coverage
        cp_green: coverpoint tr.green {
            bins black = {8'h00};
            bins dark = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins bright = {[8'hC0:8'hFE]};
            bins full = {8'hFF};
        }
        
        // Blue channel coverage
        cp_blue: coverpoint tr.blue {
            bins black = {8'h00};
            bins dark = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins bright = {[8'hC0:8'hFE]};
            bins full = {8'hFF};
        }
        
        // Color combinations
        cross_colors: cross cp_red, cp_green, cp_blue {
            ignore_bins ignore_black = binsof(cp_red.black) && binsof(cp_green.black) && binsof(cp_blue.black);
            ignore_bins ignore_white = binsof(cp_red.full) && binsof(cp_green.full) && binsof(cp_blue.full);
        }
    endgroup
    
    covergroup frame_cg;
        cp_frame: coverpoint tr.frame_number {
            bins first = {0};
            bins second = {1};
            bins third = {2};
            bins fourth_plus = {[3:$]};
        }
    endgroup
    
    function new(vga_config cfg);
        this.cfg = cfg;
        timing_cg = new();
        pixel_position_cg = new();
        color_cg = new();
        frame_cg = new();
    endfunction
    
    function void sample(vga_transaction t);
        this.tr = t;
        timing_cg.sample();
        if (tr.active_video) begin
            pixel_position_cg.sample();
            color_cg.sample();
        end
        frame_cg.sample();
    endfunction
    
    function void report();
        real timing_cov, pixel_cov, color_cov, frame_cov, total_cov;
        
        timing_cov = timing_cg.get_coverage();
        pixel_cov = pixel_position_cg.get_coverage();
        color_cov = color_cg.get_coverage();
        frame_cov = frame_cg.get_coverage();
        total_cov = (timing_cov + pixel_cov + color_cov + frame_cov) / 4.0;
        
        $display("\n");
        $display("========================================================");
        $display("              FUNCTIONAL COVERAGE REPORT");
        $display("========================================================");
        $display("Timing Coverage       : %.2f%%", timing_cov);
        $display("Pixel Position Coverage: %.2f%%", pixel_cov);
        $display("Color Coverage        : %.2f%%", color_cov);
        $display("Frame Coverage        : %.2f%%", frame_cov);
        $display("--------------------------------------------------------");
        $display("Overall Coverage      : %.2f%%", total_cov);
        $display("========================================================\n");
    endfunction
    
endclass

// =============================================================================
// DRIVER CLASS
// =============================================================================
class vga_driver;
    vga_config cfg;
    virtual vga_if vif;
    
    function new(virtual vga_if vif, vga_config cfg);
        this.cfg = cfg;
        this.vif = vif;
    endfunction
    
    task reset();
        $display("[%0t] DRIVER: Reset Started", $time);
        vif.reset_n <= 1'b0;
        repeat(20) @(posedge vif.CLOCK_50);
        vif.reset_n <= 1'b1;
        repeat(10) @(posedge vif.CLOCK_50);
        $display("[%0t] DRIVER: Reset Ended", $time);
    endtask
    
    task run();
        $display("[%0t] DRIVER: Started", $time);
        // VGA controller is self-running, just monitor
        $display("[%0t] DRIVER: Waiting for VGA operation...", $time);
    endtask
    
endclass

// =============================================================================
// MONITOR CLASS
// =============================================================================
class vga_monitor;
    virtual vga_if vif;
    mailbox #(vga_transaction) mon2scb;
    vga_config cfg;
    vga_coverage cov;
    int num_frames;
    int frames_captured;
    int pixel_count;
    int active_pixel_count;
    
    // Pixel coordinate tracking
    logic [9:0] current_x;
    logic [8:0] current_y;
    logic prev_blank_n;
    
    function new(virtual vga_if vif, vga_config cfg, vga_coverage cov, 
                 mailbox #(vga_transaction) mb, int frames);
        this.vif = vif;
        this.cfg = cfg;
        this.cov = cov;
        this.mon2scb = mb;
        this.num_frames = frames;
        this.frames_captured = 0;
        this.pixel_count = 0;
        this.active_pixel_count = 0;
        this.current_x = 0;
        this.current_y = 0;
        this.prev_blank_n = 0;
    endfunction
    
    task run();
        vga_transaction tr;
        logic prev_vsync;
        int current_frame;
        
        $display("[%0t] MONITOR: Started (capturing %0d frames)", $time, num_frames);
        
        prev_vsync = 1;
        prev_blank_n = 0;
        current_frame = 0;
        current_x = 0;
        current_y = 0;
        
        while (frames_captured < num_frames) begin
            @(posedge vif.VGA_CLK);
            
            // Detect frame boundaries (vsync falling edge)
            if (prev_vsync && !vif.VGA_VS) begin
                current_frame++;
                current_x = 0;
                current_y = 0;
                $display("[%0t] MONITOR: Frame %0d started", $time, current_frame);
            end
            
            // Track pixel coordinates during active video
            // When BLANK_N goes high, we're starting a new line at x=0
            if (!prev_blank_n && vif.VGA_BLANK_N) begin
                current_x = 0;
            end
            
            // Sample every pixel
            tr = new();
            tr.cfg = cfg;
            tr.frame_number = current_frame;
            tr.hsync = vif.VGA_HS;
            tr.vsync = vif.VGA_VS;
            tr.active_video = vif.VGA_BLANK_N;
            tr.blank_n = vif.VGA_BLANK_N;
            
            if (vif.VGA_BLANK_N) begin
                tr.red = vif.VGA_R;
                tr.green = vif.VGA_G;
                tr.blue = vif.VGA_B;
                tr.is_active_region = 1;
                tr.pixel_x = current_x;
                tr.pixel_y = current_y;
                active_pixel_count++;
                
                // Send active pixels to scoreboard for verification
                mon2scb.put(tr);
                
                // Increment X coordinate
                if (current_x < cfg.H_A - 1) begin
                    current_x++;
                end else begin
                    // End of line, move to next line
                    current_x = 0;
                    if (current_y < cfg.V_A - 1) begin
                        current_y++;
                    end else begin
                        current_y = 0; // Wrap around (shouldn't happen mid-frame)
                    end
                end
                
            end else begin
                tr.red = 8'h00;
                tr.green = 8'h00;
                tr.blue = 8'h00;
                tr.is_active_region = 0;
                tr.pixel_x = 0;
                tr.pixel_y = 0;
                
                // When BLANK_N goes low, if we were in active region, increment Y
                if (prev_blank_n && !vif.VGA_BLANK_N && current_x != 0) begin
                    if (current_y < cfg.V_A - 1) begin
                        current_y++;
                    end else begin
                        current_y = 0;
                    end
                    current_x = 0;
                end
            end
            
            prev_blank_n = vif.VGA_BLANK_N;
            pixel_count++;
            
            // Sample coverage
            cov.sample(tr);
            
            // Detect frame end (vsync rising edge)
            if (!prev_vsync && vif.VGA_VS) begin
                $display("[%0t] MONITOR: Frame %0d completed (%0d active pixels)", 
                         $time, current_frame, active_pixel_count);
                $display("[%0t] MONITOR: Final position - X:%0d, Y:%0d", $time, current_x, current_y);
                
                // Verify expected pixel count
                if (active_pixel_count != (cfg.H_A * cfg.V_A)) begin
                    $display("[%0t] WARNING: Expected %0d pixels, got %0d", 
                             $time, cfg.H_A * cfg.V_A, active_pixel_count);
                end
                
                active_pixel_count = 0;
                current_x = 0;
                current_y = 0;
                
                frames_captured++;
                
                if (frames_captured >= num_frames) begin
                    $display("[%0t] MONITOR: Captured %0d frames, stopping", $time, frames_captured);
                    break;
                end
            end
            
            // Update previous vsync state at end of loop
            prev_vsync = vif.VGA_VS;
        end
        
        $display("[%0t] MONITOR: Ended (%0d total pixels sampled)", $time, pixel_count);
    endtask
    
endclass


// =============================================================================
// SCOREBOARD CLASS
// =============================================================================
class vga_scoreboard;
    mailbox #(vga_transaction) mon2scb;
    vga_reference_model ref_model;
    vga_config cfg;
    
    int pixel_count;
    int match_count;
    int mismatch_count;
    int num_frames;
    
    function new(vga_config cfg, mailbox #(vga_transaction) mb, int frames);
        this.cfg = cfg;
        this.mon2scb = mb;
        this.ref_model = new(cfg);
        this.num_frames = frames;
        this.pixel_count = 0;
        this.match_count = 0;
        this.mismatch_count = 0;
    endfunction
    
    task run();
        vga_transaction tr;
        logic [7:0] exp_r, exp_g, exp_b;
        int frame_pixels;
        int expected_pixels_per_frame;
        
        $display("[%0t] SCOREBOARD: Started", $time);
        
        expected_pixels_per_frame = cfg.H_A * cfg.V_A;
        frame_pixels = 0;
        
        while (pixel_count < (expected_pixels_per_frame * num_frames)) begin
            mon2scb.get(tr);
            pixel_count++;
            frame_pixels++;
            
            if (tr.is_active_region) begin
                // Get expected pixel from reference model
                ref_model.get_expected_pixel(tr.pixel_x, tr.pixel_y, exp_r, exp_g, exp_b);
                
                // Compare
                if (tr.red == exp_r && tr.green == exp_g && tr.blue == exp_b) begin
                    match_count++;
                    if (pixel_count % 1000 == 0) begin
                        $display("[%0t][SCB] Pixel %0d MATCH: RGB(0x%02h,0x%02h,0x%02h)", 
                                 $time, pixel_count, tr.red, tr.green, tr.blue);
                    end
                end else begin
                    mismatch_count++;
                    $display("[%0t][SCB] MISMATCH at pixel %0d: Got RGB(0x%02h,0x%02h,0x%02h), Expected RGB(0x%02h,0x%02h,0x%02h)", 
                             $time, pixel_count, tr.red, tr.green, tr.blue, exp_r, exp_g, exp_b);
                end
            end
            
            // Frame boundary detection
            if (frame_pixels == expected_pixels_per_frame) begin
                $display("[%0t][SCB] Frame completed: %0d pixels verified", $time, frame_pixels);
                frame_pixels = 0;
            end
        end
        
        $display("[%0t] SCOREBOARD: Ended", $time);
    endtask
    
    function void report();
        real accuracy;
        accuracy = (match_count * 100.0) / pixel_count;
        
        $display("\n");
        $display("========================================================");
        $display("              SCOREBOARD FINAL REPORT");
        $display("========================================================");
        $display("Total Pixels Checked  : %0d", pixel_count);
        $display("Matching Pixels       : %0d", match_count);
        $display("Mismatched Pixels     : %0d", mismatch_count);
        $display("Accuracy              : %.2f%%", accuracy);
        $display("========================================================\n");
        
        if (mismatch_count == 0) begin
            $display("*** ALL PIXELS MATCH! TEST PASSED! ***\n");
        end else begin
            $display("*** SOME PIXELS MISMATCHED! TEST FAILED! ***\n");
        end
    endfunction
    
endclass

// =============================================================================
// ENVIRONMENT CLASS
// =============================================================================
class vga_environment;
    vga_config cfg;
    virtual vga_if vif;
    
    vga_driver drv;
    vga_monitor mon;
    vga_scoreboard scb;
    vga_coverage cov;
    
    mailbox #(vga_transaction) mon2scb;
    
    int num_frames;
    
    function new(virtual vga_if vif, vga_config cfg, int frames = 2);
        this.vif = vif;
        this.cfg = cfg;
        this.num_frames = frames;
        
        mon2scb = new();
        
        cov = new(cfg);
        drv = new(vif, cfg);
        mon = new(vif, cfg, cov, mon2scb, num_frames);
        scb = new(cfg, mon2scb, num_frames);
    endfunction
    
    task run();
        $display("\n");
        $display("========================================================");
        $display("         VGA TESTBENCH ENVIRONMENT STARTING");
        $display("========================================================");
        cfg.display();
        
        drv.reset();
        
        fork
            drv.run();
            mon.run();
            scb.run();
        join
        
        scb.report();
        cov.report();
        
        $display("\n");
        $display("========================================================");
        $display("         VGA TESTBENCH ENVIRONMENT COMPLETED");
        $display("========================================================\n");
    endtask
    
endclass

endpackage