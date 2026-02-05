# Sequence Detector - "1011" Pattern Recognition

A robust FSM-based sequence detector implemented in SystemVerilog that identifies the pattern "1011" in a serial bit stream. Features overlapping detection capability and a comprehensive UVM-style verification environment.

## 🎯 Features

- **Pattern Detection**: Detects "1011" sequence in serial input stream
- **Overlapping Support**: Capable of detecting overlapping patterns
- **FSM Architecture**: 5-state Mealy machine implementation
- **Comprehensive Testbench**: Full UVM-style layered verification environment
- **Functional Coverage**: 100% state, transition, input, and output coverage
- **Reference Model**: Golden reference for verification
- **Extensive Test Suite**: 9 targeted test scenarios with 500+ transactions

## 📁 Project Structure

```
├── seq_detector.sv       # Main sequence detector module (RTL)
└── seq_detector_tb.sv    # Comprehensive testbench with coverage
```

## 🔧 Module Overview

### Sequence Detector RTL (`seq_detector.sv`)

**Pattern**: `1011` (overlapping detection supported)

**State Machine**:
```
S0 (IDLE)    -> Wait for first '1'
S1 (GOT_1)   -> Detected '1', wait for '0'
S2 (GOT_10)  -> Detected '10', wait for '1'
S3 (GOT_101) -> Detected '101', wait for '1'
S4 (DETECT)  -> Pattern '1011' detected! (output = 1)
```

**Ports**:
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk | Input | 1 | Clock signal |
| rst_n | Input | 1 | Active-low asynchronous reset |
| in_bit | Input | 1 | Serial input bit stream |
| seq_detected | Output | 1 | High when "1011" is detected |

### State Transition Table

| Current State | Input = 0 | Input = 1 |
|---------------|-----------|-----------|
| S0 (IDLE) | S0 | S1 |
| S1 (GOT_1) | S2 | S1 |
| S2 (GOT_10) | S0 | S3 |
| S3 (GOT_101) | S2 | S4 |
| S4 (DETECT) | S2 | S1 |

**Key Feature**: When in S4 (pattern detected) and next bit is '1', transitions to S1, enabling immediate detection of overlapping patterns like "10**1011**" → "1011**1011**".

## 📊 Test Scenarios

### Test 1: Basic Sequences
- Single occurrence: `1011`
- Multiple occurrences: `10111011`
- Overlapping patterns: `101011`
- No detection: `1010101`

### Test 2: Edge Cases
- All zeros: `0000000000`
- All ones: `1111111111`
- Alternating: `0101010101`
- Near-miss patterns: `1010`, `1001`, `1110`

### Test 3: Overlapping Patterns
- Double overlap: `1010111`
- Continuous: `101101011`
- Back-to-back: `10111011`

### Test 4: Reset Scenarios
- Reset at each state (S0, S1, S2, S3, S4)
- Reset during detection
- Normal operation after reset

### Test 5: Corner Cases
- State-input combinations
- Random balanced 0/1 distribution

### Test 6: Sequence Variations
- Triple overlapping
- Long sequences with multiple patterns

### Test 7: Targeted Coverage
- Systematic state-input combinations
- All transition paths

### Test 8: Output Coverage
- Multiple consecutive detections
- Detection followed by various patterns

### Test 9: Comprehensive Coverage
- All states with different outputs
- Final coverage sweep


## 🚀 Quick Start

### Prerequisites

- ModelSim/QuestaSim or compatible SystemVerilog simulator
- SystemVerilog support (IEEE 1800-2012 or later)

## Output
### Transcript
<img width="314" height="355" alt="Transcript" src="https://github.com/user-attachments/assets/296f529c-3e7a-46b1-96e8-8cff053872df" />


### Waveform
<img width="1010" height="95" alt="Timing Diagram" src="https://github.com/user-attachments/assets/8feedeb3-840e-4b53-9317-0500a13fb9a3" />



## 🔍 Waveform Analysis

### Successful Detection

```
Time   | in_bit | State | seq_detected | Description
-------|--------|-------|--------------|------------------------
0      | 1      | S0→S1 | 0            | First '1' detected
10     | 0      | S1→S2 | 0            | Got '10'
20     | 1      | S2→S3 | 0            | Got '101'
30     | 1      | S3→S4 | 1            | Pattern '1011' detected!
```

### Overlapping Detection

```
Input Stream: 1 0 1 0 1 1
              └──┬──┘
                 └───┬───┘
                    Pattern 1: "1011" at t=30ns
                      Pattern 2: "1011" at t=40ns
```

## 💡 Key Design Features

### Overlapping Pattern Support

The FSM cleverly handles overlapping patterns:
```
Input:  1 0 1 0 1 1
State: S0→S1→S2→S3→S2→S3→S4
              ↑         ↑
            "101"    "1011"
```

When the pattern "10101**1**" is received, after detecting the first "1011" at S4, the next '1' transitions to S1 (not S0), preserving progress toward the next pattern.

### Reset Behavior

- **Asynchronous Reset**: Active-low `rst_n`
- Resets to S0 (IDLE state)
- Output immediately goes to 0
- Can reset at any state during operation

### Mealy Machine Characteristics

- Output depends on **current state AND input**
- Detection occurs combinationally (output = 1 only at S4)
- Fast response time (same cycle as S4 entry)

## 🐛 Debugging Tips

### No Detection When Expected
1. Verify input sequence timing with respect to clock
2. Check reset is deasserted properly
3. Examine state transitions in waveform
4. Ensure pattern is exactly "1011"

### False Detections
1. Verify S4 is only reached after complete "1011" sequence
2. Check for glitches on input signal
3. Validate combinational logic in output assignment

### Simulation Issues
1. Ensure proper timescale (`timescale 1ns/1ps`)
2. Check clock generation (50% duty cycle)
3. Verify reset timing (hold for multiple cycles)


---

**Note**: This detector uses a Mealy FSM where output depends on both state and input. For applications requiring glitch-free outputs, consider a Moore machine variant or register the output.
