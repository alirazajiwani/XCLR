// ============================================================================
// Layered Testbench for Sequence Detector (1011)
// ============================================================================
// This testbench follows a layered architecture similar to UVM methodology
// Layers: Transaction -> Generator -> Driver -> DUT -> Monitor -> Scoreboard
// ============================================================================

`timescale 1ns/1ps

// ============================================================================
// Transaction Class - Represents a single stimulus/response packet
// ============================================================================
class seq_transaction;
    rand bit in_bit;          // Input bit
    bit seq_detected;         // Output from DUT
    bit expected_detected;    // Expected output
    time timestamp;           // Transaction timestamp
    
    // Constraints for different test scenarios
    constraint c_balanced {
        in_bit dist {0 := 50, 1 := 50};
    }
    
    // Function to display transaction
    function void display(string tag = "");
        $display("[%s] Time=%0t | in_bit=%b | seq_detected=%b | expected=%b", 
                 tag, timestamp, in_bit, seq_detected, expected_detected);
    endfunction
    
    // Function to copy transaction
    function seq_transaction copy();
        copy = new();
        copy.in_bit = this.in_bit;
        copy.seq_detected = this.seq_detected;
        copy.expected_detected = this.expected_detected;
        copy.timestamp = this.timestamp;
    endfunction
    
endclass

// ============================================================================
// Generator Class - Generates test stimuli
// ============================================================================
class generator;
    seq_transaction trans;
    mailbox #(seq_transaction) gen2drv;
    event drv_done;
    int num_transactions;
    
    // Constructor
    function new(mailbox #(seq_transaction) gen2drv, event drv_done);
        this.gen2drv = gen2drv;
        this.drv_done = drv_done;
    endfunction
    
    // Main task to generate transactions
    task run(int count = 100);
        num_transactions = count;
        
        for (int i = 0; i < count; i++) begin
            trans = new();
            assert(trans.randomize()) else $fatal("Randomization failed!");
            gen2drv.put(trans);
            @(drv_done);
        end
        
        $display("[GENERATOR] Generated %0d transactions", count);
    endtask
    
    // Directed test: Generate specific sequence
    task generate_directed_sequence(bit bit_sequence[]);
        num_transactions = bit_sequence.size();
        
        foreach(bit_sequence[i]) begin
            trans = new();
            trans.in_bit = bit_sequence[i];
            gen2drv.put(trans);
            @(drv_done);
        end
        
        $display("[GENERATOR] Generated directed sequence of %0d bits", bit_sequence.size());
    endtask
    
    // Generate pattern with "1011" sequence
    task generate_target_pattern(int num_patterns = 5);
        bit pattern[] = '{1, 0, 1, 1};
        
        for (int i = 0; i < num_patterns; i++) begin
            foreach(pattern[j]) begin
                trans = new();
                trans.in_bit = pattern[j];
                gen2drv.put(trans);
                @(drv_done);
            end
            
            // Add random bits between patterns
            if (i < num_patterns - 1) begin
                trans = new();
                assert(trans.randomize());
                gen2drv.put(trans);
                @(drv_done);
            end
        end
        
        $display("[GENERATOR] Generated %0d target patterns", num_patterns);
    endtask
    
endclass

// ============================================================================
// Driver Class - Drives transactions to DUT
// ============================================================================
class driver;
    virtual seq_detector_if vif;
    mailbox #(seq_transaction) gen2drv;
    mailbox #(seq_transaction) drv2mon;
    event drv_done;
    
    // Constructor
    function new(virtual seq_detector_if vif, 
                 mailbox #(seq_transaction) gen2drv,
                 mailbox #(seq_transaction) drv2mon,
                 event drv_done);
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.drv2mon = drv2mon;
        this.drv_done = drv_done;
    endfunction
    
    // Reset task
    task reset();
        $display("[DRIVER] Applying reset...");
        vif.rst_n = 0;
        vif.in_bit = 0;
        repeat(3) @(posedge vif.clk);
        vif.rst_n = 1;
        @(posedge vif.clk);
        $display("[DRIVER] Reset completed");
    endtask
    
    // Main driving task
    task run();
        forever begin
            seq_transaction trans;
            gen2drv.get(trans);
            
            // Drive the transaction
            @(posedge vif.clk);
            vif.in_bit = trans.in_bit;
            trans.timestamp = $time;
            
            // Send to monitor for tracking
            drv2mon.put(trans.copy());
            
            // Signal completion
            ->drv_done;
        end
    endtask
    
endclass

// ============================================================================
// Monitor Class - Observes DUT outputs
// ============================================================================
class monitor;
    virtual seq_detector_if vif;
    mailbox #(seq_transaction) mon2scb;
    mailbox #(seq_transaction) drv2mon;
    
    // Constructor
    function new(virtual seq_detector_if vif,
                 mailbox #(seq_transaction) mon2scb,
                 mailbox #(seq_transaction) drv2mon);
        this.vif = vif;
        this.mon2scb = mon2scb;
        this.drv2mon = drv2mon;
    endfunction
    
    // Main monitoring task
    task run();
        forever begin
            seq_transaction trans;
            
            // Get transaction from driver
            drv2mon.get(trans);
            
            // Wait for output to be valid
            @(posedge vif.clk);
            #1; // Small delta delay
            
            // Capture output
            trans.seq_detected = vif.seq_detected;
            
            // Send to scoreboard
            mon2scb.put(trans);
        end
    endtask
    
endclass

// ============================================================================
// Reference Model Class - Golden reference for expected behavior
// ============================================================================
class reference_model;
    bit [3:0] shift_reg;
    
    // Constructor
    function new();
        shift_reg = 4'b0000;
    endfunction
    
    // Predict output based on input
    function bit predict(bit in_bit);
        bit expected;
        
        // Check current pattern before shifting
        expected = (shift_reg[2:0] == 3'b101) && (in_bit == 1);
        
        // Shift in new bit
        shift_reg = {shift_reg[2:0], in_bit};
        
        return expected;
    endfunction
    
    // Reset the model
    function void reset();
        shift_reg = 4'b0000;
    endfunction
    
endclass

// ============================================================================
// Scoreboard Class - Compares DUT output with expected output
// ============================================================================
class scoreboard;
    mailbox #(seq_transaction) mon2scb;
    reference_model ref_model;
    int pass_count;
    int fail_count;
    int total_count;
    
    // Constructor
    function new(mailbox #(seq_transaction) mon2scb);
        this.mon2scb = mon2scb;
        this.ref_model = new();
        this.pass_count = 0;
        this.fail_count = 0;
        this.total_count = 0;
    endfunction
    
    // Reset the scoreboard
    task reset();
        ref_model.reset();
    endtask
    
    // Main checking task
    task run();
        forever begin
            seq_transaction trans;
            bit expected;
            
            mon2scb.get(trans);
            total_count++;
            
            // Get expected result from reference model
            expected = ref_model.predict(trans.in_bit);
            trans.expected_detected = expected;
            
            // Compare
            if (trans.seq_detected === expected) begin
                pass_count++;
                if (trans.seq_detected) begin
                    $display("[SCOREBOARD] ? PASS [%0t] - Pattern detected correctly (shift_reg=%b)", 
                            trans.timestamp, ref_model.shift_reg);
                end
            end else begin
                fail_count++;
                $display("[SCOREBOARD] ? FAIL [%0t] - Expected=%b, Got=%b (shift_reg=%b)", 
                        trans.timestamp, expected, trans.seq_detected, ref_model.shift_reg);
                trans.display("ERROR");
            end
        end
    endtask
    
    // Report function
    function void report();
        $display("\n============================================");
        $display("           SCOREBOARD REPORT");
        $display("============================================");
        $display("Total Transactions: %0d", total_count);
        $display("Passed:            %0d", pass_count);
        $display("Failed:            %0d", fail_count);
        $display("Pass Rate:         %.2f%%", (pass_count * 100.0) / total_count);
        
        if (fail_count == 0) begin
            $display("\n*** ALL CHECKS PASSED! ***");
        end else begin
            $display("\n*** SOME CHECKS FAILED ***");
        end
        $display("============================================\n");
    endfunction
    
endclass

// ============================================================================
// Coverage Collector Class - Comprehensive functional coverage
// ============================================================================
class coverage_collector;
    virtual seq_detector_if vif;
    mailbox #(seq_transaction) mon2cov;
    
    // Coverage groups
    covergroup cg_states @(posedge vif.clk);
        option.name = "state_coverage";
        option.per_instance = 1;
        option.comment = "Coverage of all FSM states";
        
        cp_state: coverpoint vif.current_state {
            bins S0 = {0};
            bins S1 = {1};
            bins S2 = {2};
            bins S3 = {3};
            bins S4 = {4};
            option.comment = "All FSM states";
        }
    endgroup
    
    covergroup cg_transitions @(posedge vif.clk);
        option.name = "transition_coverage";
        option.per_instance = 1;
        option.comment = "Coverage of all state transitions";
        
        cp_trans: coverpoint vif.current_state {
            bins s0_to_s0 = (0 => 0);
            bins s0_to_s1 = (0 => 1);
            bins s1_to_s1 = (1 => 1);
            bins s1_to_s2 = (1 => 2);
            bins s2_to_s0 = (2 => 0);
            bins s2_to_s3 = (2 => 3);
            bins s3_to_s2 = (3 => 2);
            bins s3_to_s4 = (3 => 4);
            bins s4_to_s1 = (4 => 1);
            bins s4_to_s2 = (4 => 2);
            option.comment = "All valid FSM transitions";
        }
    endgroup
    
    covergroup cg_inputs @(posedge vif.clk);
        option.name = "input_coverage";
        option.per_instance = 1;
        option.comment = "Coverage of inputs at each state";
        
        cp_input: coverpoint vif.in_bit {
            bins zero = {0};
            bins one = {1};
        }
        
        cp_state_input: cross vif.current_state, vif.in_bit {
            option.comment = "Input patterns at each state";
        }
    endgroup
    
    covergroup cg_output @(posedge vif.clk);
        option.name = "output_coverage";
        option.per_instance = 1;
        option.comment = "Coverage of detection output";
        
        cp_detected: coverpoint vif.seq_detected {
            bins not_detected = {0};
            bins detected = {1};
        }
        
        cp_detection_states: cross vif.current_state, vif.seq_detected {
            option.comment = "Detection at each state";
        }
    endgroup
    
    covergroup cg_sequences @(posedge vif.clk);
        option.name = "sequence_patterns";
        option.per_instance = 1;
        option.comment = "Coverage of interesting bit sequences";
        
        cp_bit_seq: coverpoint vif.in_bit {
            bins zeros = (0 => 0);
            bins ones = (1 => 1);
            bins zero_to_one = (0 => 1);
            bins one_to_zero = (1 => 0);
        }
        
        // 3-bit sequence coverage
        cp_3bit_seq: coverpoint vif.in_bit {
            bins seq_000 = (0 => 0 => 0);
            bins seq_001 = (0 => 0 => 1);
            bins seq_010 = (0 => 1 => 0);
            bins seq_011 = (0 => 1 => 1);
            bins seq_100 = (1 => 0 => 0);
            bins seq_101 = (1 => 0 => 1);
            bins seq_110 = (1 => 1 => 0);
            bins seq_111 = (1 => 1 => 1);
        }
        
        // 4-bit target sequence
        cp_target: coverpoint vif.in_bit {
            bins target_1011 = (1 => 0 => 1 => 1);
            option.comment = "Target sequence 1011";
        }
    endgroup
    
    covergroup cg_reset @(negedge vif.rst_n);
        option.name = "reset_coverage";
        option.per_instance = 1;
        option.comment = "Reset at different states";
        
        cp_reset_state: coverpoint vif.current_state {
            bins reset_at_S0 = {0};
            bins reset_at_S1 = {1};
            bins reset_at_S2 = {2};
            bins reset_at_S3 = {3};
            bins reset_at_S4 = {4};
            option.comment = "Reset occurring at each state";
        }
    endgroup
    
    // Constructor
    function new(virtual seq_detector_if vif);
        this.vif = vif;
        cg_states = new();
        cg_transitions = new();
        cg_inputs = new();
        cg_output = new();
        cg_sequences = new();
        cg_reset = new();
    endfunction
    
    // Sample all coverage
    task run();
        forever begin
            @(posedge vif.clk);
            // Coverage is automatically sampled at clock edge
        end
    endtask
    
    // Report coverage
    function void report();
        real total_cov;
        
        $display("\n============================================");
        $display("         COVERAGE REPORT");
        $display("============================================");
        $display("State Coverage:       %.2f%%", cg_states.get_coverage());
        $display("Transition Coverage:  %.2f%%", cg_transitions.get_coverage());
        $display("Input Coverage:       %.2f%%", cg_inputs.get_coverage());
        $display("Output Coverage:      %.2f%%", cg_output.get_coverage());
        $display("Sequence Coverage:    %.2f%%", cg_sequences.get_coverage());
        $display("Reset Coverage:       %.2f%%", cg_reset.get_coverage());
        
        total_cov = (cg_states.get_coverage() + 
                     cg_transitions.get_coverage() + 
                     cg_inputs.get_coverage() + 
                     cg_output.get_coverage() + 
                     cg_sequences.get_coverage() +
                     cg_reset.get_coverage()) / 6.0;
        
        $display("--------------------------------------------");
        $display("Average Coverage:     %.2f%%", total_cov);
        $display("============================================\n");
    endfunction
    
endclass

// ============================================================================
// Environment Class - Instantiates and connects all components
// ============================================================================
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    coverage_collector cov;
    
    mailbox #(seq_transaction) gen2drv;
    mailbox #(seq_transaction) drv2mon;
    mailbox #(seq_transaction) mon2scb;
    
    event drv_done;
    
    virtual seq_detector_if vif;
    
    // Constructor
    function new(virtual seq_detector_if vif);
        this.vif = vif;
        
        // Create mailboxes
        gen2drv = new();
        drv2mon = new();
        mon2scb = new();
        
        // Create components
        gen = new(gen2drv, drv_done);
        drv = new(vif, gen2drv, drv2mon, drv_done);
        mon = new(vif, mon2scb, drv2mon);
        scb = new(mon2scb);
        cov = new(vif);
    endfunction
    
    // Pre-test: Initialize and reset
    task pre_test();
        $display("\n[ENVIRONMENT] Starting pre-test initialization...");
        scb.reset();  // Reset scoreboard first
        drv.reset();  // Then reset DUT
    endtask
    
    // Task to perform reset during test
    task reset_dut();
        scb.reset();  // Reset scoreboard first
        drv.reset();  // Then reset DUT
    endtask
    
    // Test: Run all components
    task test();
        fork
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_none
    endtask
    
    // Post-test: Reports
    task post_test();
        // Wait for all transactions to complete
        repeat(10) @(posedge vif.clk);
        
        $display("\n[ENVIRONMENT] Generating reports...");
        scb.report();
        cov.report();
    endtask
    
    // Main run task
    task run();
        pre_test();
        test();
        // Test stimulus will be generated by test program
    endtask
    
endclass

// ============================================================================
// Interface - Connects testbench to DUT
// ============================================================================
interface seq_detector_if(input logic clk);
    logic rst_n;
    logic in_bit;
    logic seq_detected;
    logic [2:0] current_state;
    
    // Clocking block for synchronous driving
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rst_n;
        output in_bit;
        input seq_detected;
    endclocking
    
    // Clocking block for monitoring
    clocking monitor_cb @(posedge clk);
        default input #1;
        input rst_n;
        input in_bit;
        input seq_detected;
        input current_state;
    endclocking
    
    // Modport for driver
    modport DRIVER (clocking driver_cb, output rst_n, output in_bit);
    
    // Modport for monitor
    modport MONITOR (clocking monitor_cb, input rst_n, input in_bit, 
                     input seq_detected, input current_state);
    
endinterface

// ============================================================================
// Top Level Testbench Module
// ============================================================================
module seq_detector_tb;
    
    // Clock generation
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Interface instantiation
    seq_detector_if vif(clk);
    
    // DUT instantiation
    seq_detector dut (
        .clk(vif.clk),
        .rst_n(vif.rst_n),
        .in_bit(vif.in_bit),
        .seq_detected(vif.seq_detected)
    );
    
    // Connect internal state for coverage
    assign vif.current_state = dut.CS;
    
    // Environment instantiation
    environment env;
    
    // Test program
    initial begin
        $display("============================================");
        $display("   LAYERED TESTBENCH FOR SEQUENCE DETECTOR");
        $display("   Detecting Pattern: 1011");
        $display("============================================\n");
        
        // Create environment
        env = new(vif);
        
        // Initialize and run
        env.run();
        
        // Test 1: Random stimulus
        $display("\n[TEST 1] Running random stimulus test (200 transactions)...");
        env.gen.run(200);
        
        // Reset between tests
        env.reset_dut();
        
        // Test 2: Directed target patterns
        $display("\n[TEST 2] Running directed target pattern test...");
        env.gen.generate_target_pattern(10);
        
        // Reset between tests
        env.reset_dut();
        
        // Test 3: Specific sequences
        $display("\n[TEST 3] Running specific sequence tests...");
        
        // Test 3a: Basic target sequence
        begin
            automatic bit seq1[] = '{1, 0, 1, 1};
            $display("  - Testing basic 1011 sequence");
            env.gen.generate_directed_sequence(seq1);
        end
        
        // Test 3b: Overlapping sequences
        begin
            automatic bit seq2[] = '{1, 0, 1, 0, 1, 1};
            $display("  - Testing overlapping sequences");
            env.gen.generate_directed_sequence(seq2);
        end
        
        // Test 3c: Back-to-back sequences
        begin
            automatic bit seq3[] = '{1, 0, 1, 1, 1, 0, 1, 1};
            $display("  - Testing back-to-back sequences");
            env.gen.generate_directed_sequence(seq3);
        end
        
        // Test 3d: All zeros
        begin
            automatic bit seq4[] = '{0, 0, 0, 0, 0, 0, 0, 0};
            $display("  - Testing all zeros");
            env.gen.generate_directed_sequence(seq4);
        end
        
        // Test 3e: All ones
        begin
            automatic bit seq5[] = '{1, 1, 1, 1, 1, 1, 1, 1};
            $display("  - Testing all ones");
            env.gen.generate_directed_sequence(seq5);
        end
        
        // Test 3f: Near-miss patterns
        begin
            automatic bit seq6[] = '{1, 0, 1, 0}; // Near miss
            $display("  - Testing near-miss pattern (1010)");
            env.gen.generate_directed_sequence(seq6);
        end
        
        // Reset test
        $display("\n[TEST 4] Running reset test...");
        begin
            automatic bit seq_before_reset[] = '{1, 0, 1};
            automatic bit seq_after_reset[] = '{1, 0, 1, 1};
            
            env.gen.generate_directed_sequence(seq_before_reset);
            
            // Wait for transactions to complete
            repeat(3) @(posedge vif.clk);
            
            // Reset scoreboard first, then apply DUT reset
            env.scb.reset();
            
            // Apply reset to DUT
            @(posedge vif.clk);
            vif.rst_n = 0;
            repeat(2) @(posedge vif.clk);
            vif.rst_n = 1;
            @(posedge vif.clk);
            
            // Continue with sequence
            env.gen.generate_directed_sequence(seq_after_reset);
        end
        
        // Post-test reports
        env.post_test();
        
        // Simulation end
        $display("\n[TESTBENCH] Simulation completed successfully!");
        $display("============================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end
    

endmodule