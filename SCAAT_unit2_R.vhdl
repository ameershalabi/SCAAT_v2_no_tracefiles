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
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions


library work;
use work.SCAAT_pkg.all;


entity SCAAT_unit2_R is
	generic (
		CACHE_LINES   : positive := 256;
		ASSOCIATIVITY : positive := 8;
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

architecture R_SCAAT of SCAAT_unit2_R is
	constant R          : positive := MEM_DATA_BITS/CPU_DATA_BITS; --words per block
	constant CACHE_SETS : positive := CACHE_LINES;                 -- / ASSOCIATIVITY;

	--- CACHE ADDRESSING >> TAG | INDEX | OFFSET
	constant addr_length : natural  := log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS;
	constant OFFSET_BITS : positive := log2ceil(R); --offset bits per address
	constant INDEX_BITS  : natural  := log2ceil(CACHE_SETS);
	constant TAG_BITS    : positive := addr_length - (OFFSET_BITS + INDEX_BITS);


	---
	--- SCAAT_mem2
	--subtype addr_star_type is unsigned (addr_length-1 downto 0);
	--signal addr_star : addr_star_type;
	-- addr signals
	signal addr_offset : unsigned (OFFSET_BITS-1 downto 0);
	--signal addr_index : unsigned (INDEX_BITS-1 downto 0);
	signal addr_tag : unsigned (TAG_BITS-1 downto 0);
	-- SCAAT signals
	signal LFSR_out_sig : std_logic_vector (INDEX_BITS-1 downto 0);

	signal found_in_SCAAT : boolean; -- Found signal for address lookup in SCAAT
	signal new_addr_star  : boolean;
	signal force_reset  : boolean;

	--####LFSR signals
	signal com_en_sig : std_logic;
	signal f_rst_sig  : std_logic;


	--signal com_en_sig : bit;
	signal found_in_SCAAT_counter : std_logic_vector(31 downto 0) := (others => '0');
	signal new_addr_star_counter  : std_logic_vector(31 downto 0) := (others => '0');
	signal R_active_c             : std_logic_vector(31 downto 0) := (others => '0');
	--####access mem signals
	signal mem_out : unsigned (INDEX_BITS downto 0);

	--### threshold signals
	signal found_in_SCAAT_det : boolean;
	signal found_in_SCAAT_rising_edge : boolean;
	signal SCAAT_thresh : natural;
	signal countSCAAT     : natural;


begin -- architecture SCAAT
	addr_offset <= cpu_addr(OFFSET_BITS-1 downto 0);
	--addr_index <= cpu_addr(OFFSET_BITS+INDEX_BITS-1 downto OFFSET_BITS);
	addr_tag <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS);

	-- ___________________________

	--mem_SCAAT: entity work.SCAAT_mem3
	--mem_SCAAT_R_mem: entity work.SCAAT_R_mem
	--mem_SCAAT_R_mem: entity work.SCAAT_CAM_mem
	mem_SCAAT_R_mem : entity work.SCAAT_CAM_4MB
		generic map(
			cam_count_log => 0,
			memDim        => INDEX_BITS,
			tag_bits      => TAG_BITS

		--addr_lencam_count_log	: positive	:= 2 => addr_length
		) -- length of pseudo-random sequence
		port map (
			clk      => clk,
			enable_w => com_en_sig,
			f_rst    => f_rst_sig,
			rst      => rst,
			addr     => unsigned(LFSR_out_sig),
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

	found_in_SCAAT <= true when mem_out(INDEX_BITS) = '1' else false;
	new_addr_star  <= true when attk = '1' else false;
	force_reset  <= true when f_rst_sig = '1' else false;
	com_en_sig     <= '1'  when attk = '1' else '0';



	found_in_scaat_edge_detector : process (clk, rst)
	begin
		if (rst = '1') then
			found_in_SCAAT_det  <= false;
		elsif rising_edge(clk) then
			found_in_SCAAT_det  <= found_in_SCAAT;
		end if;
	end process found_in_scaat_edge_detector;
	
	-- get the rising edge of the scaat signal
	found_in_SCAAT_rising_edge <= true when found_in_SCAAT and not(found_in_SCAAT_det) else false;
	f_rst_sig  <= '0';
	--SCAAT_thresh  <= 10;
	--found_counter : process (clk, rst)
	--begin
	--	if (rst = '1') then
	--		countSCAAT <= 0;
	--		f_rst_sig  <= '0';
	--	elsif rising_edge(clk) then
	--		if (countSCAAT = SCAAT_thresh) then
	--			countSCAAT <= 0;
	--			f_rst_sig  <= '1';
	---		elsif (found_in_SCAAT_rising_edge) then
	--			countSCAAT <= countSCAAT+1;
	--			f_rst_sig  <= '0';
	--		end if;
	--	end if;
	--end process found_counter;
	-- ___________________________
	-- >>	Use control signals to select output of the SCAAT unit and the 
	--		input to the memory if needed
	--addr_star <= cpu_addr;

	SCAAT_addr_out <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & unsigned(LFSR_out_sig) & cpu_addr(OFFSET_BITS-1 downto 0) when (new_addr_star and not force_reset) else
		cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & mem_out(INDEX_BITS-1 downto 0) & cpu_addr(OFFSET_BITS-1 downto 0) when (found_in_SCAAT and not force_reset) else
		cpu_addr;
	--rand_assign: process(cpu_addr,LFSR_out_sig,found_in_SCAAT,new_addr_star,mem_out)
	--	begin
	--		--	output is always the cpu address
	--		addr_star <= cpu_addr;
	--		--	if found in memory :

	--	if new_addr_star then
	--			--	the output is the LFSR output number
	--		addr_star <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & unsigned(LFSR_out_sig) & cpu_addr(OFFSET_BITS-1 downto 0);
	--	elsif found_in_SCAAT then 
	--		--	output is the address star in the memeory location
	--		addr_star <= cpu_addr(addr_length-1 downto OFFSET_BITS+INDEX_BITS) & mem_out(INDEX_BITS-1 downto 0) & cpu_addr(OFFSET_BITS-1 downto 0);
	--		--found_in_SCAAT_counter <= found_in_SCAAT_counter + 1;
	--	end if;
	--end process rand_assign;

	--SCAAT_addr_out <= addr_star;

	--------------------------------------------------------------------------------
	--  THIS IS ONLY FOR SIMULATION AND DATA COLLECTION							  --
	--------------------------------------------------------------------------------

	SIM_DATA : process(rst,new_addr_star)
	begin
		if (rst='1') then
			new_addr_star_counter <= (others => '0');
		elsif (new_addr_star) then
			new_addr_star_counter <= new_addr_star_counter + 1;
		end if;
	end process SIM_DATA;

	SIM_DATA3 : process(clk,rst)
	begin
		if (rst = '1') then
			R_active_c <= (others => '0');
		elsif (falling_edge(clk) and found_in_SCAAT_det and new_addr_star) then
			R_active_c <= R_active_c + 1;
		end if;
	end process SIM_DATA3;

	SCAAT_addr_out_count <= to_integer(unsigned(new_addr_star_counter));

	R_active <= to_integer(unsigned(R_active_c));

	f_in_SCAAT <= '1' when found_in_SCAAT_det else '0';

end architecture R_SCAAT;
