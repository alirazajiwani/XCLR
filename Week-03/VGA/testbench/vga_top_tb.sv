`timescale 1ns/1ps

module vga_top_tb;
    import vga_tb_package::*;
    
    // Clock generation
    logic CLOCK_50;
    
    // Interface instantiation
    vga_if vif(CLOCK_50);
    
    // DUT instantiation
    vga_top dut (
        .CLOCK_50(vif.CLOCK_50),
        .reset_n(vif.reset_n),
        .VGA_R(vif.VGA_R),
        .VGA_G(vif.VGA_G),
        .VGA_B(vif.VGA_B),
        .VGA_HS(vif.VGA_HS),
        .VGA_VS(vif.VGA_VS),
        .VGA_CLK(vif.VGA_CLK),
        .VGA_BLANK_N(vif.VGA_BLANK_N),
        .VGA_SYNC_N(vif.VGA_SYNC_N)
    );
    
    // Clock generation (50 MHz)
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50; // 20ns period = 50MHz
    end
    
    // Test program
    initial begin
        vga_config cfg;
        vga_environment env;
        int num_frames_to_test;
        
        $display("\n");
        $display("============================================================");
        $display("    VGA LAYERED TESTBENCH WITH FUNCTIONAL COVERAGE");
        $display("============================================================");
        $display("Starting VGA verification testbench...\n");
        
        // Configuration
        cfg = new();
        num_frames_to_test = 3; // Test 3 complete frames
        
        // Create environment
        env = new(vif, cfg, num_frames_to_test);
        
        // Run the test
        env.run();
        
        // Test completion
        #10000;
        $display("\n");
        $display("============================================================");
        $display("                   SIMULATION COMPLETED");
        $display("============================================================\n");
        
        $finish;
    end
    
    // Timeout watchdog (500ms)
    initial begin
        #500_000_000;
        $display("\n*** ERROR: Simulation timeout! ***");
        $finish;
    end
    
endmodule