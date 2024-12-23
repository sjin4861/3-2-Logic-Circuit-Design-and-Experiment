set_property IOSTANDARD LVCMOS33 [get_ports key_star]
set_property PACKAGE_PIN B6 [get_ports clk]
set_property PACKAGE_PIN H4 [get_ports com1]
set_property PACKAGE_PIN H6 [get_ports com2]
set_property PACKAGE_PIN G1 [get_ports com3]
set_property PACKAGE_PIN G3 [get_ports com4]
set_property PACKAGE_PIN L6 [get_ports com5]
set_property PACKAGE_PIN K1 [get_ports com6]
set_property PACKAGE_PIN K3 [get_ports com7]
set_property PACKAGE_PIN K5 [get_ports com8]
set_property PACKAGE_PIN L1 [get_ports key0]
set_property PACKAGE_PIN J2 [get_ports key8]
set_property PACKAGE_PIN L7 [get_ports key_star]
set_property PACKAGE_PIN Y1 [get_ports rst]
set_property PACKAGE_PIN F1 [get_ports seg_a]
set_property PACKAGE_PIN E4 [get_ports seg_d]
set_property PACKAGE_PIN J7 [get_ports seg_g]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports com1]
set_property IOSTANDARD LVCMOS33 [get_ports com2]
set_property IOSTANDARD LVCMOS33 [get_ports com3]
set_property IOSTANDARD LVCMOS33 [get_ports com4]
set_property IOSTANDARD LVCMOS33 [get_ports com5]
set_property IOSTANDARD LVCMOS33 [get_ports com6]
set_property IOSTANDARD LVCMOS33 [get_ports com7]
set_property IOSTANDARD LVCMOS33 [get_ports com8]
set_property IOSTANDARD LVCMOS33 [get_ports key0]
set_property IOSTANDARD LVCMOS33 [get_ports key8]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports seg_a]
set_property IOSTANDARD LVCMOS33 [get_ports seg_d]
set_property IOSTANDARD LVCMOS33 [get_ports seg_g]

################################################################
# LCD Control Signals
################################################################
set_property PACKAGE_PIN D6 [get_ports {LCD_RW}]
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_RW}]

set_property PACKAGE_PIN G6 [get_ports {LCD_RS}]
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_RS}]

set_property PACKAGE_PIN A6 [get_ports {LCD_E}]
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_E}]

################################################################
# LCD Data Lines
################################################################
set_property PACKAGE_PIN A4 [get_ports {LCD_DATA[0]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[0]}]

set_property PACKAGE_PIN B2 [get_ports {LCD_DATA[1]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[1]}]

set_property PACKAGE_PIN C3 [get_ports {LCD_DATA[2]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[2]}]

set_property PACKAGE_PIN D4 [get_ports {LCD_DATA[3]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[3]}]

set_property PACKAGE_PIN A2 [get_ports {LCD_DATA[4]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[4]}]

set_property PACKAGE_PIN C5 [get_ports {LCD_DATA[5]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[5]}]

set_property PACKAGE_PIN C1 [get_ports {LCD_DATA[6]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[6]}]

set_property PACKAGE_PIN D1 [get_ports {LCD_DATA[7]}]  
set_property IOSTANDARD LVCMOS33 [get_ports {LCD_DATA[7]}]

################################################################
# Full Color LED Pins
################################################################

# F_LED1
set_property PACKAGE_PIN T2  [get_ports {F_LED1_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED1_RED}]

set_property PACKAGE_PIN U5  [get_ports {F_LED1_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED1_GREEN}]

# F_LED2
set_property PACKAGE_PIN U1  [get_ports {F_LED2_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED2_RED}]

set_property PACKAGE_PIN V1  [get_ports {F_LED2_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED2_GREEN}]

# F_LED3
set_property PACKAGE_PIN P2  [get_ports {F_LED3_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED3_RED}]

set_property PACKAGE_PIN R7  [get_ports {F_LED3_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED3_GREEN}]

# F_LED4
set_property PACKAGE_PIN R3  [get_ports {F_LED4_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED4_RED}]

set_property PACKAGE_PIN T6  [get_ports {F_LED4_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED4_GREEN}]