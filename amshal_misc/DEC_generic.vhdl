--------------------------------------------------------------------------------
-- Title       : A generic decoder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : DEC_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Fri Oct 30 09:29:26 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic Decoder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity DEC_generic is
	generic (
		addr_width : natural := 7
	);
	port (
		addr : in unsigned(addr_width-1 downto 0);
		dec_out : out std_logic_vector((2**addr_width)-1 downto 0)
	);
end DEC_generic;

architecture DEC_generic_arc of DEC_generic is
	signal dec_input : unsigned(addr_width-1 downto 0);
	signal dec_output : unsigned((2**addr_width)-1 downto 0);
begin
	dec_input <= unsigned(addr);
	decoder_proc : process (dec_input)
	begin
		dec_output <= (others=>'0');
		dec_output(to_integer(dec_input)) <= '1';
	end process decoder_proc;

	dec_out  <=  std_logic_vector(dec_output);
end DEC_generic_arc;
