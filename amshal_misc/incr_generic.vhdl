--------------------------------------------------------------------------------
-- Title       : Incrementer
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : incr_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Fri Oct 30 14:51:00 2020
-- Last update : Fri Oct 30 16:18:00 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A generic incrementer with overflow signal
--------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

entity incr_generic is
	generic (
		incr_LENGTH : natural := 5
	);
	port (
		data_in  : in  std_logic_vector(incr_LENGTH-1 downto 0);
		overFlow : out std_logic;
		data_out : out std_logic_vector (incr_LENGTH-1 downto 0)
	);
end incr_generic;

architecture incr_generic_arch of incr_generic is
	signal in_signal : std_logic_vector(incr_LENGTH-1 downto 0);
	signal XOR_gates : std_logic_vector(incr_LENGTH-2 downto 0);
	signal AND_gates : std_logic_vector(incr_LENGTH-2 downto 0);
begin
	in_signal <= data_in;

	FOR_GEN_incr : for i in incr_LENGTH-1 downto 0 generate
		IF_GEN_incr_0 : if (i = 0) generate
			AND_gates(i) <= in_signal(i+1) and in_signal(i);
			XOR_gates(i) <= in_signal(i+1) xor in_signal(i);
		end generate IF_GEN_incr_0;
		IF_GEN_incr_1 : if (i /= 0 and i /= incr_LENGTH-1) generate
			AND_gates(i) <= AND_gates(i-1) and in_signal(i+1);
			XOR_gates(i) <= AND_gates(i-1) xor in_signal(i+1);
		end generate IF_GEN_incr_1;
	end generate FOR_GEN_incr;
	overFlow <= AND_gates(incr_LENGTH-2);
	data_out(0) <= not in_signal(0);
	data_out(incr_LENGTH-1 downto 1) <= XOR_gates(incr_LENGTH-2 downto 0);

end incr_generic_arch;