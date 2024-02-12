--------------------------------------------------------------------------------
-- Title       : 4x4 parallel multiplier
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : multiplier_4x4.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sat Jan 30 04:08:58 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A complete 4x4 multiplier
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity multiplier_4x4 is
	port (
		i_a : in std_logic_vector(3 downto 0);
		i_b : in std_logic_vector(3 downto 0);

		o_prod : out std_logic_vector(7 downto 0)
	);
end multiplier_4x4;

architecture multiplier_4x4_arc of multiplier_4x4 is

	component multiplier_4x4_lv_up is
		port (
			i_a : in std_logic;
			i_b : in std_logic_vector(3 downto 0);

			o_carry : out std_logic_vector(2 downto 0);
			o_sum   : out std_logic_vector(2 downto 0);
			o_prod  : out std_logic
		);
	end component multiplier_4x4_lv_up;

	component multiplier_4x4_lv_mid is
		port (
			i_a     : in std_logic;
			i_b     : in std_logic_vector(3 downto 0);
			i_carry : in std_logic_vector(2 downto 0);
			i_sum   : in std_logic_vector(2 downto 0);

			o_carry : out std_logic_vector(2 downto 0);
			o_sum   : out std_logic_vector(2 downto 0);
			o_prod  : out std_logic
		);
	end component multiplier_4x4_lv_mid;

	component multiplier_4x4_lv_last is
		port (
			i_carry : in std_logic_vector(2 downto 0);
			i_sum   : in std_logic_vector(2 downto 0);

			o_prod : out std_logic_vector(3 downto 0)
		);
	end component multiplier_4x4_lv_last;

	-- signals propagation
	type prop_arr is array (3 downto 0) of std_logic_vector(2 downto 0);
	signal sum_prop   : prop_arr;
	signal carry_prop : prop_arr;
begin
	
	first_Row : multiplier_4x4_lv_up
	port map (
		i_a(0),
		i_b,
		sum_prop(0),
		carry_prop(0),
		o_prod(0)
	);

	second_Row : multiplier_4x4_lv_mid
	port map (
		i_a(1),
		i_b,
		sum_prop(0),
		carry_prop(0),
		sum_prop(1),
		carry_prop(1),
		o_prod(1)
	);

	third_Row : multiplier_4x4_lv_mid
	port map (
		i_a(2),
		i_b,
		sum_prop(1),
		carry_prop(1),
		sum_prop(2),
		carry_prop(2),
		o_prod(2)
	);

	fourth_Row : multiplier_4x4_lv_mid
	port map (
		i_a(3),
		i_b,
		sum_prop(2),
		carry_prop(2),
		sum_prop(3),
		carry_prop(3),
		o_prod(3)
	);

	last_Row : multiplier_4x4_lv_last
	port map (
		sum_prop(3),
		carry_prop(3),
		o_prod(7 downto 4)
	);

end multiplier_4x4_arc;

