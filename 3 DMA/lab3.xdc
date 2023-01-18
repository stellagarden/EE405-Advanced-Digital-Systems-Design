set_property PACKAGE_PIN E3 [get_ports diff_clock_rtl_clk_p]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports diff_clock_rtl_clk_p]

## LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {o_led[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {o_led[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {o_led[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {o_led[3]}]
