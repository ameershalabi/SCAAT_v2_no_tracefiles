--------------------------------------------------------------------------------
-- Title       : A generic counter
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : counter_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov 11 10:16:37 2020
-- Last update : Wed Nov 11 10:27:19 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Description: A generic counter with an empty signal for local rst
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity counter_generic is
	generic (
		counter_len : natural := 4
	);
	port (
		clk       : in  std_logic;
		rst       : in  std_logic;
		em        : in  std_logic;
		enable    : in  std_logic;
		count_out : out std_logic_vector (counter_len-1 downto 0)
	);
end entity counter_generic;

architecture counter_generic_arch of counter_generic is
	signal counter : std_logic_vector (counter_len-1 downto 0);
begin
	process (clk, rst) begin
		if (rst = '1' or em = '1') then
			counter <= (others => '0');
		elsif (rising_edge(clk)) then
			if (enable = '1') then
				counter <= counter + 1;
			end if;
		end if;
	end process;
	count_out <= counter;
end architecture counter_generic_arch;
