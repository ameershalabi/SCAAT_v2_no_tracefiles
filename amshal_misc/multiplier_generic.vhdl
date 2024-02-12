--------------------------------------------------------------------------------
-- Title       : A generic parallel multiplier
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : multiplier_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sat Jan 30 22:25:19 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic parallel multiplier
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity multiplier_generic is
	generic (
		-- must be at least 3
		mult_dim : positive := 4
	);

	port (
		i_a : in std_logic_vector(mult_dim-1 downto 0);
		i_b : in std_logic_vector(mult_dim-1 downto 0);

		o_prod : out std_logic_vector((mult_dim*2)-1 downto 0)
	);
end multiplier_generic;

architecture multiplier_generic_arc of multiplier_generic is
	constant product_len : integer := mult_dim*2;
	signal prod_o        : std_logic_vector(product_len-1 downto 0);

	signal first_row : std_logic_vector(mult_dim-2 downto 0);

	signal first_col : std_logic_vector(mult_dim-2 downto 0); 

begin

	prod_o(0)  <= i_a(0) and i_b(0);

	-- a0 anded with b(3 downto 1) individually
	FOR_GEN_first_row : for bit_a in 0 to mult_dim-2 generate
		first_row(bit_a)  <= i_a(0) and i_b(bit_a+1);
	end generate FOR_GEN_first_row;

	-- b3 anded with a(3 downto 1) individually
	FOR_GEN_first_col : for bit_b in 0 to mult_dim-2 generate
		first_col(bit_b)  <= i_b(3) and i_a(bit_b+1);
	end generate FOR_GEN_first_col;


	gen_la : for lo in 0 to mult_dim-2 generate
		prod_o(lo)  <= first_row(lo);
		prod_o(lo+4)  <= first_col(lo);
	end generate gen_la;

	o_prod <= prod_o;
end multiplier_generic_arc;

