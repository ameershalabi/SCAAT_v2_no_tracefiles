--------------------------------------------------------------------------------
-- Title       : A generic LFSR with asynch load
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : LFSR_generic.vhdl.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov 11 08:47:34 2020
-- Last update : Wed Nov 11 09:36:34 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: A generic LFSR register with asynch load
-- Resgister is initiated using a vector imported from the amshal_misc package 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.amshal_misc_pkg.all;

entity LFSR_generic is
	generic(LFSR_len : natural := 12);
	port (
		clk       : in  std_logic;
		rst       : in  std_logic;
		load      : in  std_logic;
		load_data : in  std_logic_vector(LFSR_len-1 downto 0);
		gen_e     : in  std_logic;
		LFSR_out  : out std_logic_vector(LFSR_len-1 downto 0)
	);

end entity LFSR_generic;

architecture LFSR_generic_arch of LFSR_generic is

	signal XOR_placment   : std_logic_vector(LFSR_len-1 downto 0);
	signal LFSR_load_data : std_logic_vector(LFSR_len-1 downto 0);
	signal LFSR_Reg       : std_logic_vector(LFSR_len-1 downto 0);
	signal LFSR_feed      : std_logic;


begin
	XOR_placment   <= XOR_placment_ROM(LFSR_len)(LFSR_len-1 downto 0);
	LFSR_load_data <= load_data;
	LFSR : process (clk,rst)
	begin
		if (rst='1') then
			LFSR_Reg <= XOR_placment;
		elsif load = '1' then
			LFSR_Reg <= LFSR_load_data;
		elsif (clk'event and (clk = '1')) then
			LFSR_feed <= '0';
			if gen_e = '1' then
				LFSR_feed <= LFSR_Reg(LFSR_len-1);
				for gate in LFSR_len-1 downto 1 loop
					if (XOR_placment(gate-1)='1') then
						LFSR_Reg(gate) <= LFSR_Reg(gate-1) xor LFSR_feed;
					else
						LFSR_Reg(gate) <= LFSR_Reg(gate-1);
					end if;
				end loop;
				LFSR_Reg(0) <= LFSR_feed;
			end if;
		end if;
	end process;
	LFSR_out <= LFSR_Reg;
end LFSR_generic_arch;
