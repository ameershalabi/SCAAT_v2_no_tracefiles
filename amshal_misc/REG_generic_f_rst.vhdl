--------------------------------------------------------------------------------
-- Title       : A generic register
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : REG_generic_f_rst.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 14 00:00:00 2020
-- Last update : Fri Oct 30 09:29:12 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic register with force rst port and a clk edge trigger
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity REG_generic_f_rst is
	generic (
		reg_width        : natural   := 21;
		clk_edge_trigger : std_logic := '0'
	-- 0 is falling edge, 1 is rising edge1
	);
	port (
		clk       : in  std_logic;
		rst       : in  std_logic;
		f_rst     : in  std_logic;
		rst_value : in  std_logic_vector(reg_width-1 downto 0);
		en_load   : in  std_logic;
		reg_in    : in  std_logic_vector(reg_width-1 downto 0);
		reg_out   : out std_logic_vector(reg_width-1 downto 0)
	);
end REG_generic_f_rst;

architecture REG_generic_f_rst_arch of REG_generic_f_rst is
	signal rst_sig : std_logic;
begin
	rst_sig <= rst or f_rst;
	reg_proc : process (clk, rst)
	begin
		if (rst = '1') then
			reg_out <= rst_value;
		elsif (clk_edge_trigger = '0') then
			if falling_edge(clk) then
				if (en_load = '1') then
					reg_out <= reg_in;
				end if;
			end if;
		elsif (clk_edge_trigger = '1') then
			if rising_edge(clk) then
				if (en_load = '1') then
					reg_out <= reg_in;
				end if;
			end if;
		end if;
		if (f_rst) = '1' then
			reg_out <= rst_value;
		end if;
	end process reg_proc;
end REG_generic_f_rst_arch;