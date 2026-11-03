# 50 MHz FPGA System Clock (20.000 ns period)
create_clock -name {FPGA_CLK1_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {FPGA_CLK1_50}]

# Derive automatic clock uncertainty
derive_clock_uncertainty