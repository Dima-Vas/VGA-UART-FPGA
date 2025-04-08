create_clock -period 20.000 -name CLK [get_ports CLK]
create_clock -period 80.000 -name x_clk [get_ports x_clk]
create_clock -period 163.250 -name p_clk [get_ports p_clk]

set_property PACKAGE_PIN R2 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]

set_property PACKAGE_PIN H18 [get_ports RST]
set_property IOSTANDARD LVCMOS33 [get_ports RST]


# ------------- OV7670 -------------
set_property PACKAGE_PIN P4 [get_ports p_clk]
set_property IOSTANDARD LVCMOS33 [get_ports p_clk]

set_property PACKAGE_PIN F18 [get_ports o_data]
set_property IOSTANDARD LVCMOS33 [get_ports o_data]

set_property PACKAGE_PIN D18 [get_ports h_sync]
set_property IOSTANDARD LVCMOS33 [get_ports h_sync]

set_property PACKAGE_PIN C17 [get_ports v_sync]
set_property IOSTANDARD LVCMOS33 [get_ports v_sync]

set_property PACKAGE_PIN R3 [get_ports x_clk]
set_property IOSTANDARD LVCMOS33 [get_ports x_clk]

set_property PACKAGE_PIN F15 [get_ports o_sio_c]
set_property IOSTANDARD LVCMOS33 [get_ports o_sio_c]

set_property PACKAGE_PIN E16 [get_ports o_sio_d]
set_property IOSTANDARD LVCMOS33 [get_ports o_sio_d]

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

set_output_delay -clock p_clk 6.000 [get_ports {o_sio_c o_sio_d}]
set_output_delay -clock p_clk -min 2.000 [get_ports {o_sio_c o_sio_d}]

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





create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list CLK_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {vga/SCCB_i_addr[0]} {vga/SCCB_i_addr[1]} {vga/SCCB_i_addr[2]} {vga/SCCB_i_addr[3]} {vga/SCCB_i_addr[4]} {vga/SCCB_i_addr[5]} {vga/SCCB_i_addr[6]} {vga/SCCB_i_addr[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list o_sio_c_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list o_sio_d_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list vga/SCCB_i_ready_reg_n_0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list vga/Switch_SetupSCCB]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK_IBUF_BUFG]
