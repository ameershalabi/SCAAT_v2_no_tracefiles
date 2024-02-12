--------------------------------------------------------------------------------
-- Title       : SRAM cell emulator
-- Project     : amshal_misc
--------------------------------------------------------------------------------
-- File        : SRAM_cell.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov  4 13:08:15 2020
-- Last update : Sat Nov  7 13:59:11 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: a latch between two tri-state buffers
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity SRAM_cell is
	port (
		w_l  : in    std_logic  := '0';
		b_l  : inout std_ulogic := 'Z';
		nb_l : inout std_ulogic := 'Z'
	);
end entity SRAM_cell;

architecture SRAM_cell_arch of SRAM_cell is
	signal la_1 : boolean;
	signal la_0 : boolean;
	signal en   : boolean;
	signal b_ll : std_logic := '0';
	signal la   : std_logic := '0';
begin
	la_1 <= true when w_l ='1' and b_l = '1' else false;
	la_0 <= true when w_l ='1' and b_l = '0' else false;
	en   <= true when w_l ='1' and b_l /= 'Z' else false;
	la   <= '1'  when en and (la_1 and not la_0) else '0' when en and (not la_1 and la_0);
	b_l  <= la     when w_l ='1' else 'Z';
	nb_l <= not la when w_l ='1' else 'Z';
end architecture SRAM_cell_arch;