library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
entity ram6116 is
	port(address : in unsigned(7 downto 0);
		data             : inout std_logic_vector(7 downto 0);
		WE_b, CS_b, OE_b : in    std_ulogic);
end entity ram6116;

architecture simple_ram of ram6116 is
	type ram_type is array (0 to 2**8) of
		std_logic_vector(7 downto 0);
	signal ram1 : ram_type;
begin
	process (address, CS_b, WE_b, OE_b) is
	
	-- CS_b : Chip Select 
	-- WE_b : Write Enable
	-- OE_b : Output Enable 

	begin
		data <= (others => 'Z'); -- chip is not selected
		if (CS_b = '0') then
			if WE_b = '0' then -- write
				ram1(conv_integer(address)) <= data;
			end if;
			if WE_b = '1' and OE_b = '0' then -- read
				data <= ram1(conv_integer(address));
			else
				data <= (others => 'Z');
			end if;
		end if;
	end process;
end simple_ram;