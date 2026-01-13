# Sequential Logic

## 📁 Overview

This project implements and verifies various sequential logic components using SystemVerilog. The repository contains both RTL designs and comprehensive testbenches for digital circuits including multipliers, counters, registers, and shift registers.

## 📂 Structure

```
Week 02/
├── src/
│   ├── Adder_Tree.sv          # Adder tree-based multiplier with pipelining
│   ├── counter.sv             # Parameterized up/down counter
│   ├── Multiplier8x8.sv       # 8x8 multiplier with register stages
│   ├── reg32.sv               # 32-bit register with load control
│   └── shift_reg.sv           # Parameterized bidirectional shift register
└── testbenches/
    ├── counter_tb.sv          # UVM-style testbench for counter
    ├── mult_tb.sv             # UVM-style testbench for multiplier
    ├── reg32_tb.sv            # SVA-based testbench for 32-bit register
    └── shift_reg_tb.sv        # UVM-style testbench for shift register
```

## 🔧 Module Descriptions

### 1. **Adder_Tree** (`src/Adder_Tree.sv`)
- **Function**: 8x8 multiplier using adder tree architecture
- **Features**:
  - Pipelined implementation with input/output registers
  - 3-level adder tree (8→4→2→1)
  - 16-bit output to accommodate 8x8 multiplication
  - Synchronous reset

### 2. **counter** (`src/counter.sv`)
- **Function**: Parameterized N-bit up/down counter
- **Features**:
  - Configurable bit-width via parameter `N`
  - Up/down counting mode control
  - Enable signal for counting control
  - Asynchronous active-low reset

### 3. **Multiplier8x8** (`src/Multiplier8x8.sv`)
- **Function**: 8x8 multiplier with input/output registers
- **Features**:
  - Array multiplier architecture using ripple carry adders
  - Input registers with enable signals (EA, EB)
  - Output register for pipelined operation
  - Modular design with separate AND chains and full adders

### 4. **reg32** (`src/reg32.sv`)
- **Function**: 32-bit register with load control
- **Features**:
  - Load enable signal
  - Asynchronous active-low reset
  - Positive edge-triggered flip-flop

### 5. **shift_reg** (`src/shift_reg.sv`)
- **Function**: Parameterized N-bit bidirectional shift register
- **Features**:
  - Configurable bit-width via parameter `N`
  - Left/right shift direction control
  - Shift enable signal
  - Asynchronous active-low reset

## 🧪 Testbench Features

### **counter_tb.sv**
- UVM-style testbench architecture
- Transaction-level modeling
- Scoreboard with expected value checking
- Directed and pseudo-random test generation
- Interface-based communication

### **mult_tb.sv**
- UVM-style testbench for multiplier
- 2-cycle latency handling in scoreboard
- Separate input/output monitors
- Corner case testing (0×0, 255×255, etc.)
- Pseudo-random test generation

### **reg32_tb.sv**
- SVA (SystemVerilog Assertions) based verification
- Property checking for reset, load, and hold behaviors
- Direct test stimulus
- Error reporting for assertion violations

### **shift_reg_tb.sv**
- UVM-style testbench for shift register
- Scoreboard with expected shift calculations
- Directed tests for left/right shifts
- Pseudo-random test generation

## 🚀 Getting Started

### Prerequisites
- SystemVerilog simulator (ModelSim, VCS, QuestaSim, etc.)
- Basic understanding of digital design concepts

### Running Tests
Each testbench can be simulated independently:
1. `counter_tb.sv`: Tests the up/down counter functionality
2. `mult_tb.sv`: Tests the 8x8 multiplier with various inputs
3. `reg32_tb.sv`: Tests the 32-bit register with assertions
4. `shift_reg_tb.sv`: Tests the bidirectional shift register

## 📊 Key Design Features

- **Modular Design**: Each component is independently testable
- **Parameterization**: Counters and shift registers support configurable widths
- **Pipelining**: Multipliers include register stages for timing optimization
- **Synchronous Design**: All modules use positive edge-triggered flip-flops
- **Reset Strategies**: Consistent use of reset signals for initialization

## 🔍 Verification Strategy

1. **Direct Testing**: Corner cases and boundary conditions
2. **Pseudo-Random Testing**: Extensive random stimulus generation
3. **Assertion-Based Verification**: Formal property checking (reg32_tb)
4. **Scoreboard Checking**: Expected vs. actual output comparison
5. **Transaction-Level Modeling**: UVM-inspired testbench architecture

---

**Note**: This project demonstrates SystemVerilog design and verification techniques for sequential logic circuits. The testbenches use UVM-inspired methodologies without requiring the full UVM library, making them portable across different simulation environments.
