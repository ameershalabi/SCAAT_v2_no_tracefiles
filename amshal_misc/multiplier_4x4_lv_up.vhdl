--------------------------------------------------------------------------------
-- Title       : Upper Level of 4x4 multiplier (prod(0))
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : multiplier_4x4_lv_up.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sat Jan 30 04:14:25 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: The first level of the multiplier to produce the product LSB
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity multiplier_4x4_lv_up is
	port (
		i_a : in std_logic;
		i_b : in std_logic_vector(3 downto 0);

		o_carry : out std_logic_vector(2 downto 0);
		o_sum   : out std_logic_vector(2 downto 0);
		o_prod  : out std_logic

	);
end multiplier_4x4_lv_up;

architecture multiplier_4x4_lv_up_arc of multiplier_4x4_lv_up is
begin
	-- a row of and gates
	o_prod   <= i_a and i_b(0);
	o_sum(0) <= i_a and i_b(1);
	o_sum(1) <= i_a and i_b(2);
	o_sum(2) <= i_a and i_b(3);

	o_carry <= "000";

end multiplier_4x4_lv_up_arc;
