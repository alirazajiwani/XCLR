// Shift Register Transaction Class 
class shift_reg_transaction #(parameter N = 8);
    bit shift_en;
    bit dir;
    bit d_in;
    bit [N-1:0] q_out;
    
    function void display(string tag = "");
        $display("[%0t] %s: shift_en=%0b, dir=%0s, d_in=%0b, q_out=%0h", 
                 $time, tag, shift_en, dir ? "RIGHT" : "LEFT", d_in, q_out);
    endfunction
endclass

// Shift Register Generator (Using pseudo-random without randomize)
class shift_reg_generator #(parameter N = 8);
    mailbox #(shift_reg_transaction#(N)) gen2drv;
    int num_trans;
    int seed;
    
    function new(mailbox #(shift_reg_transaction#(N)) g2d, int n = 100);
        this.gen2drv = g2d;
        this.num_trans = n;
        this.seed = 54321; 
    endfunction
    
    // Simple pseudo-random function using $urandom
    function bit get_random_bit();
        return $urandom(seed) % 2;
    endfunction
    
    task run();
        shift_reg_transaction#(N) trans;
        
        // Generate directed test cases first
        $display("[%0t] GENERATOR: Starting directed tests", $time);
        
        // Test 1: Shift left with d_in=1
        trans = new();
        trans.shift_en = 1;
        trans.dir = 0; // Left
        trans.d_in = 1;
        gen2drv.put(trans);
        $display("[%0t] GENERATOR: Directed test - Shift left with d_in=1", $time);
        
        // Test 2: Shift right with d_in=1
        trans = new();
        trans.shift_en = 1;
        trans.dir = 1; // Right
        trans.d_in = 1;
        gen2drv.put(trans);
        $display("[%0t] GENERATOR: Directed test - Shift right with d_in=1", $time);
        
        // Test 3: Hold (shift_en=0)
        trans = new();
        trans.shift_en = 0;
        trans.dir = 0;
        trans.d_in = 0;
        gen2drv.put(trans);
        $display("[%0t] GENERATOR: Directed test - Hold value", $time);
        
        // Test 4: Shift left with d_in=0
        trans = new();
        trans.shift_en = 1;
        trans.dir = 0; // Left
        trans.d_in = 0;
        gen2drv.put(trans);
        $display("[%0t] GENERATOR: Directed test - Shift left with d_in=0", $time);
        
        // Generate pseudo-random transactions
        $display("[%0t] GENERATOR: Starting pseudo-random tests", $time);
        repeat(num_trans) begin
            trans = new();
            trans.shift_en = get_random_bit();
            trans.dir = get_random_bit();
            trans.d_in = get_random_bit();
            gen2drv.put(trans);
        end
    endtask
endclass

// Shift Register Driver
class shift_reg_driver #(parameter N = 8);
    virtual shift_reg_if#(N) vif;
    mailbox #(shift_reg_transaction#(N)) gen2drv;
    
    function new(virtual shift_reg_if#(N) vif, mailbox #(shift_reg_transaction#(N)) g2d);
        this.vif = vif;
        this.gen2drv = g2d;
    endfunction
    
    task reset();
        vif.rst_n <= 0;
        vif.shift_en <= 0;
        vif.dir <= 0;
        vif.d_in <= 0;
        repeat(2) @(posedge vif.clk);
        vif.rst_n <= 1;
        @(posedge vif.clk);
    endtask
    
    task run();
        shift_reg_transaction#(N) trans;
        forever begin
            gen2drv.get(trans);
            @(posedge vif.clk);
            vif.shift_en <= trans.shift_en;
            vif.dir <= trans.dir;
            vif.d_in <= trans.d_in;
            trans.display("DRIVER");
        end
    endtask
endclass

// Shift Register Monitor
class shift_reg_monitor #(parameter N = 8);
    virtual shift_reg_if#(N) vif;
    mailbox #(shift_reg_transaction#(N)) mon2scb;
    
    function new(virtual shift_reg_if#(N) vif, mailbox #(shift_reg_transaction#(N)) m2s);
        this.vif = vif;
        this.mon2scb = m2s;
    endfunction
    
    task run();
        shift_reg_transaction#(N) trans;
        forever begin
            @(posedge vif.clk);
            trans = new();
            trans.shift_en = vif.shift_en;
            trans.dir = vif.dir;
            trans.d_in = vif.d_in;
            trans.q_out = vif.q_out;
            mon2scb.put(trans);
            trans.display("MONITOR");
        end
    endtask
endclass

// Shift Register Scoreboard
class shift_reg_scoreboard #(parameter N = 8);
    mailbox #(shift_reg_transaction#(N)) mon2scb;
    bit [N-1:0] expected_q;
    int pass_count, fail_count;
    
    function new(mailbox #(shift_reg_transaction#(N)) m2s);
        this.mon2scb = m2s;
        this.expected_q = 0;
        this.pass_count = 0;
        this.fail_count = 0;
    endfunction
    
    task run();
        shift_reg_transaction#(N) trans;
        forever begin
            mon2scb.get(trans);
            
            if (trans.q_out === expected_q) begin
                $display("[%0t] SCOREBOARD PASS: Expected=%0h, Got=%0h", 
                         $time, expected_q, trans.q_out);
                pass_count++;
            end else begin
                $display("[%0t] SCOREBOARD FAIL: Expected=%0h, Got=%0h", 
                         $time, expected_q, trans.q_out);
                fail_count++;
            end
            
            // Update expected output
            if (trans.shift_en) begin
                if (trans.dir) // Right shift
                    expected_q = {trans.d_in, expected_q[N-1:1]};
                else // Left shift
                    expected_q = {expected_q[N-2:0], trans.d_in};
            end
        end
    endtask
    
    function void report();
        $display("\n========== SCOREBOARD REPORT ==========");
        $display("Total Passed: %0d", pass_count);
        $display("Total Failed: %0d", fail_count);
        if (fail_count == 0 && pass_count > 0)
            $display("*** ALL TESTS PASSED ***");
        else if (fail_count > 0)
            $display("*** SOME TESTS FAILED ***");
        $display("=======================================\n");
    endfunction
endclass

// Shift Register Environment
class shift_reg_environment #(parameter N = 8);
    shift_reg_generator#(N) gen;
    shift_reg_driver#(N) drv;
    shift_reg_monitor#(N) mon;
    shift_reg_scoreboard#(N) scb;
    
    mailbox #(shift_reg_transaction#(N)) gen2drv;
    mailbox #(shift_reg_transaction#(N)) mon2scb;
    
    virtual shift_reg_if#(N) vif;
    
    function new(virtual shift_reg_if#(N) vif);
        this.vif = vif;
        gen2drv = new();
        mon2scb = new();
        
        gen = new(gen2drv, 10);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
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

// Shift Register Interface
interface shift_reg_if #(parameter N = 8)(input logic clk);
    logic rst_n;
    logic shift_en;
    logic dir;
    logic d_in;
    logic [N-1:0] q_out;
endinterface

// Shift Register Testbench Top
module shift_reg_tb;
    parameter N = 8;
    logic clk;
    
    shift_reg_if#(N) sif(clk);
    
    shift_reg#(N) dut (
        .clk(sif.clk),
        .rst_n(sif.rst_n),
        .shift_en(sif.shift_en),
        .dir(sif.dir),
        .d_in(sif.d_in),
        .q_out(sif.q_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    shift_reg_environment#(N) env;
    
    initial begin
        $display("========================================");
        $display("       Shift Register Testbench        ");
        $display("========================================\n");
        
        env = new(sif);
        env.run();
        #100; // Wait for all transactions to complete
        env.report();
        $finish;
    end

endmodule