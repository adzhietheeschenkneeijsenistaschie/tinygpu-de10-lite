# tinygpu-de10-lite

A DE10-Lite adaptation of adam-maj’s tiny-gpu, focused on building a minimal FPGA graphics pipeline with VGA output, framebuffer memory, and host-driven rendering.

## Overview

This project takes inspiration from [`adam-maj/tiny-gpu`](https://github.com/adam-maj/tiny-gpu) and adapts the idea to real FPGA hardware on the **Terasic DE10-Lite**.

The long-term goal is to turn the DE10-Lite into a small, host-driven graphics accelerator:
- Video output generated directly from the FPGA over **VGA**
- Framebuffer stored in on-chip memory first, then optionally extended with **external SDRAM**
- Commands sent from a host computer, initially a **Raspberry Pi 3**
- A path toward hardware-accelerated rendering experiments, starting simple and growing over time

This is not intended to be a modern GPU clone. The goal is to build a small, understandable graphics pipeline that is practical to simulate, verify, synthesize, and extend.

## Project Goals

- Bring up a working VGA output pipeline on the DE10-Lite
- Build a framebuffer-based display system
- Add a host-to-FPGA command interface
- Adapt ideas from `tiny-gpu` into a board-ready design
- Develop the project incrementally with **simulation first**
- Create a foundation for future experiments:
  - hardware blitters
  - texture fetch from SDRAM
  - host-driven rendering
  - Doom acceleration
  - simple ray tracing / BVH traversal research ideas

## Current Direction

The project is being developed in stages.

### Stage 1: FPGA-only bring-up
Focus on hardware that can be built and verified using only the DE10-Lite:
- VGA timing generator
- framebuffer memory
- test patterns
- simple pixel/line/rectangle drawing
- simulation testbenches

### Stage 2: Host interface
Add a command path from a host system:
- SPI slave or similar command interface
- command FIFO
- register-mapped control path
- framebuffer writes from the host

### Stage 3: Rendering pipeline
Move from “draw test patterns” to “accept rendering commands”:
- column/span drawing primitives
- texture reads
- SDRAM-backed assets
- double buffering
- frame swap control

### Stage 4: Doom-oriented work
Use the platform as a hardware rendering target for a modified software engine:
- host-side command generation
- framebuffer flip protocol
- texture upload pipeline
- possible Chocolate Doom integration

## High-Level Architecture

```text
Host Computer / Raspberry Pi
            |
            |  SPI / command stream
            v
+--------------------------------------+
|              DE10-Lite               |
|                                      |
|  +-------------+    +-------------+  |
|  | SPI Slave   | -> | Command FIFO|  |
|  +-------------+    +-------------+  |
|           |              |           |
|           v              v           |
|     +---------------------------+    |
|     | Control / Render Logic    |    |
|     | - register interface      |    |
|     | - draw engine             |    |
|     | - optional tiny-gpu core  |    |
|     +---------------------------+    |
|                  |                   |
|         +------------------+         |
|         | Framebuffer BRAM |         |
|         +------------------+         |
|                  |                   |
|           +-------------+            |
|           | VGA Output  | ----------> Monitor
|           +-------------+            |
|                                      |
|      Optional: external SDRAM        |
|      for textures / larger assets    |
+--------------------------------------+
```

## Design Philosophy

This repo is being built around a few principles:

- **Keep it modular.** Separate VGA, framebuffer, host I/O, rendering, and memory control into independent modules.
- **Verify first.** Every major block should have a simulation testbench before hardware integration.
- **Start with fixed-function graphics.** A simple graphics pipeline is more realistic on this board than a full programmable GPU.
- **Use tiny-gpu as inspiration, not a constraint.** Some parts may be reused directly, while others may need to be wrapped, replaced, or simplified for DE10-Lite hardware.

## Planned Modules

The exact structure may evolve, but the project is expected to include modules like:

- `vga_controller.sv`  
  Generates VGA sync and pixel timing.

- `framebuffer.sv`  
  On-chip framebuffer storage, likely using dual-port block RAM.

- `test_pattern.sv`  
  Simple hardware patterns for initial bring-up.

- `spi_slave.sv`  
  Host command receiver.

- `command_fifo.sv`  
  Buffers host commands safely across timing boundaries.

- `render_core.sv`  
  Draw engine for pixels, spans, columns, or simple primitives.

- `sdram_controller.sv`  
  Optional external memory controller for textures or larger assets.

- `de10_lite_top.sv`  
  Board-level top module connecting clocks, VGA, GPIO, SDRAM, and internal blocks.

## Development Plan

### Part A — VGA bring-up
- [ ] Generate stable VGA timing
- [ ] Display solid colors
- [ ] Display test bars / checkerboards
- [ ] Confirm monitor compatibility
- [ ] Add simulation for sync timing

### Part B — Framebuffer
- [ ] Instantiate block RAM framebuffer
- [ ] Read pixels out through VGA
- [ ] Add write port for draw logic
- [ ] Support at least one simple color mode
- [ ] Add optional double buffering

### Part C — Draw engine
- [ ] Set a single pixel
- [ ] Draw horizontal / vertical lines
- [ ] Draw rectangles
- [ ] Add span / column style commands
- [ ] Define command packet format

### Part D — Host interface
- [ ] Implement SPI slave
- [ ] Receive command words correctly
- [ ] Add command FIFO
- [ ] Expose status / busy flags
- [ ] Create a minimal host-side test program

### Part E — External memory
- [ ] Bring up SDRAM controller
- [ ] Verify read/write with test patterns
- [ ] Add burst support if needed
- [ ] Store textures or other render assets externally

### Part F — Doom path
- [ ] Define host-render command format
- [ ] Upload textures/assets
- [ ] Draw columns/spans from host commands
- [ ] Implement buffer flip protocol
- [ ] Test with a simplified software renderer
- [ ] Explore Chocolate Doom integration

## Toolchain

Planned development flow:
- **Quartus** for synthesis and board programming
- **Questa / ModelSim** for simulation and verification
- **SystemVerilog** for RTL and testbenches

The project is being approached as a verification-heavy hardware build, not just a quick FPGA demo.

## Hardware Target

Primary target:
- **Terasic DE10-Lite**

Planned host:
- **Raspberry Pi 3B**

The DE10-Lite is the main development platform for the first stages, so the early milestones are designed to work even without the Raspberry Pi connected.

## Status

Early development / architecture stage.

Near-term focus:
1. bring up VGA
2. add framebuffer
3. verify drawing path in simulation
4. add host command input later

## Notes on tiny-gpu

This project started as a fork of `adam-maj/tiny-gpu`, but the DE10-Lite adaptation will likely require:
- board-specific top-level integration
- hardware display output
- memory system changes
- command ingestion from an external host
- additional state machines for rendering and control

That means the final design may become a **tiny-gpu-inspired graphics platform** rather than a direct 1:1 port.

## Why this exists

The point of this repo is to learn by building:
- graphics hardware
- FPGA memory systems
- display timing
- host/accelerator communication
- verification workflows
- hardware/software co-design

It is meant to stay understandable, hackable, and educational.

## License

This repository retains the upstream license where applicable and should clearly document any new modules or major changes added for the DE10-Lite adaptation.
