# Design of an OS-Capable RISC-V Processor for AI SoCs on FPGA

> A complete hardware/software co-design implementation of a RISC-V processor deployed on the Kria KR260 FPGA, running bare-metal C algorithms and communicating with an ARM host controller.

## Repository Structure

```text
├── fpga_workspace/ # Bare-metal C code, ARM host controller, bitstream, and deployment scripts
├── rtl/            # Verilog/SystemVerilog source files for the RISC-V processor core
├── tb/             # Testbench files and verification environment for RTL simulation
├── wrapper/        # Top-level integration, AXI interfaces, and BRAM wrappers
└── README.md
```

## Overview
This repository contains the RTL design and physical FPGA deployment environment for an OS-capable RISC-V processor. Designed to function within an AI System-on-Chip (SoC), the processor is implemented on the **Kria KR260 FPGA**. It operates in tandem with an ARM host controller running Debian Linux, establishing a seamless hardware-software communication pipeline via Block RAM (BRAM).

## Key Features
* **Hardware-Software Co-Design:** Integrates a custom RISC-V microarchitecture with a physical ARM processor on the Kria KR260 platform.
* **Multi-core Communication:** Utilizes shared Block RAM (BRAM) for high-speed data exchange between the ARM host and the RISC-V core.
* **Automated Deployment Pipeline:** Features a robust Linux Bash scripting environment (`run_all.sh`) that automates GCC cross-compilation (`gcc-riscv64-unknown-elf`), hex formatting, hardware bitstream flashing via `fpga_manager`, and ARM host execution.
* **Bare-Metal C Execution:** Supports the compilation and execution of custom bare-metal C algorithms directly on the FPGA fabric without requiring a standard C library.

## Implementation Target
The system is physically synthesized, routed, and verified on real hardware:
* **Target Board:** Xilinx Kria KR260 Robotics Starter Kit
* **Operating System (Host):** Debian 11 Linux
* **Toolchains:** Xilinx Vivado (Hardware), GCC RISC-V Cross-Compiler (Software)

## How to Run & Deploy
The execution flow is highly automated to minimize manual terminal commands. Follow these steps to compile and deploy the system directly on the KR260 board:

### 1. Setup the Workspace
* Connect to the Kria KR260 board via SSH.
* Navigate to the directory containing the `fpga_workspace/`.
* Ensure all dependencies (e.g., `gcc-riscv64-unknown-elf`, `build-essential`) are installed on the board's OS.

### 2. One-Click Build & Execution
* Place your target RISC-V bare-metal C code in the `fpga_workspace/riscv_code/` directory.
* Run the automation script from the terminal:
  ```bash
  chmod +x run_all.sh
  ./run_all.sh
  ```
* The script will automatically:
  1. Configure the FPGA hardware with the provided bitstream (`rv32imc_soc_wrapper.bit`).
  2. Cross-compile the RISC-V code and generate the `program.hex` memory file.
  3. Compile the ARM host controller code (`main.c`).
  4. Load the data into BRAM and trigger the RISC-V execution to verify the results.

---
*Developed by Võ Thanh Toàn  under the guidance of Advisor Phạm Hoài Luân at Trường Đại học Công nghệ Thông tin (UIT) - ĐHQG-HCM.*
