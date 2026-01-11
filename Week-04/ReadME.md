# SystemVerilog Digital Design & Verification

A collection of parameterized digital design modules implemented in SystemVerilog with comprehensive UVM-style testbenches featuring functional coverage and automated verification.

## 📋 Contents

This repository contains RTL designs and their corresponding verification environments:

1. **ALU (Arithmetic Logic Unit)** - 16-bit configurable ALU with 7 operations
2. **FIFO (First-In-First-Out)** - Synchronous FIFO with configurable depth

## 🔧 Modules

### ALU (Arithmetic Logic Unit)

A parameterized N-bit ALU supporting multiple operations with carry and zero flags.

**Features:**
- Configurable bit width (default: 16-bit)
- Seven operations: ADD, SUB, AND, OR, XOR, SHIFT_LEFT, SHIFT_RIGHT
- Carry flag generation for arithmetic and shift operations
- Zero flag for result detection

**Ports:**
```systemverilog
module ALU #(parameter N = 16)(
    input  logic [N-1:0] A, B,        // Operands
    input  alu_op_t      OP,          // Operation selector
    output logic [N-1:0] Result,      // Result
    output logic         Carry, Zero  // Status flags
);
```

**Operations:**
- `ADD`: Addition with carry out
- `SUB`: Subtraction with borrow indication
- `AND`: Bitwise AND
- `OR`: Bitwise OR
- `XOR`: Bitwise XOR
- `SHIFT_LEFT`: Logical left shift
- `SHIFT_RIGHT`: Logical right shift

### FIFO (First-In-First-Out)

A synchronous FIFO buffer with configurable depth and full/empty status flags.

**Features:**
- Configurable depth (default: 8 entries)
- 16-bit data width
- Full and empty status flags
- Simultaneous read/write support
- Internal counter-based depth tracking

**Ports:**
```systemverilog
module FIFO #(parameter DEPTH = 8)(
    input  logic        clk, rst,           // Clock and reset
    input  logic        write_en, read_en,  // Control signals
    input  logic [15:0] data_in,            // Write data
    output logic [15:0] data_out,           // Read data
    output logic        full, empty         // Status flags
);
```

**Behavior:**
- Writes are ignored when FIFO is full
- Reads are ignored when FIFO is empty
- Supports simultaneous read and write operations
- Registered output for stable data

## 🧪 Verification

Both modules include comprehensive UVM-style testbenches.

### Key Features

**Transaction Class:**
- Randomized test stimulus generation
- Constrained random testing
- Display methods for debugging

**Coverage Class:**
- Comprehensive functional coverage
- Corner case tracking
- Cross-coverage for complex scenarios
- Coverage reporting

**Generator:**
- Directed edge case testing
- Constrained random test generation
- Configurable number of transactions

**Driver:**
- Clock-synchronized stimulus application
- Interface-based communication

**Monitor:**
- Non-intrusive observation
- Captures all DUT signals

**Scoreboard:**
- Golden reference model
- Automatic result checking
- Pass/fail statistics
- Integration with coverage

### ALU Testbench Coverage

- All 7 operations
- Corner cases (0x0000, 0xFFFF)
- Carry flag scenarios
- Zero flag detection
- Operation × Carry cross-coverage
- Operation × Zero flag cross-coverage

### FIFO Testbench Coverage

- Full and empty conditions
- Write when full attempts
- Read when empty attempts
- Simultaneous read/write operations
- Corner case data patterns
- All operational state combinations

## 🚀 Usage

### Customizing Tests

Modify the number of random transactions in the testbench:

```systemverilog
// In ALU_tb or FIFO_tb
env = new(vif, 50);  // Change 50 to desired number
```

## 📊 Test Results

The testbenches provide detailed reporting:

- **Real-time transaction monitoring** with timestamped displays
- **Pass/fail status** for each test
- **Summary statistics** (total tests, passed, failed, pass rate)
- **Functional coverage** percentage
- **Queue status** tracking (FIFO only)

Example output:
```
========================================
         TEST SUMMARY
========================================
Total Tests: 52
Passed:      52
Failed:      0
Pass Rate:   100.00%
========================================
      COVERAGE REPORT
========================================
Overall Coverage: 98.50%
========================================
```

## 🛠️ Design Methodology

- **Parameterized designs** for reusability
- **Clean separation** of combinational and sequential logic
- **Comprehensive edge case** handling
- **Industry-standard** verification practices
- **Self-checking** testbenches with automatic pass/fail

## 📝 File Structure

```
Processor Units/
├── src/
│   ├── ALU.sv              # ALU RTL design
│   └── FIFO.sv             # FIFO RTL design
├── testbench/
│   ├── ALU_tb.sv           # ALU testbench with verification environment
│   └── FIFO_tb.sv          # FIFO testbench with verification environment
└── README.md               # This file
```


---

**Note:** These designs are suitable for FPGA/ASIC implementation after synthesis and timing analysis.
