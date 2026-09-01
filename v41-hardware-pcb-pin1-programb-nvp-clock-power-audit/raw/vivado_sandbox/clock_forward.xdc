set_property PACKAGE_PIN D13 [get_ports osc27_d13]
set_property IOSTANDARD LVCMOS33 [get_ports osc27_d13]

# Sandbox-only enable input; T12 is not proposed as a product assignment here.
set_property PACKAGE_PIN T12 [get_ports gate_enable_t12]
set_property IOSTANDARD LVCMOS33 [get_ports gate_enable_t12]

set_property PACKAGE_PIN A14 [get_ports nvp_clk_a14]
set_property IOSTANDARD LVCMOS33 [get_ports nvp_clk_a14]
set_property DRIVE 8 [get_ports nvp_clk_a14]
set_property SLEW SLOW [get_ports nvp_clk_a14]

create_clock -name osc27_in -period 37.037 [get_ports osc27_d13]
set_false_path -from [get_ports gate_enable_t12]
