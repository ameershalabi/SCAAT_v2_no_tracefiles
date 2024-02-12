-- Author:         Ameer Shalabi
----
---- Best Cache Configuration for Benchmarks 
--  CACHE_LINES ---> 256
--  ASSOCIATIVITY ---> 1
--  MEM_ADDR_BITS ---> 27
--  CPU_ADDR_BITS ---> 32
--  MEM_DATA_BITS ---> 1024
--  CPU_DATA_BITS ---> 32
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.SCAAT_pkg.all;


entity SCAAT_unit is
	generic (
		CACHE_LINES        : positive	:= 256;
		ASSOCIATIVITY	   : positive	:= 1;
		CPU_DATA_BITS      : positive	:= 32;
		MEM_ADDR_BITS      : positive	:= 27; -- 2^10 Memory locations
		MEM_DATA_BITS      : positive	:= 1024 
	);
	port (
		clk   : in  std_logic;
		cpu_addr  : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
		attk : in std_logic;
		rst : in std_logic;
		SCAAT_addr_out: out unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0)
		);
end entity;

architecture arch of SCAAT_unit is
	constant R : positive := MEM_DATA_BITS/CPU_DATA_BITS; --words per block
	constant CACHE_SETS: positive := CACHE_LINES / ASSOCIATIVITY;

	--- CACHE ADDRESSING >> TAG | INDEX | OFFSET
	constant addr_length : natural := log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS;
	constant OFFSET_BITS: positive := log2ceil(R); --offset bits per address
	constant INDEX_BITS : positive := log2ceil(CACHE_SETS);
	constant TAG_BITS: positive := addr_length - (OFFSET_BITS + INDEX_BITS);
	
	---
	--- SCAAT_mem2
	subtype addr_star is unsigned (addr_length downto 0);
	-- addr signals
	signal addr_offset : unsigned (OFFSET_BITS-1 downto 0);
	signal addr_index : unsigned (INDEX_BITS-1 downto 0);
	signal addr_tag : unsigned (TAG_BITS-1 downto 0);
	-- SCAAT signals
	signal LFSR_out_sig : std_logic_vector (INDEX_BITS-1 downto 0);
	signal SCAAT_update  : unsigned (INDEX_BITS downto 0);
	signal SCAAT_temp  : unsigned (INDEX_BITS downto 0);
	signal found_in_SCAAT : boolean; -- Found signal for address lookup in SCAAT
	signal new_addr_star : boolean;

	--####LFSR signals
	signal com_en_sig : std_logic;

	--####access mem signals
	signal mem_out  : unsigned (INDEX_BITS downto 0);
begin  -- architecture SCAAT
	addr_offset <= cpu_addr(OFFSET_BITS-1 downto 0);
	addr_index <= cpu_addr(OFFSET_BITS+INDEX_BITS-1 downto OFFSET_BITS);
	addr_tag <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS);

-- ___________________________
-- >> 	Create the SCAAT memeory
--	mem_SCAAT: entity work.SCAAT_mem
--	generic map(
--		addr_len => addr_length
--		) -- length of pseudo-random sequence
--		port map (
--		clk			=> clk,
--		enable_w	=> com_en_sig,
--		rst			=> rst,
--		cpu_addr	=> cpu_addr,
--		datain		=> SCAAT_update,
--		dataout		=> mem_out
--		);

	mem_SCAAT: entity work.SCAAT_mem2
	generic map(
		memDim => INDEX_BITS,
		tag_bits => TAG_BITS,
		addr_len => addr_length
		) 
		port map (
		clk			=> clk,
		enable_w	=> com_en_sig,
		rst			=> rst,
		cpu_addr	=> cpu_addr,
		datain		=> SCAAT_update,
		dataout		=> mem_out
		);

-- ___________________________
-- >> 	Create the LFSR register
	LFSR_SCAAT: entity work.LFSR_RAND
	generic map(
		addr_len => INDEX_BITS
		)
	port map(	
		clk			=> clk,	-- active low reset
		gen_e			=> com_en_sig, -- active high load
		rst				=> rst,
		rand_out 	=> LFSR_out_sig -- parallel data out
			);
	
	tbl_access: process(mem_out)
		begin
		SCAAT_temp <= mem_out;
	end process tbl_access;

-- ___________________________
-- >> 	Generate requesred signals for the SCAAT control
	sig_generator: process(SCAAT_temp, attk)
		begin
			found_in_SCAAT <= false;
			new_addr_star <= false;
			com_en_sig <= '0';
			--	if the MSB of the memeory location is 1 then 
			if SCAAT_temp(INDEX_BITS) = '1' then 
				--	address is valid and already in the memeory
				found_in_SCAAT <= true;
			--	if was not found and is an attak
			elsif attk = '1' then 
				--	a new address star needs to be generated
				new_addr_star <= true;
				--	an LFSR enable signal is generated
				com_en_sig <= '1';
			end if;
	end process sig_generator;

-- ___________________________
-- >>	Use control signals to select output of the SCAAT unit and the 
--		input to the memory if needed
	rand_assign: process(mem_out,cpu_addr,found_in_SCAAT,new_addr_star)
		begin
			--	output is always the cpu address
			SCAAT_addr_out <= cpu_addr;
			--	the memeory update signals is always Xs
			SCAAT_update <= (others=>'0');
			--	if found in memory :

			if found_in_SCAAT then 
				--	output is the address star in the memeory location
				SCAAT_addr_out <= addr_tag & mem_out(INDEX_BITS-1 downto 0) & addr_offset;
				--	and the update signal stays the same as the address
				--	star in the memory location
				--SCAAT_update <= mem_out;
			--	if a new address is generated
			elsif new_addr_star then
				--	the output is the LFSR output number
				SCAAT_addr_out <= addr_tag & unsigned(LFSR_out_sig) & addr_offset;
				--	the update signal is the LFSR output with a 
				--	'1' bit as a valid signal
				SCAAT_update <= '1' & unsigned(LFSR_out_sig);
			end if;
	end process rand_assign;
	
end architecture arch;
