--------------------------------------------------------------------------------
-- Title       : Decrementer
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : decr_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Fri Oct 30 16:17:28 2020
-- Last update : Fri Oct 30 16:19:01 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: An up to 32-bit generic decrementer with zero signal generated 
-- using an AND gate balanced tree
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions


entity decr_generic is
	generic (
		decr_LENGTH : natural := 3
	);
	port (
		data_in  : in  std_logic_vector(decr_LENGTH-1 downto 0);
		zero : out std_logic;
		data_out : out std_logic_vector (decr_LENGTH-1 downto 0)
	);
end decr_generic;

architecture decr_generic_arch of decr_generic is
	signal in_signal : std_logic_vector(decr_LENGTH-1 downto 0);
	signal out_signal : std_logic_vector(decr_LENGTH-1 downto 0);
	signal XOR_gates : std_logic_vector(decr_LENGTH-2 downto 0);
	signal AND_gates : std_logic_vector(decr_LENGTH-2 downto 0);
	signal zero_gen : std_logic_vector(63 downto 0);
begin
	in_signal <= data_in;
	
	FOR_GEN_incr : for i in decr_LENGTH-1 downto 0 generate
		IF_GEN_incr_0 : if (i = 0) generate
			AND_gates(i) <= in_signal(i+1) and in_signal(i);
			XOR_gates(i) <= not (in_signal(i+1) xor in_signal(i));
		end generate IF_GEN_incr_0;
		IF_GEN_incr_1 : if (i /= 0 and i /= decr_LENGTH-1) generate
			AND_gates(i) <= AND_gates(i-1) and in_signal(i+1);
			XOR_gates(i) <= not (AND_gates(i-1) xor in_signal(i+1));
		end generate IF_GEN_incr_1;
	end generate FOR_GEN_incr;

	FOR_GEN_OR_gates : for orGate in 63 downto 0 generate
		IF_GEN_OR_gates : if (orGate mod 2 = 0) generate
			zero_gen(orGate/2) <= zero_gen(orGate) and zero_gen(orGate+1);
		end generate IF_GEN_OR_gates;
	end generate FOR_GEN_OR_gates;

	--zero <= '1' when to_integer(unsigned(data_out)) = 1 else '0';
	
	out_signal(0) <= not in_signal(0);
	out_signal(decr_LENGTH-1 downto 1) <= XOR_gates(decr_LENGTH-2 downto 0);
	zero_gen(63 downto 32+decr_LENGTH) <= (others=>'1');
	zero_gen(32+decr_LENGTH-1 downto 32) <= out_signal;

	zero <= '1' when zero_gen(1) = '1' else '0';
	data_out <= out_signal;


end decr_generic_arch;