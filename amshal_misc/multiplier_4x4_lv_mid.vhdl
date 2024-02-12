--------------------------------------------------------------------------------
-- Title       : One row of middle Level of 4x4 multiplier ((prod(1) to prod(3)))
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : multiplier_4x4_lv_mid.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sat Jan 30 04:13:34 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description:  One row of the second level of the multiplier to produce the product
-- least significant half (except LSB)
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity multiplier_4x4_lv_mid is
	port (
		i_a     : in std_logic;
		i_b     : in std_logic_vector(3 downto 0);
		i_carry : in std_logic_vector(2 downto 0);
		i_sum   : in std_logic_vector(2 downto 0);

		o_carry : out std_logic_vector(2 downto 0);
		o_sum   : out std_logic_vector(2 downto 0);
		o_prod  : out std_logic

	);
end multiplier_4x4_lv_mid;

architecture multiplier_4x4_lv_mid_arc of multiplier_4x4_lv_mid is
	signal carry_and_out : std_logic_vector(2 downto 0);
begin
	carry_and_out(0) <= i_a and i_b(0);
	carry_and_out(1) <= i_a and i_b(1);
	carry_and_out(2) <= i_a and i_b(2);
	o_sum(2)         <= i_a and i_b(3);

	-- three adders can be used
	--fa (i_sum(2), i_carry(2), carry_and_out(2), o_sum(1), o_carry(2))
	o_sum(1) <= i_sum(2) xor i_carry(2) xor carry_and_out(2);
	o_carry(2) <= (i_sum(2) and i_carry(2)) or (i_sum(2) and carry_and_out(2)) or (i_carry(2) and carry_and_out(2));

	--fa (i_sum(1), i_carry(1), carry_and_out(1), o_sum(0), o_carry(1))
	o_sum(0) <= i_sum(1) xor  i_carry(1) xor carry_and_out(1);
	o_carry(1) <= (i_sum(1) and  i_carry(1)) or (i_sum(1) and carry_and_out(1)) or ( i_carry(1) and carry_and_out(1));

	--fa (i_sum(0), i_carry(0), carry_and_out(0), o_prod, o_carry(0))
	o_prod <= i_sum(0) xor i_carry(0) xor carry_and_out(0);
	o_carry(0) <= (i_sum(0) and i_carry(0)) or (i_sum(0) and carry_and_out(0)) or (i_carry(0) and carry_and_out(0));

end multiplier_4x4_lv_mid_arc;

