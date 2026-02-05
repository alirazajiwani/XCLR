# VGA Controller with Frame Buffer

A fully functional VGA controller implementation in SystemVerilog designed for FPGA deployment. This project generates VGA timing signals and displays images from a frame buffer at 160×100 resolution.

## 🎯 Features

- **Custom VGA Timing Generator**: FSM-based implementation for precise horizontal and vertical sync signals
- **160×100 Resolution**: Low-resolution display optimized for FPGA resources
- **Frame Buffer**: SRAM-based memory storing 24-bit RGB color data
- **Clock Management**: Configurable clock divider from 50 MHz to ~1.3 MHz pixel clock
- **Comprehensive Testbench**: SystemVerilog UVM-style layered testbench with functional coverage
- **100% Verification**: All pixels validated with 95.33% functional coverage

## 📁 Project Structure

```
├── src/
  ├── vga_top.sv              # Top-level module integrating all components
  ├── vga_timing.sv           # VGA timing controller with FSM
  ├── frame_buffer.sv         # Frame buffer memory (160×100 pixels)
  ├── clock_divider.sv        # Clock frequency divider
  └──  SourceImage.hex         # Image data in hexadecimal format (required)
├──testbench/
  ├── vga_top_tb.sv           # Main testbench file
  └──  vga_tb_package.sv       # Testbench package with classes and coverage

```

## 🔧 Hardware Requirements

- **FPGA**: DE1-SoC or compatible board with VGA output
- **Clock**: 50 MHz input clock
- **Outputs**: 8-bit VGA DAC (R, G, B) + sync signals

## 🚀 Quick Start

### Prerequisites

- ModelSim/QuestaSim for simulation
- Quartus Prime for synthesis (Intel FPGAs)
- SystemVerilog-compatible simulator

## 📊 Module Descriptions

### `vga_top`
Top-level integration module connecting:
- Clock divider (50 MHz → ~1.3 MHz)
- VGA timing generator
- Frame buffer
- Output signal management

### `vga_timing`
Generates VGA timing signals using dual FSM architecture:
- **Horizontal FSM**: Manages H-sync, front porch, back porch, and active region
- **Vertical FSM**: Controls V-sync and line progression
- **Outputs**: Pixel coordinates (x, y), sync signals, active video flag

#### Timing Parameters
| Parameter | Value | Description |
|-----------|-------|-------------|
| H_A       | 160   | Horizontal active pixels |
| H_FP      | 8     | Horizontal front porch |
| H_S       | 8     | Horizontal sync |
| H_BP      | 16    | Horizontal back porch |
| V_A       | 100   | Vertical active lines |
| V_FP      | 3     | Vertical front porch |
| V_S       | 6     | Vertical sync |
| V_BP      | 6     | Vertical back porch |

**Total Frame Size**: 192 × 115 = 22,080 clocks per frame

### `frame_buffer`
- Stores 16,000 pixels (160×100)
- 24-bit color depth per pixel
- Reads from `SourceImage.hex` at initialization
- Synchronous read operation with address calculation: `addr = y × 160 + x`

### `clock_divider`
- Divides 50 MHz input to ~1.3 MHz output
- Division ratio: 50 MHz / (2 × 19) = 1.316 MHz
- Provides pixel clock for VGA timing

## 🧪 Testbench Architecture

The verification environment uses a layered UVM-style approach:

### Components

1. **vga_config**: Configuration parameters
2. **vga_transaction**: Pixel data and timing information
3. **vga_generator**: Generates expected golden reference
4. **vga_monitor**: Captures DUT outputs
5. **vga_scoreboard**: Compares actual vs expected with coverage
6. **vga_environment**: Orchestrates all components

### Coverage Groups

- **Timing Coverage**: H-sync and V-sync transitions
- **Pixel Position Coverage**: All display regions
- **Color Coverage**: RGB value ranges
- **Frame Coverage**: Frame number tracking

### Test Results

From simulation transcript:
<img width="1366" height="768" alt="Transcript" src="https://github.com/user-attachments/assets/f5527353-2e72-4285-acd4-dcbb48e1fac4" />


## 📈 Simulation Results

### Timing Diagram
The waveform shows:
- **Green (reset_n)**: Active-low reset signal
- **Red/Blue (VGA_R/B)**: 8-bit color values during active video
- **VGA_HS**: Horizontal sync pulses
- **VGA_VS**: Vertical sync pulses (3 frames visible)
- **VGA_BLANK_N**: Active video region indicator
- **VGA_SYNC_N**: Tied to 0 (separate sync mode)
<img width="1366" height="768" alt="Timing Diagram" src="https://github.com/user-attachments/assets/9d435d45-a8bd-410a-88ae-fc88f4a0d97b" />

### Performance
- **Simulation Time**: ~5 seconds for 3 complete frames
- **Frame Rate**: ~60 Hz at 1.3 MHz pixel clock
- **Pixel Verification**: All 48,000 pixels across 3 frames validated

## 🖼️ Creating Source Image

To create your own `SourceImage.hex`:

```python
# Python script example
from PIL import Image

# Load and resize image to 160x100
img = Image.open('input.png').resize((160, 100))
pixels = img.load()

with open('SourceImage.hex', 'w') as f:
    for y in range(100):
        for x in range(160):
            r, g, b = pixels[x, y]
            f.write(f'{r:02x}{g:02x}{b:02x}\n')
```

## 🔍 Debugging Tips

1. **No Display**:
   - Verify clock divider ratio
   - Check VGA cable connection
   - Ensure `SourceImage.hex` is loaded

2. **Wrong Colors**:
   - Verify RGB bit order in frame buffer
   - Check DAC pin assignments
   - Validate hex file format

3. **Sync Issues**:
   - Monitor hsync/vsync timing in simulation
   - Verify timing parameters match monitor requirements
   - Check active_video signal alignment

---

**Note**: This implementation uses non-standard VGA timing (160×100) optimized for FPGA resources. Standard VGA monitors may not support this resolution. Consider implementing 640×480 for broader compatibility.
