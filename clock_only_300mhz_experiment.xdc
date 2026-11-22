# HISTORICAL TIMING EXPERIMENT ONLY; NOT BOARD CLOCK CONFIGURATION.
# Do not enable this at the same time as clock_only_100mhz.xdc.
create_clock -name sys_clk -period 3.333 -waveform {0.000 1.6665} [get_ports clk]
