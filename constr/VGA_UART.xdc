create_clock -period 20.000 -name CLK [get_ports CLK]

set_property PACKAGE_PIN R2 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

set_property PACKAGE_PIN H18 [get_ports RST]
set_property IOSTANDARD LVCMOS33 [get_ports RST]

set_property IOSTANDARD LVCMOS33 [get_ports {i_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[0]}]
