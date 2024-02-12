--------------------------------------------------------------------------------
--
-- Title		: SCAAT_mem4.vhdl
-- Project		: SCAAT
-- Design 		: Redundant memory
-- Author		: Ameer Shalabi
-- Date			: 05/10/2020
-- Institution	: Tallinn University of Technology
--------------------------------------------------------------------------------
--
-- Description
-- This is a memory device that checks if a tag already exists in the memory
-- and removes its duplicates once reassigned into a different location.
--------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.SCAAT_pkg.all;

entity SCAAT_R_mem is
 	generic(	
 	memDim			: natural	:= 6;
 	tag_bits		: positive	:= 6
 	--addr_len 		: positive 	:= 12
 	);

	port (
	clk				: in	std_logic; -- clk
	rst				: in	std_logic; -- reset
	enable_w		: in	std_logic; -- write enable
	addr			: in	unsigned(memDim-1 downto 0); -- address location in memeory
	addr_tag		: in	unsigned(tag_bits-1 downto 0); -- address location in memeory
	--datain		: in	unsigned(memDim downto 0); -- data in
	dataout			: out 	unsigned(memDim downto 0) -- data out
	);

end entity SCAAT_R_mem;

--------------------------------------------------------------------------------

architecture SCAAT_R_mem_RTL of SCAAT_R_mem is
--------------------------------------------------------------------------------
--  Signals
--------------------------------------------------------------------------------
	constant resetVal : unsigned (tag_bits-1 downto 0) := (others=>'1');
	--	create the memory 2D array according to the length of the address
	type SCAAT is array ((2**memDim) - 1 downto 0) of unsigned(tag_bits-1 downto 0);
	--	create the access signal to the array
	signal SCAATacss : SCAAT;
	-- pipeline states and signals
	--type pipeline_fsm is (READY, W_MEM, RST_LOC, UNKNOWN);
	--signal curStage, nextStage : pipeline_fsm;
	-- signal for write location
	signal location	: natural range 0 to 2**memDim - 1;
	-- signal to carry output
	signal data_read : unsigned (memDim downto 0);

	signal data_read_BUF : unsigned (memDim downto 0);
	--
	signal R_active : std_logic;

begin
	--	assign the memeory location
	location <= to_integer(addr);
--------------------------------------------------------------------------------
--  Write to mem
--------------------------------------------------------------------------------
	mem_proc: process(clk) is
	begin
		--	check at the falling edge of the clk,
		if falling_edge(clk) then ---switch wit the if of the rst
			--	if a reset, all the locations are initialized to 0s
			--R_active	<=	'0';
			if rst = '1' then
				SCAATacss 			<= (others=>(resetVal));
				--pre_index_reg		<= (others=>'0');
			elsif enable_w = '1' then
				SCAATacss(location) <= addr_tag;
				if (data_read_BUF(memDim) = '1') then
					SCAATacss(to_integer(data_read_BUF(memDim-1 downto 0))) <= resetVal;
					--R_active	<=	'1';
				end if;
			end if;
		end if;
	end process mem_proc;
	--	the address in XY location is always output
--------------------------------------------------------------------------------
--  Read from mem
--------------------------------------------------------------------------------
	mem_read: process(addr_tag,SCAATacss) is
	begin
		data_read <= to_unsigned(0, memDim+1);
		for i in 0 to 2**memDim - 1 loop
			if SCAATacss(i)(tag_bits-1 downto 0) = addr_tag then
				data_read <= '1'&to_unsigned(i, memDim);
			end if;
		end loop;
	end process mem_read;
	data_read_BUF <= data_read;
	dataout <= data_read;
end SCAAT_R_mem_RTL;
