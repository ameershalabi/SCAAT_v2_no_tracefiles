--------------------------------------------------------------------------------
-- Title       : Last Level of 4x4 multiplier (prod(4) to prod(7))
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : multiplier_4x4_lv_last.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sat Jan 30 04:13:33 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: The Last level of the multiplier to produce the product
-- most significant half
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity multiplier_4x4_lv_last is
	port (

		i_carry : in std_logic_vector(2 downto 0);
		i_sum   : in std_logic_vector(2 downto 0);

		o_prod : out std_logic_vector(3 downto 0)

	);
end multiplier_4x4_lv_last;

architecture multiplier_4x4_lv_last_arc of multiplier_4x4_lv_last is
	signal carry_internal : std_logic_vector(2 downto 0);
begin

	carry_internal(0) <= '0';

	-- three adders can be used
	--fa (i_sum(0), i_carry(0), carry_internal(0), o_prod(1), carry_internal(1))
	--fa (i_sum(1), i_carry(1), carry_internal(1), o_prod(1), carry_internal(2))
	--fa (i_sum(2), i_carry(2), carry_internal(2), o_prod(2), o_prod(3))

	o_prod(0) <= i_sum(0) xor i_carry(0) xor carry_internal(0);
	o_prod(1) <= i_sum(1) xor i_carry(1) xor carry_internal(1);
	o_prod(2) <= i_sum(2) xor i_carry(2) xor carry_internal(2);

	carry_internal(1) <= (i_sum(0) and i_carry(0)) or (i_sum(0) and carry_internal(0)) or (i_carry(0) and carry_internal(0));
	carry_internal(2) <= (i_sum(1) and i_carry(1)) or (i_sum(1) and carry_internal(1)) or (i_carry(1) and carry_internal(1));
	o_prod(3)         <= (i_sum(2) and i_carry(2)) or (i_sum(2) and carry_internal(2)) or (i_carry(2) and carry_internal(2));


end multiplier_4x4_lv_last_arc;

