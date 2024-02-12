--------------------------------------------------------------------------------
-- Title       : A generic Multiplexer
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : MUX_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Fri Oct 30 09:27:56 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic Multiplexer with an array as input
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.amshal_misc_pkg.all;

entity MUX_generic is
	generic (
		len_inputs : natural := 5;
		num_inputs : natural := 2
	);
	port (
		inputs_array: in gen_mux_array(0 to num_inputs-1,len_inputs-1 downto 0);
		sel: in natural range num_inputs-1 downto 0;
		mux_out : out std_logic_vector(len_inputs-1 downto 0)
	);
end MUX_generic;

architecture MUX_generic_arch of MUX_generic is
begin
	FOR_GEN_MUX_outputs : for i in len_inputs-1 downto 0 generate
		mux_out(i)  <=  inputs_array(sel,i);
	end generate FOR_GEN_MUX_outputs;
end MUX_generic_arch;