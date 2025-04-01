create_clock -period 20.000 -name CLK [get_ports CLK]
create_clock -period 40.000 -name p_clk [get_ports p_clk]

set_property PACKAGE_PIN R2 [get_ports CLK]
set_property PACKAGE_PIN P4 [get_ports p_clk]
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

set_property PACKAGE_PIN V8 [get_ports {i_data[7]}]
set_property PACKAGE_PIN U7 [get_ports {i_data[6]}]
set_property PACKAGE_PIN T7 [get_ports {i_data[5]}]
set_property PACKAGE_PIN R6 [get_ports {i_data[4]}]
set_property PACKAGE_PIN R5 [get_ports {i_data[3]}]
set_property PACKAGE_PIN U6 [get_ports {i_data[2]}]
set_property PACKAGE_PIN V4 [get_ports {i_data[1]}]
set_property PACKAGE_PIN V3 [get_ports {i_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports p_clk]
set_property IOSTANDARD LVCMOS33 [get_ports o_data]
set_property IOSTANDARD LVCMOS33 [get_ports h_sync]

set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[1]}]

set_property PACKAGE_PIN P16 [get_ports o_clk_en]
set_property IOSTANDARD LVCMOS33 [get_ports o_clk_en]
set_property PACKAGE_PIN R16 [get_ports o_clk_en]
set_property IOSTANDARD LVCMOS33 [get_ports o_clk_en]

set_property PACKAGE_PIN N16 [get_ports o_dqm[1]]
set_property IOSTANDARD LVCMOS33 [get_ports o_dqm[1]]
set_property PACKAGE_PIN V16 [get_ports o_dqm[0]]
set_property IOSTANDARD LVCMOS33 [get_ports o_dqm[0]]

set_property PACKAGE_PIN U14 [get_ports o_cas_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_cas_n]
set_property PACKAGE_PIN V14 [get_ports o_ras_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_ras_n]
set_property PACKAGE_PIN U15 [get_ports o_we_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_we_n]
set_property PACKAGE_PIN V13 [get_ports o_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_cs_n]

set_property PACKAGE_PIN U12 [get_ports o_bank[1]]
set_property IOSTANDARD LVCMOS33 [get_ports o_bank[1]]
set_property PACKAGE_PIN V12 [get_ports o_bank[0]]
set_property IOSTANDARD LVCMOS33 [get_ports o_bank[0]]

set_property PACKAGE_PIN P15 [get_ports o_addr[12]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[12]]
set_property PACKAGE_PIN R15 [get_ports o_addr[11]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[11]]
set_property PACKAGE_PIN V11 [get_ports o_addr[10]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[10]]
set_property PACKAGE_PIN T15 [get_ports o_addr[9]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[9]]
set_property PACKAGE_PIN P14 [get_ports o_addr[8]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[8]]
set_property PACKAGE_PIN T14 [get_ports o_addr[7]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[7]]
set_property PACKAGE_PIN T13 [get_ports o_addr[6]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[6]]
set_property PACKAGE_PIN R13 [get_ports o_addr[5]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[5]]
set_property PACKAGE_PIN T12 [get_ports o_addr[4]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[4]]
set_property PACKAGE_PIN U9 [get_ports o_addr[3]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[3]]
set_property PACKAGE_PIN V9 [get_ports o_addr[2]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[2]]
set_property PACKAGE_PIN U10 [get_ports o_addr[1]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[1]]
set_property PACKAGE_PIN U11 [get_ports o_addr[0]]
set_property IOSTANDARD LVCMOS33 [get_ports o_addr[0]]

set_property PACKAGE_PIN P18 [get_ports io_data[0]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[0]]
set_property PACKAGE_PIN R18 [get_ports io_data[1]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[1]]
set_property PACKAGE_PIN R17 [get_ports io_data[2]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[2]]
set_property PACKAGE_PIN T18 [get_ports io_data[3]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[3]]
set_property PACKAGE_PIN T17 [get_ports io_data[4]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[4]]
set_property PACKAGE_PIN U17 [get_ports io_data[5]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[5]]
set_property PACKAGE_PIN V17 [get_ports io_data[6]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[6]]
set_property PACKAGE_PIN U16 [get_ports io_data[7]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[7]]
set_property PACKAGE_PIN N17 [get_ports io_data[8]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[8]]
set_property PACKAGE_PIN N18 [get_ports io_data[9]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[9]]
set_property PACKAGE_PIN M16 [get_ports io_data[10]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[10]]
set_property PACKAGE_PIN M17 [get_ports io_data[11]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[11]]
set_property PACKAGE_PIN K17 [get_ports io_data[12]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[12]]
set_property PACKAGE_PIN L18 [get_ports io_data[13]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[13]]
set_property PACKAGE_PIN K18 [get_ports io_data[14]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[14]]
set_property PACKAGE_PIN J18 [get_ports io_data[15]]
set_property IOSTANDARD LVCMOS33 [get_ports io_data[15]]

set_property PACKAGE_PIN F18 [get_ports o_data]
set_property IOSTANDARD LVCMOS33 [get_ports o_data]
set_property PACKAGE_PIN D18 [get_ports h_sync]
set_property IOSTANDARD LVCMOS33 [get_ports h_sync]
set_property PACKAGE_PIN C17 [get_ports v_sync]
set_property IOSTANDARD LVCMOS33 [get_ports v_sync]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property SLEW FAST [get_ports o_data]
set_property DRIVE 12 [get_ports o_data]

