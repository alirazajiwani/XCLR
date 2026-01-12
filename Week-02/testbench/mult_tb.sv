// Multiplier Transaction Class
class mult_transaction;
    bit [7:0] A;
    bit [7:0] B;
    bit EA;
    bit EB;
    bit [15:0] P;
    
    function void display(string tag = "");
        $display("[%0t] %s: A=%0d, B=%0d, EA=%0b, EB=%0b, P=%0d", 
                 $time, tag, A, B, EA, EB, P);
    endfunction
    
    function bit [15:0] calculate_expected();
        return A * B;
    endfunction
endclass

// Multiplier Generator
class mult_generator;
    mailbox #(mult_transaction) gen2drv;
    int num_trans;
    int seed;
    
    function new(mailbox #(mult_transaction) g2d, int n = 50);
        this.gen2drv = g2d;
        this.num_trans = n;
        this.seed = 98765;
        void'($urandom(seed));
    endfunction
    
    function bit [7:0] get_random_byte();
        return $urandom() % 256;
    endfunction
    
    function bit get_random_bit();
        return $urandom() % 2;
    endfunction
    
    task run();
        mult_transaction trans;
        
        $display("[%0t] GENERATOR: Starting directed corner cases", $time);
        
        // Test 1: 0 × 0
        trans = new();
        trans.A = 0; trans.B = 0; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Test 2: 1 × 1
        trans = new();
        trans.A = 1; trans.B = 1; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Test 3: 255 × 255
        trans = new();
        trans.A = 255; trans.B = 255; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Test 4: 1 × 255
        trans = new();
        trans.A = 1; trans.B = 255; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Test 5: 255 × 1
        trans = new();
        trans.A = 255; trans.B = 1; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Test 6: Powers of 2
        trans = new();
        trans.A = 16; trans.B = 16; trans.EA = 1; trans.EB = 1;
        gen2drv.put(trans);
        
        // Generate pseudo-random transactions
        $display("[%0t] GENERATOR: Starting pseudo-random tests", $time);
        repeat(num_trans) begin
            trans = new();
            trans.A = get_random_byte();
            trans.B = get_random_byte();
            trans.EA = 1;
            trans.EB = 1;
            gen2drv.put(trans);
        end
        
        // Test with enables disabled
        $display("[%0t] GENERATOR: Testing with enables disabled", $time);
        trans = new();
        trans.A = 100; trans.B = 100; trans.EA = 0; trans.EB = 1;
        gen2drv.put(trans);
        
        trans = new();
        trans.A = 100; trans.B = 100; trans.EA = 1; trans.EB = 0;
        gen2drv.put(trans);
        
        $display("[%0t] GENERATOR: All transactions generated", $time);
    endtask
endclass

// Multiplier Driver
class mult_driver;
    virtual mult_if vif;
    mailbox #(mult_transaction) gen2drv;
    
    function new(virtual mult_if vif, mailbox #(mult_transaction) g2d);
        this.vif = vif;
        this.gen2drv = g2d;
    endfunction
    
    task reset();
        vif.rst <= 1;
        vif.EA <= 0;
        vif.EB <= 0;
        vif.A <= 0;
        vif.B <= 0;
        repeat(2) @(posedge vif.clk);
        vif.rst <= 0;
        @(posedge vif.clk);
    endtask
    
    task run();
        mult_transaction trans;
        forever begin
            gen2drv.get(trans);
            @(posedge vif.clk);
            vif.A <= trans.A;
            vif.B <= trans.B;
            vif.EA <= trans.EA;
            vif.EB <= trans.EB;
            trans.display("DRIVER");
        end
    endtask
endclass

// Multiplier Monitor - Sample AFTER clock edge with delay
class mult_monitor;
    virtual mult_if vif;
    mailbox #(mult_transaction) mon2scb_input;
    mailbox #(mult_transaction) mon2scb_output;
    
    function new(virtual mult_if vif, mailbox #(mult_transaction) m2s_in, 
                 mailbox #(mult_transaction) m2s_out);
        this.vif = vif;
        this.mon2scb_input = m2s_in;
        this.mon2scb_output = m2s_out;
    endfunction
    
    task run();
        fork
            monitor_inputs();
            monitor_outputs();
        join
    endtask
    
    // Sample inputs AFTER clock edge to see what was actually driven
    task monitor_inputs();
        mult_transaction trans;
        forever begin
            @(posedge vif.clk);
            #1; // Wait for NBA assignments to complete
            trans = new();
            trans.A = vif.A;
            trans.B = vif.B;
            trans.EA = vif.EA;
            trans.EB = vif.EB;
            mon2scb_input.put(trans);
            $display("[%0t] MONITOR INPUT: A=%0d, B=%0d, EA=%0b, EB=%0b", 
                     $time, trans.A, trans.B, trans.EA, trans.EB);
        end
    endtask
    
    // Sample outputs AFTER clock edge
    task monitor_outputs();
        mult_transaction trans;
        forever begin
            @(posedge vif.clk);
            #1; // Wait for NBA assignments to complete
            trans = new();
            trans.P = vif.P;
            mon2scb_output.put(trans);
            $display("[%0t] MONITOR OUTPUT: P=%0d", $time, trans.P);
        end
    endtask
endclass

// Multiplier Scoreboard - 
class mult_scoreboard;
    mailbox #(mult_transaction) mon2scb_input;
    mailbox #(mult_transaction) mon2scb_output;
    int pass_count, fail_count;
    
    mult_transaction input_queue[$];
    int latency;
    
    function new(mailbox #(mult_transaction) m2s_in, 
                 mailbox #(mult_transaction) m2s_out, int lat = 2);
        this.mon2scb_input = m2s_in;
        this.mon2scb_output = m2s_out;
        this.pass_count = 0;
        this.fail_count = 0;
        this.latency = lat;
    endfunction
    
    task run();
        fork
            collect_inputs();
            check_outputs();
        join
    endtask
    
    task collect_inputs();
        mult_transaction trans;
        forever begin
            mon2scb_input.get(trans);
            input_queue.push_back(trans);
        end
    endtask
    
    task check_outputs();
        mult_transaction output_trans, expected_trans;
        bit [15:0] expected_P;
        
        forever begin
            mon2scb_output.get(output_trans);
            
            // Need latency entries in queue to start checking
            if (input_queue.size() >= latency) begin
                expected_trans = input_queue.pop_front();
                
                // Only check if inputs were enabled
                if (expected_trans.EA && expected_trans.EB) begin
                    expected_P = expected_trans.A * expected_trans.B;
                    
                    if (output_trans.P === expected_P) begin
                        $display("[%0t] SCOREBOARD PASS: A=%0d, B=%0d, Expected=%0d, Got=%0d", 
                                 $time, expected_trans.A, expected_trans.B, expected_P, output_trans.P);
                        pass_count++;
                    end else begin
                        $display("[%0t] SCOREBOARD FAIL: A=%0d, B=%0d, Expected=%0d, Got=%0d", 
                                 $time, expected_trans.A, expected_trans.B, expected_P, output_trans.P);
                        fail_count++;
                    end
                end else begin
                    $display("[%0t] SCOREBOARD: Inputs not enabled (EA=%0b, EB=%0b), skipping check", 
                             $time, expected_trans.EA, expected_trans.EB);
                end
            end else begin
                $display("[%0t] SCOREBOARD: Pipeline filling... (queue size=%0d, need %0d)", 
                         $time, input_queue.size(), latency);
            end
        end
    endtask
    
    function void report();
        $display("\n========== SCOREBOARD REPORT ==========");
        $display("Total Passed: %0d", pass_count);
        $display("Total Failed: %0d", fail_count);
        $display("Pipeline Latency: %0d cycles", latency);
        if (fail_count == 0 && pass_count > 0)
            $display("*** ALL TESTS PASSED ***");
        else if (fail_count > 0)
            $display("*** SOME TESTS FAILED ***");
        else
            $display("*** NO TESTS EXECUTED ***");
        $display("=======================================\n");
    endfunction
endclass

// Multiplier Environment
class mult_environment;
    mult_generator gen;
    mult_driver drv;
    mult_monitor mon;
    mult_scoreboard scb;
    
    mailbox #(mult_transaction) gen2drv;
    mailbox #(mult_transaction) mon2scb_input;
    mailbox #(mult_transaction) mon2scb_output;
    
    virtual mult_if vif;
    
    function new(virtual mult_if vif);
        this.vif = vif;
        gen2drv = new();
        mon2scb_input = new();
        mon2scb_output = new();
        
        gen = new(gen2drv, 10);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb_input, mon2scb_output);
        scb = new(mon2scb_input, mon2scb_output, 2); // 2-cycle latency
    endfunction
    
    task run();
        fork
            drv.reset();
            #10 gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
    
    function void report();
        scb.report();
    endfunction
endclass

// Multiplier Interface
interface mult_if(input logic clk);
    logic rst;
    logic EA;
    logic EB;
    logic [7:0] A;
    logic [7:0] B;
    logic [15:0] P;
endinterface

// Multiplier Testbench Top
module mult_tb;
    logic clk;
    
    mult_if mif(clk);
    
    Multiplier8x8 dut (
        .clk(mif.clk),
        .rst(mif.rst),
        .EA(mif.EA),
        .EB(mif.EB),
        .A(mif.A),
        .B(mif.B),
        .P(mif.P)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    mult_environment env;
    
    initial begin
        $display("========================================");
        $display("          Multiplier Testbench          ");
        $display("========================================\n");
        
        env = new(mif);
        env.run();
        #210; 
        env.report();
        $finish;
    end
endmodule