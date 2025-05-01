# VGA-UART-FPGA

This is a repository for my 2025 Bachelor thesis for Ukrainian Catholic University, on the topic *"Real-time VGA to UART converter using FPGA"*

Implements a real-time video frame transmitter using UART with a custom-designed compression algorithm; originally, for low-end Xilinx FPGAs.

The hardware components initially used for implementation:

- Xilinx Artix-7 FPGA
- OV7670 camera module
- 32MB SDRAM
- FT232H UART module

**Testing**

The `sim` directory contains the `*_tb.v` files for essential modules, originally intended for Vivado's Behavioral Simulation tool. Also, it provides the `UART_wrapper.v` file that is intended for conducting on-hardware performance measurements when simulating the system's video input. `packet_decomp.py` should be used alongside for packet parsing and video frame rendering.

**Implementation details**

The details and specifics of this design, as well as the measurements and resource usage statistics, are provided in the thesis paper, the link to which will be added here once it is available for public citing.
