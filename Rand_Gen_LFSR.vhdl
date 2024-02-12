	------http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/1999f/Drivers_Ed/lfsr_generic.vhd

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.SCAAT_pkg.all;

entity LFSR_RAND is

	generic(addr_len: natural := 12);		-- length of pseudo-random sequence
	port 	(	
		clk: in std_logic;
		rst: in std_logic;
		gen_e: in std_logic;		
		rand_out: out std_logic_vector(addr_len-1 downto 0) -- parallel data out
			);

end entity LFSR_RAND;

architecture LFSR_RAND_RTL of LFSR_RAND is
	

	--signal INITSEED: std_logic_vector(addr_len-1 downto 0);

	--trey this as constant Taps 
	signal Taps: std_logic_vector(addr_len-1 downto 0);

	signal LFSR_Reg: std_logic_vector(addr_len-1 downto 0);
begin
	Taps <= TapsArray(addr_len)(addr_len-1 downto 0);
	LFSR: process (clk,rst)
	variable Feedback: std_logic;
	
	begin
		--	Create the initial seed for the LFSR for rst
		--INITSEED <= LFSRSEED(addr_len-1 downto 0);
		--	find primitive polynomial for length of cpu_addr
		--	get tap points from lookup table
		--Taps <= TapsArray(addr_len)(addr_len-1 downto 0);
		--	if reset, then initialize with the initial seed
		if rst='1' then
			LFSR_Reg <= LFSRSEED(addr_len-1 downto 0);
		--	if a clk event (rising edge of the clk)
		elsif clk'event and (clk = '1') then
			--	if it is enabled
			if gen_e = '1' then
				--	feedback is the MSB of the LFSR register
				Feedback := LFSR_Reg(addr_len-1);
				--	then XOR for every '1' of the taps
				for N in addr_len-1 downto 1 loop
					if (Taps(N-1)='1') then
						LFSR_Reg(N) <= LFSR_Reg(N-1) xor Feedback;
					else
						LFSR_Reg(N) <= LFSR_Reg(N-1);
					end if;
				end loop;
				--	the LSB of the LFSR register is the feedback
				LFSR_Reg(0) <= Feedback;
			end if;
		--	assign the value of the LFSR register to the output
		--rand_out <= LFSR_Reg;
		end if;
	end process;
	rand_out <= LFSR_Reg;
end LFSR_RAND_RTL;
