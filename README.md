# Audio FIR Filter on FPGA

## Project Overview

This project focuses on the design and implementation of a digital audio FIR (Finite Impulse Response) filter using Verilog HDL on the Intel DE10-Nano Cyclone V SoC FPGA development board.

The design includes a 16-tap FIR filter, ADC interfacing, digital signal processing and DAC output conversion.

The project was implemented and tested on the DE10-Nano hardware.

## Project Objectives

- Design and implement a 16-tap FIR filter using Verilog HDL.
- Interface the AD7265 ADC using an SPI master.
- Perform digital filtering using signed fixed-point arithmetic.
- Convert the filtered digital output into a one-bit stream using a Delta-Sigma DAC.
- Implement and test the design on the DE10-Nano FPGA platform.

## Hardware and Software Requirements

**Hardware**
- Intel DE10-Nano Development Board
- Cyclone V SE SoC FPGA (5CSEBA6U23I7)
- AD7265 ADC

**Software and Tools**
- Intel Quartus Prime
- Questa / ModelSim
- Verilog HDL
- Platform Designer (Qsys)

## Design Modules

### 1. Audio_FIR_Filter.v
Top-level Verilog module for the project, integrating the SoC system.

### 2. fir_filter_16tap.v
Implements a 16-tap FIR filter using signed input samples, coefficients and an accumulator.

### 3. ad7265_spi_master.v
Implements the SPI interface for ADC communication and reads 12-bit digital samples from the AD7265.

### 4. delta_sigma_dac.v
Converts the digital filter output into a one-bit Delta-Sigma output stream.

## FIR Filter Specifications

- Filter Type: Finite Impulse Response (FIR)
- Number of Taps: 16
- Input Data Width: 12 bits
- Output Data Width: 12 bits
- Coefficient Format: Signed Q15
- Accumulator Width: 32 bits

## Simulation and Verification

The FIR filter module was simulated using Questa / ModelSim.

The testbench `tb_fir_filter.v` checks the FIR filter response using:
- Constant input samples.
- Alternating positive and negative input samples.
- Input and output valid signals.

Simulation waveforms can be added in the Documentation folder.

## Hardware Implementation

The project was implemented and tested on the Intel DE10-Nano Cyclone V SE SoC FPGA development board.

The Quartus project files and Platform Designer dependencies are included in this repository.

## Repository Structure

```text
Audio-FIR-Filter-FPGA/
│
├── RTL/
│   ├── Audio_FIR_Filter.v
│   ├── fir_filter_16tap.v
│   ├── ad7265_spi_master.v
│   └── delta_sigma_dac.v
│
├── Testbench/
│   └── tb_fir_filter.v
│
├── Quartus_Project/
│   ├── fir_filter_16tap.qpf
│   ├── fir_filter_16tap.qsf
│   ├── Audio_FIR_Filter.sdc
│   └── output_files/
│       ├── soc_system.qsys
│       ├── soc_system.sopcinfo
│       ├── fir_filter_avalon.v
│       ├── fir_filter_avalon_hw.tcl
│       ├── fir_filter_avalon_slave.v
│       ├── fir_filter_avalon_slave_hw.tcl
│       └── soc_system/
│
├── Software/
│   └── dsp_cli.c
│
├── Documentation/
│
├── Reports/
│
└── README.md
```

## Tools Used

| Tool | Purpose |
|---|---|
| Verilog HDL | RTL design |
| Intel Quartus Prime | FPGA compilation and implementation |
| Questa / ModelSim | Simulation and verification |
| Platform Designer | SoC system integration |

## Author
>  Gaurav Sain