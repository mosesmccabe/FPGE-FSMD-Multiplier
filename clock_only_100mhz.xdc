# Clock-only timing experiment; NOT sufficient for Basys 3 hardware programming.
# Physical package pin and IOSTANDARD assignments still required.
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} [get_ports clk]
