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
# Clock Signal (1kHz 입력)
################################################################
set_property PACKAGE_PIN B6 [get_ports {clk_1khz}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_1khz}]


################################################################
# Reset Signal
################################################################
set_property PACKAGE_PIN Y1 [get_ports {rst}]
set_property IOSTANDARD LVCMOS33 [get_ports {rst}]


################################################################
# Game Status Signals
################################################################
set_property PACKAGE_PIN N4 [get_ports {game_clear}]
set_property IOSTANDARD LVCMOS33 [get_ports {game_clear}]

set_property PACKAGE_PIN K4 [get_ports {collision_detected}]
set_property IOSTANDARD LVCMOS33 [get_ports {collision_detected}]


################################################################
# Key Input (key_star)
################################################################
set_property PACKAGE_PIN L7 [get_ports {key_star}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_star}]


################################################################
# LEDs
################################################################
set_property PACKAGE_PIN N5 [get_ports {led_green}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_green}]

set_property PACKAGE_PIN L4 [get_ports {led_red}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_red}]

################################################################
# Full Color LED Pins
################################################################

# F_LED1
set_property PACKAGE_PIN T2  [get_ports {F_LED1_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED1_RED}]

set_property PACKAGE_PIN U5  [get_ports {F_LED1_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED1_GREEN}]

set_property PACKAGE_PIN U3  [get_ports {F_LED1_BLUE}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED1_BLUE}]

# F_LED2
set_property PACKAGE_PIN U1  [get_ports {F_LED2_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED2_RED}]

set_property PACKAGE_PIN V1  [get_ports {F_LED2_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED2_GREEN}]

set_property PACKAGE_PIN W2  [get_ports {F_LED2_BLUE}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED2_BLUE}]

# F_LED3
set_property PACKAGE_PIN P2  [get_ports {F_LED3_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED3_RED}]

set_property PACKAGE_PIN R7  [get_ports {F_LED3_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED3_GREEN}]

set_property PACKAGE_PIN R5  [get_ports {F_LED3_BLUE}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED3_BLUE}]

# F_LED4
set_property PACKAGE_PIN R3  [get_ports {F_LED4_RED}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED4_RED}]

set_property PACKAGE_PIN T6  [get_ports {F_LED4_GREEN}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED4_GREEN}]

set_property PACKAGE_PIN T3  [get_ports {F_LED4_BLUE}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_LED4_BLUE}]
