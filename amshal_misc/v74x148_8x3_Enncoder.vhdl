

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity V74x148 is
	port (
		EI_L       : in  STD_LOGIC;
		I_L        : in  STD_LOGIC_VECTOR (7 downto 0);
		A_L        : out STD_LOGIC_VECTOR (2 downto 0);
		EO_L, GS_L : out STD_LOGIC
	);
end V74x148;

architecture V74x148p of V74x148 is
	signal EI     : STD_LOGIC;                     -- active-high version of input
	signal I      : STD_LOGIC_VECTOR (7 downto 0); -- active-high version of inputs
	signal EO, GS : STD_LOGIC;                     -- active-high version of outputs
	signal A      : STD_LOGIC_VECTOR (2 downto 0); -- active-high version of outputs
begin
	process (EI_L, I_L, EI, EO, GS, I, A)
		variable j : INTEGER range 7 downto 0;
	begin
		EI <= not EI_L; -- convert input
		I  <= not I_L;  -- convert inputs
		EO <= '1'; GS <= '0'; A <= "000";
		if (EI)='0' then EO <= '0';
		else
			for j in 7 downto 0 loop
				if GS = '1' then
					null;
				elsif I(j)='1' then
					GS <= '1'; EO <= '0'; A <= CONV_STD_LOGIC_VECTOR(j,3);
				end if;
			end loop;
		end if;
		EO_L <= not EO; -- convert output
		GS_L <= not GS; -- convert output
		A_L  <= not A;  -- convert outputs
	end process;
end V74x148p;