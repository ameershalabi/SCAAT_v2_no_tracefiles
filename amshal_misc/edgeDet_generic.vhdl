--------------------------------------------------------------------------------
-- Title       : A generic edge detector circuit
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : edgeDet_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : User Company Name
-- Created     : Sat Mar  6 12:28:16 2021
-- Last update : Sat Mar  6 13:22:11 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic edge detector circuit
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

entity edgeDet_generic is
	generic (
		det_width : natural := 7
	);
	port (
		clk            : in  std_logic;
		rst            : in  std_logic;
		in_signal      : in  std_logic_vector(det_width-1 downto 0);
		sig_event      : out std_logic_vector(det_width-1 downto 0);
		rising_edge_v  : out std_logic_vector(det_width-1 downto 0);
		falling_edge_v : out std_logic_vector(det_width-1 downto 0)

	);
end edgeDet_generic;

architecture edgeDet_generic_arc of edgeDet_generic is

	signal RE_sig : std_logic_vector(det_width-1 downto 0);
	signal FE_sig : std_logic_vector(det_width-1 downto 0);

	signal FF_Q : std_logic_vector(det_width-1 downto 0);
	signal det  : std_logic_vector(det_width-1 downto 0);
begin

	flipFlopProcess : process (clk, rst,in_signal)
	begin
		if (rst = '1') then
			FF_Q <= (others => '0');
		elsif clk'event and clk='1' then
			FF_Q <= in_signal;
		end if;
	end process flipFlopProcess;

	FOR_GEN_rising_edge_signal : for signa in 0 to det_width-1 generate
		sig_event(signa)      <= in_signal(signa) xor FF_Q(signa);
		rising_edge_v(signa)  <= '1' when in_signal(signa) = '1' and FF_Q(signa) = '0' else '0';
		falling_edge_v(signa) <= '1' when in_signal(signa) = '0' and FF_Q(signa) = '1' else '0';
	end generate FOR_GEN_rising_edge_signal;

end edgeDet_generic_arc;
