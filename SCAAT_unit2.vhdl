-- Author:			Ameer Shalabi
----
---- Best Cache Configuration for Benchmarks 
--	CACHE_LINES ---> 256
--	ASSOCIATIVITY ---> 1
--	MEM_ADDR_BITS ---> 27
--	CPU_ADDR_BITS ---> 32
--	MEM_DATA_BITS ---> 1024
--	CPU_DATA_BITS ---> 32
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.SCAAT_pkg.all;


entity SCAAT_unit2 is
	generic (
		CACHE_LINES   : positive := 64;
		ASSOCIATIVITY : positive := 1;
		CPU_DATA_BITS : positive := 32;
		MEM_ADDR_BITS : positive := 27; -- 2^10 Memory locations
		MEM_DATA_BITS : positive := 1024
	);
	port (
		clk                  : in  std_logic;
		cpu_addr             : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
		attk                 : in  std_logic;
		rst                  : in  std_logic;
		SCAAT_addr_out       : out unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
		SCAAT_addr_out_count : out integer;
		R_active             : out integer;
		f_in_SCAAT           : out std_logic
	);
end entity;

architecture SCAAT_ctrl of SCAAT_unit2 is
	constant R          : positive := MEM_DATA_BITS/CPU_DATA_BITS; --words per block
	constant CACHE_SETS : positive := CACHE_LINES;

	--- CACHE ADDRESSING >> TAG | INDEX | OFFSET
	constant addr_length : natural  := log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS;
	constant OFFSET_BITS : positive := log2ceil(R); --offset bits per address
	constant INDEX_BITS  : natural  := log2ceil(CACHE_SETS);
	constant TAG_BITS    : positive := addr_length - (OFFSET_BITS + INDEX_BITS);

	---
	--- SCAAT_mem2
	subtype addr_star_type is unsigned (addr_length-1 downto 0);
	signal addr_star : addr_star_type;
	-- addr signals
	signal addr_offset : unsigned (OFFSET_BITS-1 downto 0);
	--signal addr_index : unsigned (INDEX_BITS-1 downto 0);
	signal addr_tag : unsigned (TAG_BITS-1 downto 0);
	-- SCAAT signals
	signal LFSR_out_sig : std_logic_vector (INDEX_BITS-1 downto 0);

	signal found_in_SCAAT : boolean; -- Found signal for address lookup in SCAAT
	signal new_addr_star  : boolean;

	--####LFSR signals
	signal com_en_sig : std_logic;
	--signal com_en_sig : bit;

	--####access mem signals
	signal mem_out : unsigned (INDEX_BITS downto 0);

	signal new_addr_star_counter : std_logic_vector(31 downto 0) := (others => '0');
	signal R_active_c            : std_logic_vector(31 downto 0) := (others => '0');


begin -- architecture SCAAT
	addr_offset <= cpu_addr(OFFSET_BITS-1 downto 0);
	--addr_index <= cpu_addr(OFFSET_BITS+INDEX_BITS-1 downto OFFSET_BITS);
	addr_tag <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS);

	-- ___________________________

	mem_SCAAT : entity work.SCAAT_mem3
		--mem_SCAAT_R_mem: entity work.SCAAT_R_mem
		generic map(
			memDim   => INDEX_BITS,
			tag_bits => TAG_BITS
		--addr_len => addr_length
		) -- length of pseudo-random sequence
		port map (
			clk      => clk,
			enable_w => com_en_sig,
			rst      => rst,
			--attk		=> attk,
			addr => unsigned(LFSR_out_sig),
			--addr_tag	=> addr_tag,
			addr_tag => cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS),
			dataout  => mem_out
		);

	-- ___________________________
	-- >> 	Create the LFSR register
	LFSR_SCAAT : entity work.LFSR_RAND
		generic map(
			addr_len => INDEX_BITS
		) -- length of pseudo-random sequence
		port map(
			clk      => clk,        -- active low reset
			gen_e    => com_en_sig, -- active high load
			rst      => rst,
			rand_out => LFSR_out_sig -- parallel data out
		);
	-- ___________________________
	-- >> 	Generate requesred signals for the SCAAT control
	sig_generator : process(mem_out, attk)
	begin
		found_in_SCAAT <= false;
		new_addr_star  <= false;
		com_en_sig     <= '0';
		--	if the MSB of the memeory location is 1 then 
		if mem_out(INDEX_BITS) = '1' then
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
	--addr_star <= cpu_addr;
	rand_assign : process(cpu_addr,LFSR_out_sig,addr_offset,addr_tag,found_in_SCAAT,new_addr_star,mem_out)
	begin
		--	output is always the cpu address
		addr_star <= cpu_addr;
		--	if found in memory :
		if found_in_SCAAT then
			--	output is the address star in the memeory location
			addr_star <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & mem_out(INDEX_BITS-1 downto 0) & cpu_addr(OFFSET_BITS-1 downto 0);
		elsif new_addr_star then
			--	the output is the LFSR output number
			addr_star <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & unsigned(LFSR_out_sig) & cpu_addr(OFFSET_BITS-1 downto 0);
		end if;
	end process rand_assign;

	SCAAT_addr_out <= addr_star;

	SIM_DATA : process(rst,new_addr_star)
	begin
		if (rst='1') then
			new_addr_star_counter <= (others => '0');
		elsif (new_addr_star) then
			new_addr_star_counter <= new_addr_star_counter + 1;
		end if;
	end process SIM_DATA;

	SCAAT_addr_out_count <= to_integer(unsigned(new_addr_star_counter));

	R_active <= to_integer(unsigned(R_active_c));

	f_in_SCAAT <= '1' when found_in_SCAAT else '0';
end architecture SCAAT_ctrl;
