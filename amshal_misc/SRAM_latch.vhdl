--------------------------------------------------------------------------------
-- Title       : A simple latch
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : SRAM_latch.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Nov  3 14:06:45 2020
-- Last update : Tue Nov  3 18:33:51 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: a latch with a write pin
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity latch is
	port (
		en : in  std_logic;
		w  : in  std_logic;
		d  : in  std_logic;
		q  : out std_logic
	);
end entity latch;

architecture latch_arch of latch is
begin
	q  <= d when (en='1' and w = '0');
end architecture latch_arch;