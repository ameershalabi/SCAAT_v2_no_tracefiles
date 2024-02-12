--------------------------------------------------------------------------------
-- Title       : RAM block
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : RAM_dual_read.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Nov  2 13:40:44 2020
-- Last update : Mon Nov  2 14:01:55 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2020 User Company Name
-------------------------------------------------------------------------------
-- Description: A dual-read-port RAM block generator
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity RAM_dual_R is
	generic (
		ram_width : natural := 4;
		ram_depth : natural := 8
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		-- write port
		w_en   : in std_logic;
		w_addr : in std_logic_vector(ram_depth-1 downto 0);
		w_data : in std_logic_vector(ram_width-1 downto 0);
		-- read ports
		r_addr_1 : in  std_logic_vector(ram_depth-1 downto 0);
		r_addr_2 : in  std_logic_vector(ram_depth-1 downto 0);
		r_data_1 : out std_logic_vector(ram_width-1 downto 0);
		r_data_2 : out std_logic_vector(ram_width-1 downto 0)
	);
end RAM_dual_R;
architecture RAM_dual_R_arch of RAM_dual_R is
	constant rst_value : std_logic_vector(ram_width-1 downto 0) := (others => '0');
	type ram_type is array (ram_depth-1 downto 0) of std_logic_vector (ram_width-1 downto 0);
	signal RAM : ram_type;
begin
	process (clk)
	begin
		if (rst = '1') then
			RAM <= (others => (rst_value));
		elsif (clk'event and clk = '1') then
			if (w_en = '1') then
				RAM(to_integer(unsigned(w_addr))) <= w_data;
			end if;
		end if;
	end process;
	r_data_1 <= RAM(conv_integer(r_addr_1));
	r_data_2 <= RAM(conv_integer(r_addr_2));
end RAM_dual_R_arch; 