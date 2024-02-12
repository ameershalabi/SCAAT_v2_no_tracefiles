--------------------------------------------------------------------------------
-- Title       : Serial In Parallel Out (SIPO) shift register
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : SIPO_rl_shift_reg_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Nov  2 11:56:49 2020
-- Last update : Mon Nov  2 13:23:14 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A SIPO shift register with asynch load and right/left shift and
-- enable control
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
entity SIPO_rl_shift_reg_generic is
	generic (
		SIPO_len : natural := 8
	);
	port(
		clk     : in std_logic;
		en     : in std_logic;
		sft_r_l : in std_logic; -- 0 = right / 1 = left
		                        --  0 1 2 3 ... MSB
		                        --  -- right ----> 
		                        --  <---- left --
		serial_in    : in  std_logic;
		load_en      : in  std_logic;
		load_d       : in  std_logic_vector(SIPO_len-1 downto 0);
		
		Parallel_out : out std_logic_vector(SIPO_len-1 downto 0)
	);
end SIPO_rl_shift_reg_generic;
architecture SIPO_rl_shift_reg_generic_arch of SIPO_rl_shift_reg_generic is
	signal SIPO_temp     : std_logic_vector(SIPO_len-1 downto 0);
	signal serial_in_bit : std_logic;

begin
	serial_in_bit <= serial_in;

	process (clk)
	begin
		if (load_en = '1') then
			SIPO_temp <= load_d;
		elsif (rising_edge(clk) and en='1') then
			if (sft_r_l = '0') then --shift right
				SIPO_temp(SIPO_len-1 downto 1) <= SIPO_temp(SIPO_len-2 downto 0);
				SIPO_temp(0)                   <= serial_in_bit;
			else --shift left
				SIPO_temp(SIPO_len-2 downto 0) <= SIPO_temp(SIPO_len-1 downto 1);
				SIPO_temp(SIPO_len-1)          <= serial_in_bit;
			end if;
		end if;
	end process;
	Parallel_out <= SIPO_temp;

end SIPO_rl_shift_reg_generic_arch;