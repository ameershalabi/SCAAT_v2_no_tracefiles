--------------------------------------------------------------------------------
-- Title       : Serial In (Serial and Parallel) Out (SI_SPO) shift register
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : SI_SPO_rl_shift_reg_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Nov  2 12:56:49 2020
-- Last update : Mon Nov  2 13:15:13 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A shift register with both synch serial and parallel out ports 
-- with asynch load and right/left shift and enable control
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
entity SI_SPO_rl_shift_reg_generic is
	generic (
		SI_SPO_len : natural := 8
	);
	port(
		clk     : in std_logic;
		en      : in std_logic;
		sft_r_l : in std_logic; -- 0 = right / 1 = left
		                        --  0 1 2 3 ... MSB
		                        --  -- right ----> 
		                        --  <---- left --
		serial_in    : in  std_logic;
		load_en      : in  std_logic;
		load_d       : in  std_logic_vector(SI_SPO_len-1 downto 0);
		serial_out   : out std_logic;
		Parallel_out : out std_logic_vector(SI_SPO_len-1 downto 0)
	);
end SI_SPO_rl_shift_reg_generic;
architecture SI_SPO_rl_shift_reg_generic_arch of SI_SPO_rl_shift_reg_generic is
	signal SI_SPO_temp      : std_logic_vector(SI_SPO_len-1 downto 0);
	signal serial_in_bit  : std_logic;
	signal serial_out_bit : std_logic;
begin
	serial_in_bit  <= serial_in;
	serial_out_bit <= SI_SPO_temp(SI_SPO_len-1) when sft_r_l = '0' else SI_SPO_temp(0);
	process (clk)
	begin
		if (load_en = '1') then
			SI_SPO_temp <= load_d;
		elsif (rising_edge(clk) and en='1') then
			if (sft_r_l = '0') then --shift right
				SI_SPO_temp(SI_SPO_len-1 downto 1) <= SI_SPO_temp(SI_SPO_len-2 downto 0);
				SI_SPO_temp(0)                   <= serial_in_bit;
			else --shift left
				SI_SPO_temp(SI_SPO_len-2 downto 0) <= SI_SPO_temp(SI_SPO_len-1 downto 1);
				SI_SPO_temp(SI_SPO_len-1)          <= serial_in_bit;
			end if;
		end if;
	end process;
	Parallel_out <= SI_SPO_temp;
	serial_out   <= serial_out_bit;
end SI_SPO_rl_shift_reg_generic_arch;