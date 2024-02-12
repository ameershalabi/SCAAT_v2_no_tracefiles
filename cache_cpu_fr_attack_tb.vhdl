-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:         Martin Zabel
--
-- Testbench:       Testbench for cache_cpu.
--
-- Description:
-- ------------------------------------
-- Test cache_cpu using two memories. One connected behind the cache, and one
-- directly attached to the CPU. The CPU compares the result of read requests
-- issued to the cache with the result from the direct attached memory.
--
-- CPU  ---+--- Cache (UUT) ---- 1st memory
--         |
--         +--- 2nd memory
--
-- License:
-- ============================================================================
-- Copyright 2016-2016 Technische Universitaet Dresden - Germany,
--										 Chair of VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use IEEE.std_logic_unsigned.all;

library poc;
use poc.utils.all;
use poc.physical.all;
-- simulation only packages
use poc.sim_types.all;
use poc.simulation.all;
use poc.waveform.all;
-- use PoC.type_def_pack.all;

library osvvm;
use osvvm.RandomPkg.all;


entity cache_cpu_tb is
end entity cache_cpu_tb;

architecture sim of cache_cpu_tb is
	constant CLOCK_FREQ : FREQ := 100 MHz;

	-- Cache configuration
  constant REPLACEMENT_POLICY : string   := "LRU";
  constant CACHE_LINES        : positive := 64;
  constant ASSOCIATIVITY      : positive := 1;
  constant CACHE_SETS		  : positive := CACHE_LINES/ASSOCIATIVITY;
  constant WAY_BITS 		  : integer  := log2ceil(ASSOCIATIVITY);
  constant SET_BITS 		  : positive := log2ceil(CACHE_SETS);


	-- Memory configuration
  constant MEM_ADDR_BITS      : positive := 10; -- 2^10 Memory locations
  constant MEM_DATA_BITS      : positive := 128; -- 16-Byte cache line size

	-- NOTE:
	-- Memory accesses are always aligned to a word boundary. Each memory word
	-- (and each cache line) consists of MEM_DATA_BITS bits.
	-- For example if MEM_DATA_BITS=128:
	--
	-- * memory address 0 selects the bits   0..127 in memory,
	-- * memory address 1 selects the bits 128..256 in memory, and so on.

	-- CPU configuration
	  constant CPU_DATA_BITS      : positive := 32;
	  constant RATIO 			  : positive := MEM_DATA_BITS/CPU_DATA_BITS;
	  constant CPU_ADDR_BITS      : positive := log2ceil(RATIO)+MEM_ADDR_BITS;
	  constant LOWER_ADDR_BITS	  : positive := log2ceil(RATIO);
	  constant MEMORY_WORDS       : natural := 2**CPU_ADDR_BITS;
	  constant BYTES_PER_WORD     : positive := CPU_DATA_BITS/8;

	-- NOTE:
	-- Cache accesses are always aligned to a CPU word boundary. Each CPU word
	-- consists of CPU_DATA_BITS bits. For example if CPU_DATA_BITS=32:
	--
	-- * CPU address 0 selects the bits   0.. 31 in memory word 0,
	-- * CPU address 1 selects the bits  32.. 63 in memory word 0,
	-- * CPU address 2 selects the bits  64.. 95 in memory word 0,
	-- * CPU address 3 selects the bits  96..127 in memory word 0,
	-- * CPU address 4 selects the bits   0.. 31 in memory word 1,
	-- * CPU address 5 selects the bits  32.. 63 in memory word 1, and so on.

	-- Global signals
	  signal clk : std_logic := '1';
	  signal rst : std_logic;
	  --signal Case_21_detected : std_logic := '0';
		-- Request from CPU
	  signal cpu_req   : std_logic;
	  signal cpu_write : std_logic;
	  signal cpu_addr  : unsigned(CPU_ADDR_BITS-1 downto 0);
	  signal cpu_wdata : std_logic_vector(CPU_DATA_BITS-1 downto 0);
	  signal cpu_wmask : std_logic_vector(CPU_DATA_BITS/8-1 downto 0);
	  signal cpu_got   : std_logic;

		-- Bus between CPU and Cache
		-- write / addr / wdata are directly connected to the CPU
	  signal cache_req   : std_logic;
	  signal cache_rstb  : std_logic;
	  signal cache_rdata : std_logic_vector(CPU_DATA_BITS-1 downto 0);

		-- Bus between Cache and 1st Memory
	  signal mem1_req   : std_logic;
	  signal mem1_write : std_logic;
	  signal mem1_addr  : unsigned(MEM_ADDR_BITS-1 downto 0);
	  signal mem1_wdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);
	  signal mem1_wmask : std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
	  signal mem1_rdy   : std_logic;
	  signal mem1_rstb  : std_logic;
	  signal mem1_rdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);

		-- Bus between CPU and 2nd Memory
		-- write / addr / wdata are directly connected to the CPU
	  signal mem2_req   : std_logic;
	  signal mem2_rdy   : std_logic;
	  signal mem2_rstb  : std_logic;
	  signal mem2_rdata : std_logic_vector(CPU_DATA_BITS-1 downto 0);

	-- Write-Data Generator
	signal wdata_got : std_logic;
	signal wdata_val : std_logic_vector(CPU_DATA_BITS-1 downto 0) := "00000000000000000000000000000000";

	-- Control signals between Request Generator and Checker of CPU
	signal finished : boolean := false;
	signal cache_Hit, cache_Miss : std_logic;
	signal process_type : character;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);

	-- The Cache + Wrapper
	--UUT: entity poc.cache_cpu
	--	generic map (
	--		REPLACEMENT_POLICY => REPLACEMENT_POLICY,
	--		CACHE_LINES        => CACHE_LINES,
	--		ASSOCIATIVITY      => ASSOCIATIVITY,
	--		CPU_DATA_BITS      => CPU_DATA_BITS,
	--		MEM_ADDR_BITS      => MEM_ADDR_BITS,
	--		MEM_DATA_BITS      => MEM_DATA_BITS)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		cpu_req   => cache_req,
	--		cpu_write => cpu_write,
	--		cpu_addr  => cpu_addr,
	--		cpu_wdata => cpu_wdata,
	--		cpu_wmask => cpu_wmask,
	--		cpu_got   => cpu_got,
	--		cpu_rdata => cache_rdata,
	--		mem_req   => mem1_req,
	--		mem_write => mem1_write,
	--		mem_addr  => mem1_addr,
	--		mem_wdata => mem1_wdata,
	--		mem_wmask => mem1_wmask,
	--		mem_rdy   => mem1_rdy,
	--		mem_rstb  => mem1_rstb,
	--		mem_rdata => mem1_rdata);

	UUT_with_Wapper: entity poc.cache_cpu_wrapper
--	UUT: entity poc.cache_cpu
		generic map (
			REPLACEMENT_POLICY => REPLACEMENT_POLICY,
			CACHE_LINES        => CACHE_LINES,
			ASSOCIATIVITY      => ASSOCIATIVITY,
			CPU_DATA_BITS      => CPU_DATA_BITS,
			MEM_ADDR_BITS      => MEM_ADDR_BITS,
			MEM_DATA_BITS      => MEM_DATA_BITS)
		port map (
			clk       => clk,
			rst       => rst,
			cpu_req   => cache_req,
			cpu_write => cpu_write,
			cpu_addr  => cpu_addr,
			cpu_wdata => cpu_wdata,
			cpu_wmask => cpu_wmask,
			cpu_got   => cpu_got,
			cpu_rdata => cache_rdata,
			mem_req   => mem1_req,
			mem_write => mem1_write,
			mem_addr  => mem1_addr,
			mem_wdata => mem1_wdata,
			mem_wmask => mem1_wmask,
			mem_rdy   => mem1_rdy,
			mem_rstb  => mem1_rstb,
			mem_rdata => mem1_rdata, 

			output_cache_Hit => cache_Hit, 
			output_cache_Miss => cache_Miss
);

	-- request only if also 2nd memory is ready
	cache_req <= cpu_req and mem2_rdy;

	-- read data is valid one clock cycle after cpu_got si asserted
	cache_rstb <= (not rst) and (not cpu_write) and cpu_got when rising_edge(clk);

	-- The 1st Memory
	memory1: entity work.mem_model
		generic map (
			A_BITS	=> MEM_ADDR_BITS,
			D_BITS	=> MEM_DATA_BITS)
		port map (
			clk       => clk,
			rst       => rst,
			mem_req   => mem1_req,
			mem_write => mem1_write,
			mem_addr  => mem1_addr,
			mem_wdata => mem1_wdata,
			mem_wmask => mem1_wmask,
			mem_rdy   => mem1_rdy,
			mem_rstb  => mem1_rstb,
			mem_rdata => mem1_rdata);

	-- The 2nd Memory
	memory2: entity work.mem_model
		generic map (
			A_BITS	=> CPU_ADDR_BITS,
			D_BITS	=> CPU_DATA_BITS)
		port map (
			clk       => clk,
			rst       => rst,
			mem_req   => mem2_req,
			mem_write => cpu_write,
			mem_addr  => cpu_addr,
			mem_wdata => cpu_wdata,
			mem_wmask => cpu_wmask,
			mem_rdy   => mem2_rdy,
			mem_rstb  => mem2_rstb,
			mem_rdata => mem2_rdata);

	-- request only if request is acknowledged by cache
	mem2_req <= cpu_got;

	-- The Write-Data Generator of the CPU
	--wdata_prng: entity poc.arith_prng
    --generic map (BITS => CPU_DATA_BITS)
    --port map (
      --clk => clk,
      --rst => rst,
      --got => wdata_got,
      --val => wdata_val);

	cpu_wdata <= wdata_val when cpu_write = '1' else (others => '-');
	wdata_got <= cpu_write and cpu_got and mem2_rdy;

	-- The Request Generator of the CPU
  CPU_RequestGen: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU RequestGen");

		-- no operation
		procedure nop is
		begin
			cpu_req   <= '0';
			cpu_write <= '-';
			cpu_addr  <= (others => '-');
			cpu_wmask <= (others => '-');
			wait until rising_edge(clk);
		end procedure;

		-- Write random data at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure write(
			addr       : in integer;
			data 	   : in integer;
			wmask      : in std_logic_vector(BYTES_PER_WORD-1 downto 0) := (others => '0')
		) is
			--variable cpu_addr_value: std_logic_vector (CPU_ADDR_BITS-1 downto 0);
			--variable all_zeros: std_logic_vector (LOWER_ADDR_BITS-1 downto 0) := (others => '0');		
		begin
			-- apply request (will be ignored if not ready)
			cpu_req   <= '1';
			cpu_write <= '1';

			cpu_addr  <= to_unsigned(addr, CPU_ADDR_BITS);
			wdata_val <= std_logic_vector(to_unsigned(data, CPU_DATA_BITS));

			-- cpu_addr_value := std_logic_vector(to_unsigned(addr,CPU_ADDR_BITS));
			-- cpu_addr <= unsigned(cpu_addr_value(CPU_ADDR_BITS-LOWER_ADDR_BITS-1 downto 0) & all_zeros);

			cpu_wmask <= wmask;
			while true loop
				wait until rising_edge(clk);
				exit when cpu_got = '1';
			end loop;
		end procedure;

		-- Write single byte of random data at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure write_byte(
			word_addr  : in integer;
			byte_addr  : in integer range 0 to BYTES_PER_WORD-1
		) is
			variable mask : std_logic_vector(BYTES_PER_WORD-1 downto 0);
		begin
			mask := (others => '1');
			mask(byte_addr) := '0';
			write(word_addr, 5, mask);
		end procedure;

-- (cpu_addr[LOWER_ADDR_BITS+SET_BITS+WAY_BITS-1:LOWER_ADDR_BITS] == $past(cpu_addr[LOWER_ADDR_BITS+SET_BITS+WAY_BITS-1:LOWER_ADDR_BITS]) + 1) 

		-- Read at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure read(addr : in integer) is
			--variable cpu_addr_value: std_logic_vector (CPU_ADDR_BITS-1 downto 0);
			--variable all_zeros: std_logic_vector (LOWER_ADDR_BITS-1 downto 0) := (others => '0');
		begin
			-- apply request (will be ignored if not ready)
			cpu_req   <= '1';
			cpu_write <= '0';
			cpu_addr  <= to_unsigned(addr*4,CPU_ADDR_BITS);
			--cpu_addr_value := std_logic_vector(to_unsigned(addr,CPU_ADDR_BITS));
			--cpu_addr  <= unsigned(cpu_addr_value(CPU_ADDR_BITS-LOWER_ADDR_BITS-1 downto 0) & all_zeros);
			cpu_wmask <= (others => '-');
			while true loop
				wait until rising_edge(clk);
				exit when cpu_got = '1';
			end loop;
		end procedure;

		-- Seeds for random request generation
		variable seed1 : positive := 4;
		variable seed2 : positive := 9;

		variable temp_r : real;
		variable temp_r2: real;

    	variable rand_addr : RandomPType;
    	variable rand_data : RandomPType;
    	variable rand_probability : RandomPType;
		variable addr : integer;
		variable attacker_addr, victim_addr : integer;

		variable address_vector, attacker_address_vector : std_logic_vector (CPU_ADDR_BITS-1 downto 0);
		variable victim_vector, victim_address_vector : std_logic_vector (CPU_ADDR_BITS-1 downto 0);
		variable cache_line_vector : std_logic_vector (SET_BITS-1 downto 0);
		variable probability : real;

		type 	 attacker_addr_range_type is array (0 to 7) of integer;
		type 	 victim_addr_range_type is array (0 to 3) of integer;

		constant attacker_addr_range_mapping_to_cache_lines : attacker_addr_range_type := (8, 12, 16, 20, 24, 28, 32, 36);
		constant attacker_addr_range_mapping_to_cache_line_2 : attacker_addr_range_type := (8, 9, 10, 11, 264, 265, 266, 267);
		constant victim_addr_range_mapping_to_cache_lines: victim_addr_range_type := (520, 524, 528, 532);
		constant victim_addr_range_mapping_to_cache_line_2: victim_addr_range_type := (520, 521, 522, 523);
		constant attacker_addr_range_mapping_to_cache_line_3 : attacker_addr_range_type := (12, 13, 14, 15, 268, 269, 270, 271);
		constant victim_addr_range_mapping_to_cache_line_3: victim_addr_range_type := (524, 525, 526, 527);

  		constant A1_AR_LOWER_BOUND : integer := 0;
  		constant A1_AR_UPPER_BOUND : integer := 383;
  		constant V1_VR_LOWER_BOUND : integer := 384;
  		constant V1_VR_UPPER_BOUND : integer := 767;
  		constant VX_LOWER_BOUND : integer := 384;
  		constant VX_UPPER_BOUND : integer := 767;
  begin


		rand_data.InitSeed(rand_data'instance_name);          
		rand_addr.InitSeed(rand_addr'instance_name);
		rand_probability.InitSeed(rand_probability'instance_name);          


		-- Not shared address space for attacker and victim

		---------------------------------------------------------------------------------------
		-- Case 21 (Prime+Probe)
		---------------------------------------------------------------------------------------
						rst <= '1';
	    				wait until rising_edge(clk);
	    				rst <= '0';
						for i in 0 to 3 loop nop; end loop;

		 -- Attacker accesses Cache Line 2 (Miss)
		 -- Victim accesses Cache Line 2 (Miss)
		 -- Attacker accesses Cache Line 2 (Miss)

		 -- 256 scenarios (covering Miss/Miss/Miss)
		for attacker_addr_1 in 0 to 63 loop 
			process_type <= 'A';
			read(attacker_addr_1);
		end loop;			
		
		for victim_addr_1 in 8 to 15 loop 
			process_type <= 'V';
			read(victim_addr_1+384);
			
			process_type <= 'A';
			read(victim_addr_1);
		end loop;			
		
		for victim_addr_2 in 32 to 39 loop 
			process_type <= 'V';
			read(victim_addr_2+384);
			
			process_type <= 'A';
			read(victim_addr_2);
		end loop;
		
		--for cache_line in 0 to CACHE_LINES-1 loop
		--	for VR_addr in V1_VR_LOWER_BOUND to V1_VR_UPPER_BOUND loop 
		--		for A1_addr in A1_AR_LOWER_BOUND to A1_AR_UPPER_BOUND loop 
		--			for Vx_addr in VX_LOWER_BOUND to VX_UPPER_BOUND loop

		--				cache_line_vector := std_logic_vector(to_unsigned(cache_line, SET_BITS)); -- For analyzing the cache line and set

		--			   	rst <= '1';
	 --   				wait until rising_edge(clk);
	 --   				rst <= '0';
		--				for i in 0 to 3 loop nop; end loop;

		--				wait until falling_edge(clk); -- V_R
		--				process_type <= 'V';
		--				victim_address_vector := std_logic_vector(to_unsigned(VR_addr, CPU_ADDR_BITS));
		--				if (cache_line_vector = victim_address_vector(SET_BITS+LOWER_ADDR_BITS-1 downto LOWER_ADDR_BITS)) then	
		--					read(VR_addr);
		--				end if;
		--				for i in 0 to 3 loop nop; end loop;

		--				wait until falling_edge(clk); -- A1
		--				process_type <= 'A';
		--				attacker_address_vector := std_logic_vector(to_unsigned(A1_addr, CPU_ADDR_BITS));
		--				if (cache_line_vector = attacker_address_vector(SET_BITS+LOWER_ADDR_BITS-1 downto LOWER_ADDR_BITS)) then
		--					read(A1_addr);
		--				end if;
		--				for i in 0 to 3 loop nop; end loop;

		--				wait until falling_edge(clk); -- Vx
		--				process_type <= 'V';
		--				victim_address_vector := std_logic_vector(to_unsigned(Vx_addr, CPU_ADDR_BITS));
		--				if (cache_line_vector = victim_address_vector(SET_BITS+LOWER_ADDR_BITS-1 downto LOWER_ADDR_BITS)) then
		--					read(Vx_addr);
		--				end if;
		--				for i in 0 to 3 loop nop; end loop;

		--			end loop;
		--		end loop;
		--	end loop;
		--end loop;

		

		---- Fill memory with valid data and read it back
		---- --------------------------------------------
		---- Due to the No-Write-Allocate policy no cache hit occurs.

		---- Write / read whole word
		---- ***********************
		--for addr in 0 to MEMORY_WORDS-1 loop
		-- 	write(addr);
		--end loop;  -- addr
		--for addr in 0 to MEMORY_WORDS-1 loop
		--	read(addr);
		--end loop;  -- addr
		--for i in 0 to 3 loop nop; end loop;

		---- Write single bytes, read whole word
		---- ***********************************
		--for word_addr in 0 to MEMORY_WORDS-1 loop
		--	for byte_addr in 0 to BYTES_PER_WORD-1 loop
		--		write_byte(word_addr, byte_addr);
		--	end loop;
		--end loop;  -- addr
		--for addr in 0 to MEMORY_WORDS-1 loop
		--	read(addr);
		--end loop;  -- addr
		--for i in 0 to 3 loop nop; end loop;

		---- Linear access, read/write/read at every address
		---- -----------------------------------------------

		---- Write / read whole word
		---- ***********************
		--for addr in 0 to MEMORY_WORDS-1 loop
		--	read(addr);  -- cache hit only if cache size equals memory size.
		--	write(addr); -- cache hit, write-through
		--	read(addr);  -- cache hit
		--	nop;
		--end loop;
		--for i in 0 to 3 loop nop; end loop;

		---- Write single bytes, read whole word
		---- ***********************************
		--for word_addr in 0 to MEMORY_WORDS-1 loop
		--	read(word_addr);  -- cache hit only if cache size equals memory size.
		--	for byte_addr in 0 to BYTES_PER_WORD-1 loop
		--		write_byte(word_addr, byte_addr);
		--		-- cache hit, write-through
		--	end loop;
		--	read(word_addr);  -- cache hit
		--	nop;
		--end loop;  -- word_addr
		--for i in 0 to 3 loop nop; end loop;

		---- Linear access in chunks of cache size, read/write/read every chunk
		---- ------------------------------------------------------------------

		---- Write / read whole word
		---- ***********************
		--for chunk in 0 to (MEMORY_WORDS / CACHE_LINES)-1 loop
		--	for addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		read(addr);  -- cache hit only if cache size equals memory size.
		--	end loop; -- addr
		--	for addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		write(addr); -- cache hit, write-through
		--	end loop; -- addr
		--	for addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		read(addr);  -- cache hit
		--	end loop; -- addr
		--	nop;
		--end loop;  -- chunk
		--for i in 0 to 3 loop nop; end loop;

		---- Write single bytes, read whole word
		---- ***********************************
		--for chunk in 0 to (MEMORY_WORDS / CACHE_LINES)-1 loop
		--	for word_addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		read(word_addr);  -- cache hit only if cache size equals memory size.
		--	end loop; -- word_addr
		--	for word_addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		for byte_addr in 0 to BYTES_PER_WORD-1 loop
		--			write_byte(word_addr, byte_addr); -- cache hit, write-through
		--		end loop;
		--	end loop; -- word_addr
		--	for word_addr in chunk*CACHE_LINES to (chunk+1)*CACHE_LINES-1 loop
		--		read(word_addr);  -- cache hit
		--	end loop; -- word_addr
		--	nop;
		--end loop;  -- chunk
		--for i in 0 to 3 loop nop; end loop;

		---- Random access
		---- -------------
		--for i in 1 to 2000 loop
		--	uniform(seed1, seed2, temp_r);
		--	if temp_r < 0.5 then -- read
		--		uniform(seed1, seed2, temp_r);
		--		read(natural(floor(temp_r * real(MEMORY_WORDS"))));
		--	else -- write
		--		uniform(seed1, seed2, temp_r);
		--		if temp_r < 0.5 then -- write whole word
		--			uniform(seed1, seed2, temp_r);
		--			write(natural(floor(temp_r * real(MEMORY_WORDS"))));
		--		else -- write single byte
		--			temp_r2 := (temp_r-0.5) * 2.0; -- change range to [0:1)
		--			uniform(seed1, seed2, temp_r);
		--			write_byte(
		--				natural(floor(temp_r * real(MEMORY_WORDS))),
		--				natural(floor(temp_r2 * real(BYTES_PER_WORD"))));
		--		end if;
		--	end if;
		--end loop;

		-- Finished
		-- --------
		nop;
		finished  <= true;
		simDeactivateProcess(simProcessID);
    wait;
  end process CPU_RequestGen;

	-- The Checker of the CPU
	CPU_Checker: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU Checker");
		variable saved_rdata  : std_logic_vector(CPU_DATA_BITS-1 downto 0);
	begin
		-- wait until reset completes
		wait until rising_edge(clk) and rst = '0';

		-- wait until all requests have been applied
		while not finished loop
			wait until rising_edge(clk);
			simAssertion(not is_x(cache_rstb) and not is_x(mem2_rstb), "Meta-value on rstb.");
			if mem2_rstb = '1' then
				saved_rdata := mem2_rdata;
				-- If cache does not return data in same clock cycle (i.e. cache miss),
				-- then wait for cache_rstb.
				while cache_rstb = '0' loop
					wait until rising_edge(clk);
					-- No new data from 2nd memory must arrive here.
					simAssertion(not is_x(cache_rstb) and mem2_rstb = '0',
											 "Meta-value on rstb or invalid reply from 2nd memory.");
				end loop;

				simAssertion(cache_rdata = saved_rdata, "Read data differs.");
			end if;
		end loop;

		simDeactivateProcess(simProcessID);
		simFinalize;
		wait;
	end process CPU_Checker;


end architecture sim;