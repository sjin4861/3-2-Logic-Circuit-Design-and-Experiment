// Copyright (C) 2020  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"
// CREATED		"Wed Nov 16 19:46:54 2022"

module mx_4bit_2x1(
	ce,
	s0,
	s1,
	m_out
);


input wire	ce;
input wire	[3:0] s0;
input wire	[3:0] s1;
output wire	[3:0] m_out;

wire	[3:0] l_s0;
wire	[3:0] l_s1;
wire	[3:0] m_line;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_5;
wire	SYNTHESIZED_WIRE_12;
wire	SYNTHESIZED_WIRE_10;
wire	SYNTHESIZED_WIRE_11;




assign	SYNTHESIZED_WIRE_11 = l_s1[0] & ce;

assign	SYNTHESIZED_WIRE_1 = l_s1[1] & ce;

assign	m_line[1] = SYNTHESIZED_WIRE_0 | SYNTHESIZED_WIRE_1;

assign	m_line[2] = SYNTHESIZED_WIRE_2 | SYNTHESIZED_WIRE_3;

assign	m_line[3] = SYNTHESIZED_WIRE_4 | SYNTHESIZED_WIRE_5;

assign	SYNTHESIZED_WIRE_3 = l_s1[2] & ce;

assign	SYNTHESIZED_WIRE_5 = l_s1[3] & ce;

assign	SYNTHESIZED_WIRE_10 = SYNTHESIZED_WIRE_12 & l_s0[0];

assign	SYNTHESIZED_WIRE_0 = SYNTHESIZED_WIRE_12 & l_s0[1];

assign	SYNTHESIZED_WIRE_2 = SYNTHESIZED_WIRE_12 & l_s0[2];

assign	SYNTHESIZED_WIRE_4 = SYNTHESIZED_WIRE_12 & l_s0[3];

assign	SYNTHESIZED_WIRE_12 =  ~ce;

assign	m_line[0] = SYNTHESIZED_WIRE_10 | SYNTHESIZED_WIRE_11;

assign	m_out = m_line;
assign	l_s0 = s0;
assign	l_s1 = s1;

endmodule
