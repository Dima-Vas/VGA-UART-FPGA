create_clock -period 20.000 -name CLK [get_ports CLK]
create_clock -period 80.000 -name x_clk [get_ports x_clk]
create_clock -period 162.760 -name p_clk [get_ports p_clk]

set_property PACKAGE_PIN R2 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

set_property PACKAGE_PIN H18 [get_ports RST]
set_property IOSTANDARD LVCMOS33 [get_ports RST]

set_false_path -from [get_ports RST]

set_property PACKAGE_PIN F18 [get_ports o_data]
set_property IOSTANDARD LVCMOS33 [get_ports o_data]


# ------------- OV7670 -------------
set_property PACKAGE_PIN P4 [get_ports p_clk]
set_property IOSTANDARD LVCMOS33 [get_ports p_clk]

set_property PACKAGE_PIN F14 [get_ports h_sync]
set_property IOSTANDARD LVCMOS33 [get_ports h_sync]

set_property PACKAGE_PIN A13 [get_ports v_sync]
set_property IOSTANDARD LVCMOS33 [get_ports v_sync]

set_property PACKAGE_PIN R3 [get_ports x_clk]
set_property IOSTANDARD LVCMOS33 [get_ports x_clk]

set_property PACKAGE_PIN F15 [get_ports o_sio_c]
set_property IOSTANDARD LVCMOS33 [get_ports o_sio_c]

set_property PACKAGE_PIN G15 [get_ports o_sio_d]
set_property IOSTANDARD LVCMOS33 [get_ports o_sio_d]

set_property IOSTANDARD LVCMOS33 [get_ports {i_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[0]}]

set_property PACKAGE_PIN E16 [get_ports {i_data[7]}]
set_property PACKAGE_PIN A15 [get_ports {i_data[6]}]
set_property PACKAGE_PIN D16 [get_ports {i_data[5]}]
set_property PACKAGE_PIN A14 [get_ports {i_data[4]}]
set_property PACKAGE_PIN A17 [get_ports {i_data[3]}]
set_property PACKAGE_PIN C14 [get_ports {i_data[2]}]
set_property PACKAGE_PIN C16 [get_ports {i_data[1]}]
set_property PACKAGE_PIN C13 [get_ports {i_data[0]}]


# ------------- SDRAM -------------

set_property PACKAGE_PIN P16 [get_ports o_clk_en]
set_property IOSTANDARD LVCMOS33 [get_ports o_clk_en]

set_property PACKAGE_PIN N16 [get_ports {o_dqm[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_dqm[1]}]
set_property PACKAGE_PIN V16 [get_ports {o_dqm[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_dqm[0]}]

set_property PACKAGE_PIN U14 [get_ports o_cas_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_cas_n]
set_property PACKAGE_PIN V14 [get_ports o_ras_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_ras_n]
set_property PACKAGE_PIN U15 [get_ports o_we_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_we_n]
set_property PACKAGE_PIN V13 [get_ports o_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports o_cs_n]

set_property PACKAGE_PIN U12 [get_ports {o_bank[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_bank[1]}]
set_property PACKAGE_PIN V12 [get_ports {o_bank[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_bank[0]}]

set_property PACKAGE_PIN P15 [get_ports {o_addr[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[12]}]
set_property PACKAGE_PIN R15 [get_ports {o_addr[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[11]}]
set_property PACKAGE_PIN V11 [get_ports {o_addr[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[10]}]
set_property PACKAGE_PIN T15 [get_ports {o_addr[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[9]}]
set_property PACKAGE_PIN P14 [get_ports {o_addr[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[8]}]
set_property PACKAGE_PIN T14 [get_ports {o_addr[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[7]}]
set_property PACKAGE_PIN T13 [get_ports {o_addr[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[6]}]
set_property PACKAGE_PIN R13 [get_ports {o_addr[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[5]}]
set_property PACKAGE_PIN T12 [get_ports {o_addr[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[4]}]
set_property PACKAGE_PIN U9 [get_ports {o_addr[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[3]}]
set_property PACKAGE_PIN V9 [get_ports {o_addr[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[2]}]
set_property PACKAGE_PIN U10 [get_ports {o_addr[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[1]}]
set_property PACKAGE_PIN U11 [get_ports {o_addr[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_addr[0]}]

set_property PACKAGE_PIN P18 [get_ports {io_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[0]}]
set_property PACKAGE_PIN R18 [get_ports {io_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[1]}]
set_property PACKAGE_PIN R17 [get_ports {io_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[2]}]
set_property PACKAGE_PIN T18 [get_ports {io_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[3]}]
set_property PACKAGE_PIN T17 [get_ports {io_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[4]}]
set_property PACKAGE_PIN U17 [get_ports {io_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[5]}]
set_property PACKAGE_PIN V17 [get_ports {io_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[6]}]
set_property PACKAGE_PIN U16 [get_ports {io_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[7]}]
set_property PACKAGE_PIN N17 [get_ports {io_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[8]}]
set_property PACKAGE_PIN N18 [get_ports {io_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[9]}]
set_property PACKAGE_PIN M16 [get_ports {io_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[10]}]
set_property PACKAGE_PIN M17 [get_ports {io_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[11]}]
set_property PACKAGE_PIN K17 [get_ports {io_data[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[12]}]
set_property PACKAGE_PIN L18 [get_ports {io_data[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[13]}]
set_property PACKAGE_PIN K18 [get_ports {io_data[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[14]}]
set_property PACKAGE_PIN J18 [get_ports {io_data[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_data[15]}]


# ------------- Timing constraints ---------
set_input_delay -clock p_clk 6.000 [get_ports {{i_data[*]} h_sync v_sync}]
set_input_delay -clock p_clk -min 2.000 [get_ports {{i_data[*]} h_sync v_sync}]

set_output_delay -clock CLK 6.000 [get_ports {o_sio_c o_sio_d}]
set_output_delay -clock CLK -min 2.000 [get_ports {o_sio_c o_sio_d}]

set_output_delay -clock CLK 3.000 [get_ports {{o_addr[*]} {o_bank[*]} o_we_n o_cas_n o_ras_n o_cs_n {o_dqm[*]} {io_data[*]}}]
set_output_delay -clock CLK -min 1.000 [get_ports {{o_addr[*]} {o_bank[*]} o_we_n o_cas_n o_ras_n o_cs_n {o_dqm[*]} {io_data[*]}}]

set_input_delay -clock CLK 5.000 [get_ports {io_data[*]}]
set_input_delay -clock CLK -min 2.000 [get_ports {io_data[*]}]

set_input_delay -clock CLK 3.000 [get_ports RST]
set_input_delay -clock CLK -min 1.000 [get_ports RST]

set_input_delay -clock p_clk 3.000 [get_ports RST]
set_input_delay -clock p_clk -min 1.000 [get_ports RST]

set_output_delay -clock CLK 6.000 [get_ports o_data]
set_output_delay -clock CLK -min 2.000 [get_ports o_data]

# ------------- Misc -----------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property SLEW FAST [get_ports o_data]
set_property DRIVE 12 [get_ports o_data]

set_clock_groups -asynchronous -group [get_clocks CLK] -group [get_clocks p_clk]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]




connect_debug_port u_ila_0/probe4 [get_nets [list {facade/write/CurrentState__0[0]}]]
connect_debug_port u_ila_0/probe6 [get_nets [list {facade/write/CurrentState[0]}]]
connect_debug_port u_ila_0/probe12 [get_nets [list {facade/PixelsForSDRAM_reg[0][15][0]} {facade/PixelsForSDRAM_reg[0][15][1]} {facade/PixelsForSDRAM_reg[0][15][2]} {facade/PixelsForSDRAM_reg[0][15][3]} {facade/PixelsForSDRAM_reg[0][15][4]} {facade/PixelsForSDRAM_reg[0][15][5]} {facade/PixelsForSDRAM_reg[0][15][6]} {facade/PixelsForSDRAM_reg[0][15][7]} {facade/PixelsForSDRAM_reg[0][15][8]} {facade/PixelsForSDRAM_reg[0][15][9]} {facade/PixelsForSDRAM_reg[0][15][10]} {facade/PixelsForSDRAM_reg[0][15][11]} {facade/PixelsForSDRAM_reg[0][15][12]} {facade/PixelsForSDRAM_reg[0][15][13]} {facade/PixelsForSDRAM_reg[0][15][14]} {facade/PixelsForSDRAM_reg[0][15][15]}]]
connect_debug_port u_ila_0/probe25 [get_nets [list facade/write/HeadAddressSDRAM]]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list CLK_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {facade/write/PixelsForSDRAM_reg[5][0]} {facade/write/PixelsForSDRAM_reg[5][1]} {facade/write/PixelsForSDRAM_reg[5][2]} {facade/write/PixelsForSDRAM_reg[5][3]} {facade/write/PixelsForSDRAM_reg[5][4]} {facade/write/PixelsForSDRAM_reg[5][5]} {facade/write/PixelsForSDRAM_reg[5][6]} {facade/write/PixelsForSDRAM_reg[5][7]} {facade/write/PixelsForSDRAM_reg[5][8]} {facade/write/PixelsForSDRAM_reg[5][9]} {facade/write/PixelsForSDRAM_reg[5][10]} {facade/write/PixelsForSDRAM_reg[5][11]} {facade/write/PixelsForSDRAM_reg[5][12]} {facade/write/PixelsForSDRAM_reg[5][13]} {facade/write/PixelsForSDRAM_reg[5][14]} {facade/write/PixelsForSDRAM_reg[5][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {facade/write/PixelsForSDRAM_reg[2][0]} {facade/write/PixelsForSDRAM_reg[2][1]} {facade/write/PixelsForSDRAM_reg[2][2]} {facade/write/PixelsForSDRAM_reg[2][3]} {facade/write/PixelsForSDRAM_reg[2][4]} {facade/write/PixelsForSDRAM_reg[2][5]} {facade/write/PixelsForSDRAM_reg[2][6]} {facade/write/PixelsForSDRAM_reg[2][7]} {facade/write/PixelsForSDRAM_reg[2][8]} {facade/write/PixelsForSDRAM_reg[2][9]} {facade/write/PixelsForSDRAM_reg[2][10]} {facade/write/PixelsForSDRAM_reg[2][11]} {facade/write/PixelsForSDRAM_reg[2][12]} {facade/write/PixelsForSDRAM_reg[2][13]} {facade/write/PixelsForSDRAM_reg[2][14]} {facade/write/PixelsForSDRAM_reg[2][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 16 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {facade/write/PixelsForSDRAM_reg[1][15]_0[0]} {facade/write/PixelsForSDRAM_reg[1][15]_0[1]} {facade/write/PixelsForSDRAM_reg[1][15]_0[2]} {facade/write/PixelsForSDRAM_reg[1][15]_0[3]} {facade/write/PixelsForSDRAM_reg[1][15]_0[4]} {facade/write/PixelsForSDRAM_reg[1][15]_0[5]} {facade/write/PixelsForSDRAM_reg[1][15]_0[6]} {facade/write/PixelsForSDRAM_reg[1][15]_0[7]} {facade/write/PixelsForSDRAM_reg[1][15]_0[8]} {facade/write/PixelsForSDRAM_reg[1][15]_0[9]} {facade/write/PixelsForSDRAM_reg[1][15]_0[10]} {facade/write/PixelsForSDRAM_reg[1][15]_0[11]} {facade/write/PixelsForSDRAM_reg[1][15]_0[12]} {facade/write/PixelsForSDRAM_reg[1][15]_0[13]} {facade/write/PixelsForSDRAM_reg[1][15]_0[14]} {facade/write/PixelsForSDRAM_reg[1][15]_0[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {facade/write/PixelsForSDRAM_reg[0][0]} {facade/write/PixelsForSDRAM_reg[0][1]} {facade/write/PixelsForSDRAM_reg[0][2]} {facade/write/PixelsForSDRAM_reg[0][3]} {facade/write/PixelsForSDRAM_reg[0][4]} {facade/write/PixelsForSDRAM_reg[0][5]} {facade/write/PixelsForSDRAM_reg[0][6]} {facade/write/PixelsForSDRAM_reg[0][7]} {facade/write/PixelsForSDRAM_reg[0][8]} {facade/write/PixelsForSDRAM_reg[0][9]} {facade/write/PixelsForSDRAM_reg[0][10]} {facade/write/PixelsForSDRAM_reg[0][11]} {facade/write/PixelsForSDRAM_reg[0][12]} {facade/write/PixelsForSDRAM_reg[0][13]} {facade/write/PixelsForSDRAM_reg[0][14]} {facade/write/PixelsForSDRAM_reg[0][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {facade/write/PixelsForSDRAM_reg[1][0]} {facade/write/PixelsForSDRAM_reg[1][1]} {facade/write/PixelsForSDRAM_reg[1][2]} {facade/write/PixelsForSDRAM_reg[1][3]} {facade/write/PixelsForSDRAM_reg[1][4]} {facade/write/PixelsForSDRAM_reg[1][5]} {facade/write/PixelsForSDRAM_reg[1][6]} {facade/write/PixelsForSDRAM_reg[1][7]} {facade/write/PixelsForSDRAM_reg[1][8]} {facade/write/PixelsForSDRAM_reg[1][9]} {facade/write/PixelsForSDRAM_reg[1][10]} {facade/write/PixelsForSDRAM_reg[1][11]} {facade/write/PixelsForSDRAM_reg[1][12]} {facade/write/PixelsForSDRAM_reg[1][13]} {facade/write/PixelsForSDRAM_reg[1][14]} {facade/write/PixelsForSDRAM_reg[1][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {facade/write/PixelsForSDRAM_reg[3][0]} {facade/write/PixelsForSDRAM_reg[3][1]} {facade/write/PixelsForSDRAM_reg[3][2]} {facade/write/PixelsForSDRAM_reg[3][3]} {facade/write/PixelsForSDRAM_reg[3][4]} {facade/write/PixelsForSDRAM_reg[3][5]} {facade/write/PixelsForSDRAM_reg[3][6]} {facade/write/PixelsForSDRAM_reg[3][7]} {facade/write/PixelsForSDRAM_reg[3][8]} {facade/write/PixelsForSDRAM_reg[3][9]} {facade/write/PixelsForSDRAM_reg[3][10]} {facade/write/PixelsForSDRAM_reg[3][11]} {facade/write/PixelsForSDRAM_reg[3][12]} {facade/write/PixelsForSDRAM_reg[3][13]} {facade/write/PixelsForSDRAM_reg[3][14]} {facade/write/PixelsForSDRAM_reg[3][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {facade/write/PixelsForSDRAM_reg[4][0]} {facade/write/PixelsForSDRAM_reg[4][1]} {facade/write/PixelsForSDRAM_reg[4][2]} {facade/write/PixelsForSDRAM_reg[4][3]} {facade/write/PixelsForSDRAM_reg[4][4]} {facade/write/PixelsForSDRAM_reg[4][5]} {facade/write/PixelsForSDRAM_reg[4][6]} {facade/write/PixelsForSDRAM_reg[4][7]} {facade/write/PixelsForSDRAM_reg[4][8]} {facade/write/PixelsForSDRAM_reg[4][9]} {facade/write/PixelsForSDRAM_reg[4][10]} {facade/write/PixelsForSDRAM_reg[4][11]} {facade/write/PixelsForSDRAM_reg[4][12]} {facade/write/PixelsForSDRAM_reg[4][13]} {facade/write/PixelsForSDRAM_reg[4][14]} {facade/write/PixelsForSDRAM_reg[4][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 16 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {facade/write/PixelsForSDRAM_reg[7][0]} {facade/write/PixelsForSDRAM_reg[7][1]} {facade/write/PixelsForSDRAM_reg[7][2]} {facade/write/PixelsForSDRAM_reg[7][3]} {facade/write/PixelsForSDRAM_reg[7][4]} {facade/write/PixelsForSDRAM_reg[7][5]} {facade/write/PixelsForSDRAM_reg[7][6]} {facade/write/PixelsForSDRAM_reg[7][7]} {facade/write/PixelsForSDRAM_reg[7][8]} {facade/write/PixelsForSDRAM_reg[7][9]} {facade/write/PixelsForSDRAM_reg[7][10]} {facade/write/PixelsForSDRAM_reg[7][11]} {facade/write/PixelsForSDRAM_reg[7][12]} {facade/write/PixelsForSDRAM_reg[7][13]} {facade/write/PixelsForSDRAM_reg[7][14]} {facade/write/PixelsForSDRAM_reg[7][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 16 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {facade/write/PixelsForSDRAM_reg[6][0]} {facade/write/PixelsForSDRAM_reg[6][1]} {facade/write/PixelsForSDRAM_reg[6][2]} {facade/write/PixelsForSDRAM_reg[6][3]} {facade/write/PixelsForSDRAM_reg[6][4]} {facade/write/PixelsForSDRAM_reg[6][5]} {facade/write/PixelsForSDRAM_reg[6][6]} {facade/write/PixelsForSDRAM_reg[6][7]} {facade/write/PixelsForSDRAM_reg[6][8]} {facade/write/PixelsForSDRAM_reg[6][9]} {facade/write/PixelsForSDRAM_reg[6][10]} {facade/write/PixelsForSDRAM_reg[6][11]} {facade/write/PixelsForSDRAM_reg[6][12]} {facade/write/PixelsForSDRAM_reg[6][13]} {facade/write/PixelsForSDRAM_reg[6][14]} {facade/write/PixelsForSDRAM_reg[6][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {facade/write/FSM_onehot_CurrentOperation_reg[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {facade/write/FSM_onehot_CurrentState[2]_i_1_n_0}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {facade/write/FSM_onehot_CurrentState[3]_i_1_n_0}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {facade/write/FSM_onehot_CurrentState[3]_i_2_n_0}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {facade/write/FSM_onehot_CurrentState[3]_i_4_n_0}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK_IBUF_BUFG]
