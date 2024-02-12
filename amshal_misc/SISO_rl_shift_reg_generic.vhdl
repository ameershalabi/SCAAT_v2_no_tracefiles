--------------------------------------------------------------------------------
-- Title       : Serial In Serial Out (SISO) shift register
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : SISO_rl_shift_reg_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Nov  2 11:58:39 2020
-- Last update : Mon Nov  2 16:17:41 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A SISO shift register with asynch load and right/left shift and
-- enable control
--------------------------------------------------------------------------------
-- to look at https://www.tutorialspoint.com/computer_logical_organization/digital_registers.htm
library ieee;
use ieee.std_logic_1164.all;
entity SISO_rl_shift_reg_generic is
	generic (
		SISO_len : natural := 8
	); 
	port(
		clk     : in std_logic;
		en     : in std_logic;
		sft_r_l : in std_logic; -- 0 = right / 1 = left
		                        --  0 1 2 3 ... MSB
		                        --  -- right ----> 
		                        --  <---- left --
		serial_in  : in  std_logic;
		load_en    : in  std_logic;
		load_d     : in  std_logic_vector(SISO_len-1 downto 0);
		
		serial_out : out std_logic
	);
end SISO_rl_shift_reg_generic;
architecture SISO_rl_shift_reg_generic_arch of SISO_rl_shift_reg_generic is
	signal SISO_temp      : std_logic_vector(SISO_len-1 downto 0);
	signal serial_in_bit  : std_logic;
	signal serial_out_bit : std_logic;
begin
	serial_in_bit <= serial_in;
	serial_out_bit <= SISO_temp(SISO_len-1) when sft_r_l = '0' else SISO_temp(0);
	process (clk)
	begin
		if (load_en = '1') then
			SISO_temp <= load_d;
		elsif (rising_edge(clk) and en='1') then
			if (sft_r_l = '0') then --shift right
				SISO_temp(SISO_len-1 downto 1) <= SISO_temp(SISO_len-2 downto 0);
				SISO_temp(0)                   <= serial_in_bit;
			else --shift left
				SISO_temp(SISO_len-2 downto 0) <= SISO_temp(SISO_len-1 downto 1);
				SISO_temp(SISO_len-1)          <= serial_in_bit;
			end if;
		end if;
	end process;
	serial_out <= serial_out_bit;

end SISO_rl_shift_reg_generic_arch;