--------------------------------------------------------------------------------
-- Title       : A row of latches
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : SRAM_latch_row.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Nov  3 14:25:45 2020
-- Last update : Tue Nov  3 18:34:40 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: a row of latches with a write pin
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity latch_row is
	generic (
		row_width : natural := 4
	);
	port (
		en : in    std_logic;
		w  : in    std_logic;
		row_d_in  : in std_logic_vector(row_width-1 downto 0);
		row_d_out  : out std_logic_vector(row_width-1 downto 0)

	);
end entity latch_row;

architecture latch_row_arch of latch_row is
	signal in_la : std_logic_vector(row_width-1 downto 0);
	signal out_la : std_logic_vector(row_width-1 downto 0);
begin
	in_la <= row_d_in;
	FOR_GEN_LATCH_ROW : for i in row_width-1 downto 0 generate
		la : latch port map (en,w,in_la(i),out_la(i));
	end generate FOR_GEN_LATCH_ROW;
	row_d_out <= out_la;
end architecture latch_row_arch;
