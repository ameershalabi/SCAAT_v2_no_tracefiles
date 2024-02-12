--------------------------------------------------------------------------------
-- Title       : A simple full adder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : parallel_fa_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Wed Jan 27 21:49:48 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A simple full adder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.amshal_misc_pkg.all;

entity parallel_fa_generic is
	generic (
		adder_len : natural := 8
	);
	port (
		in_a : in std_logic_vector(adder_len-1 downto 0);
		in_b : in std_logic_vector(adder_len-1 downto 0);
		c_in : in std_logic;

		sum      : out std_logic_vector(adder_len-1 downto 0);
		OVERFLOW : out std_logic
	);
end entity parallel_fa_generic;

architecture arch of parallel_fa_generic is
	signal c_out_vector : std_logic_vector(adder_len-1 downto 0);
	signal sum_vector   : std_logic_vector(adder_len-1 downto 0);

begin
	FOR_GEN_ADDER : for i in adder_len-1 downto 0 generate
		IF_GEN_0 : if (i = 0) generate
			adder_0 : fa
				port map (
					in_a(i),
					in_b(i),
					c_in,
					sum_vector(i),
					c_out_vector(i)
				);
		end generate IF_GEN_0;
		IF_GEN_1 : if (i /= 0) generate
			adder_x : fa
				port map (
					in_a(i),
					in_b(i),
					c_out_vector(i-1),
					sum_vector(i),
					c_out_vector(i)
				);
		end generate IF_GEN_1;
	end generate FOR_GEN_ADDER;
	sum <= sum_vector;
	OVERFLOW <= c_out_vector(adder_len-1);
end architecture arch;

