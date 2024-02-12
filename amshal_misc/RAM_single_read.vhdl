--------------------------------------------------------------------------------
-- Title       : RAM block (single read/write ports)
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : RAM_single_read.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Nov  3 10:49:04 2020
-- Last update : Wed Nov  4 14:36:52 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A single-read-port RAM block generator
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity RAM_single_R is
	generic (
		ram_width : natural := 4;
		ram_depth : natural := 8
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		-- write port
		w_en   : in std_logic;
		w_addr : in std_logic_vector(log2ceil(ram_depth)-1 downto 0);
		w_data : in std_logic_vector(ram_width-1 downto 0);
		-- read ports
		r_addr : in  std_logic_vector(log2ceil(ram_depth)-1 downto 0);
		r_data : out std_logic_vector(ram_width-1 downto 0)
	);
end RAM_single_R;
architecture RAM_single_R_arch of RAM_single_R is
	constant addr_len : natural := log2ceil(ram_depth);

	constant rst_value : std_logic_vector(ram_width-1 downto 0) := (others => '0');

	type ram_type is array (ram_depth-1 downto 0) of std_logic_vector (ram_width-1 downto 0);

	signal RAM          : ram_type;
	signal mux_array    : gen_mux_array(ram_depth-1 downto 0,ram_width-1 downto 0);
	signal decoder_in   : unsigned(addr_len-1 downto 0);
	signal decoder_out  : std_logic_vector((2**(addr_len))-1 downto 0);
	signal mux_2_output : std_logic_vector(ram_width-1 downto 0);
	signal enable_v     : unsigned(ram_depth-1 downto 0);

begin

	decoder_in <= unsigned(w_addr);

	--addr decoder for RAM write 
	cam_addr_decoder : DEC_generic
		generic map (addr_len)
		port map (decoder_in,decoder_out);

	-- register array
	FOR_GEN_regs : for reg_id in ram_depth-1 downto 0 generate
		enable_v(reg_id) <= decoder_out(reg_id) and w_en;
		RAM_reg : REG_generic
			generic map (ram_width,'0')
			port map (clk,rst,rst_value,enable_v(reg_id),w_data,RAM(reg_id));
	end generate FOR_GEN_regs;

	-- convert register putput to mux array
	FOR_GEN_ram_2_mux : for i in ram_depth-1 downto 0 generate
		FOR_GEN_ram_2_mux_2 : for j in ram_width-1 downto 0 generate
			mux_array(i,j) <= RAM(i)(j);
		end generate FOR_GEN_ram_2_mux_2;
	end generate FOR_GEN_ram_2_mux;

	-- Output MUX
	MUX_4_test : MUX_generic
		generic map (
			ram_width,
			ram_depth
		)
		port map (
			mux_array,
			conv_integer(r_addr),
			mux_2_output
		);

	-- mux out to RAM read output
	r_data <= mux_2_output;
end RAM_single_R_arch;

