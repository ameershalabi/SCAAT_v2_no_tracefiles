--------------------------------------------------------------------------------
-- Title       : A simple full adder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : fa.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Wed Jan 27 21:32:33 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A simple full adder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fa is
	port (
		in_a : in std_logic;
		in_b : in std_logic;
		c_in : in std_logic;

		sum   : out std_logic;
		c_out : out std_logic
	);
end entity fa;

architecture arch of fa is
begin
	sum <= in_a xor in_b xor c_in;
	c_out <= (in_a and in_b) or (in_a and c_in) or (in_b and c_in);
end architecture arch;

