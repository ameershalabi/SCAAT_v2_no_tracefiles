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
use ieee.std_logic_textio.all;
use std.textio.all;
--use std_logic_arith.all;
--use fixed_generic_pkg.all;

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
	constant CLOCK_FREQ : FREQ := 2000 MHz;
	---- Best Cache Configuration for Benchmarks 
	--  CACHE_LINES ---> 256
	--  ASSOCIATIVITY ---> 1
	--  MEM_ADDR_BITS ---> 27
	--  CPU_ADDR_BITS ---> 32
	--  MEM_DATA_BITS ---> 1024
	--  CPU_DATA_BITS ---> 32
	-- Cache configuration
	constant REPLACEMENT_POLICY : string   := "LRU";
	constant CACHE_LINES        : positive := 4096;
	--constant ASSOCIATIVITY      : positive := 1; --Direct mapped 32bit bench
	--constant CACHE_LINES        : positive := 512; --k-way associative 32bit bench
	constant ASSOCIATIVITY : positive := 1;           --k-way associative 32bit bench
	constant CACHE_SETS    : positive := CACHE_LINES; -- /ASSOCIATIVITY;
	constant WAY_BITS      : integer  := log2ceil(ASSOCIATIVITY);
	constant SET_BITS      : natural  := log2ceil(CACHE_SETS);


	-- Memory configuration
	constant MEM_ADDR_BITS : positive := 28;  -- 2^10 Memory locations
	constant MEM_DATA_BITS : positive := 512; -- 16-Byte cache line size

	-- NOTE:
	-- Memory accesses are always aligned to a word boundary. Each memory word
	-- (and each cache line) consists of MEM_DATA_BITS bits.
	-- For example if MEM_DATA_BITS=128:
	--
	-- * memory address 0 selects the bits   0..127 in memory,
	-- * memory address 1 selects the bits 128..256 in memory, and so on.

	-- CPU configuration
	constant CPU_DATA_BITS   : positive := 32;
	constant RATIO           : positive := MEM_DATA_BITS/CPU_DATA_BITS;
	constant CPU_ADDR_BITS   : positive := log2ceil(RATIO)+MEM_ADDR_BITS;
	constant LOWER_ADDR_BITS : positive := log2ceil(RATIO);
	constant MEMORY_WORDS    : natural  := 2**CPU_ADDR_BITS;
	constant BYTES_PER_WORD  : positive := CPU_DATA_BITS/8;
	constant process_ID_len  : positive := 3;




	constant low_bound_set  : positive := 4;
	constant high_bound_set : positive := 15;

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
	signal cpu_req    : std_logic;
	signal cpu_write  : std_logic;
	signal cpu_addr   : unsigned(CPU_ADDR_BITS-1 downto 0);
	signal SCAAT_addr : unsigned(CPU_ADDR_BITS-1 downto 0);

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
	signal finished              : boolean := false;
	signal finished_while        : boolean := false;
	signal cache_Hit, cache_Miss : std_logic;
	signal bench_miss_enable     : std_logic;
	signal process_type          : character;
	signal target_bench          : character;
	signal SCAAT_v               : character;
	------ FILE READER SIGNALS -- AMSHAL
	file file_VECTORS           : text;
	file Stats                  : text;
	file CLD_attk_Histo_RESULTS : text;
	file IRQ_attk_Histo_RESULTS : text;
	file SVA_attk_Histo_RESULTS : text;
	file access_Histo_RESULTS   : text;
	file miss_Histo_RESULTS     : text;


	file MKPI_0 : text;
	file MKPI_1 : text;
	file MKPI_2 : text;
	file MKPI_3 : text;
	file MKPI_4 : text;
	file MKPI_5 : text;
	file MKPI_6 : text;
	file MKPI_7 : text;

	file CLD_attk_hist : text;
	file IRQ_attk_hist : text;
	file Bench_0       : text;


	signal ctx_string : string(1 to 34) := "__________________________________";

	--file file_RESULTS : text;
	file attk_RESULTS : text;
	signal ADDR_HEX   : string(1 to 13);
	signal op         : character;
	--signal input_addr_vector : std_logic_vector(31 downto 0);
	signal addr_int : integer;
	--AMSHAL 
	--signal ralloc_RandX  : unsigned(CPU_ADDR_BITS-1 downto 0); --address from checker to reallocator
	--signal addr_star  : unsigned(CPU_ADDR_BITS-1 downto 0); --address output from reallocator
	type CORE_ARRAY is array (7 downto 0) of integer;
	signal MKPI_arr   : CORE_ARRAY := (others => 0);
	signal miss_arr   : CORE_ARRAY := (others => 0);
	signal MKmiss_arr : CORE_ARRAY := (others => 0);
	signal access_arr : CORE_ARRAY := (others => 0);

	--signal IRQ_attk_arr : CORE_ARRAY := (others => 0);
	signal attk_arr : CORE_ARRAY := (others => 0);
	--signal CLDattk_arr   : CORE_ARRAY := (others => 0);


	--type FILE_ARRAY is array (7 downto 0) of file;
	--signal MKPI_file_array : FILE_ARRAY;


	type Histogram_accesses is array (CACHE_SETS-1 downto 0) of natural;
	signal Histogram    : Histogram_accesses;
	signal CLD_attk_arr : Histogram_accesses;
	signal IRQ_attk_arr : Histogram_accesses;


	type Histogram_cores is array (CACHE_SETS-1 downto 0,7 downto 0) of natural;
	signal Histo_access : Histogram_cores;
	signal Histo_miss   : Histogram_cores;
	--signal Histo_CLD_   : Histogram_cores;

	type safe_proc_arr is array (7 downto 0) of std_logic_vector(2 downto 0);
	signal safe_procs : safe_proc_arr := ("111", "110", "101", "100", "011", "010", "001", "000");

	signal attk                   : std_logic;        -- attack signal from checker
	signal attk_deactive          : std_logic := '0'; -- attack signal from checker
	signal attk_active            : std_logic := '0'; -- attack signal from checker
	signal caseNum                : std_logic_vector(4 downto 0);
	signal SCAAT_env_trace_vector : std_logic_vector(33 downto 0) := "0000000000000000000000000000000000";
	signal diff_index             : boolean;
	signal diff_index2            : boolean;
	signal diff_index3            : boolean;
	signal en_SVA                 : std_logic;
	signal en_CLD                 : std_logic;

	signal ADDR_ORG : string(1 to 11);

	signal prev_hex_addr_reg  : unsigned(CPU_ADDR_BITS-1 downto 0);
	signal prev_hex_addr_reg2 : unsigned(CPU_ADDR_BITS-1 downto 0);
	signal prev_hex_addr_reg3 : unsigned(CPU_ADDR_BITS-1 downto 0);



	signal TOTALACCESScounter        : std_logic_vector(31 downto 0);
	signal ACCESScounter             : std_logic_vector(31 downto 0);
	signal ACCESShistocounter        : integer := 0;
	signal miss_count                : integer := 0;
	signal miss_count_BENCH          : integer := 0;
	signal MPKI                      : integer := 0;
	signal MPKI_BENCH                : integer := 0;
	signal MPKI_el                   : integer := 0;
	signal MPKI_miss,MPKI_miss_BENCH : integer := 0;
	signal cur_ctx                   : integer := 0;
	signal SCAAT_addr_out_c          : integer := 0;
	signal R_active                  : integer := 0;
	signal CLD_attk_counter          : integer := 0;
	signal IRQ_attk_counter          : integer := 0;
	signal attk_counter              : integer := 0;






	signal f_in_SCAAT : std_logic;
	signal IRQ        : std_logic;

	signal found_in_SCAAT_count_reg : integer := 0;
	signal core_bench_num           : integer := 0;

	signal process_ID_tb      : std_logic_vector(process_ID_len - 1 downto 0);
	signal safe_process_ID_tb : std_logic_vector(process_ID_len - 1 downto 0);
	signal safety_tb          : std_logic;




	signal core_bench : character;


	signal PREG_PROTECT_L : integer := 1;
	signal PREG_PROTECT_H : integer := 2**MEM_ADDR_BITS;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);


	--UUT: entity poc.cache_cpu_wrapper
	--UUT: entity poc.cache_cpu
	UUT : entity poc.cache_cpu_SCAAT
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


			output_cache_Hit  => cache_Hit,
			output_cache_Miss => cache_Miss,
			SCAAT_addr_out_c  => SCAAT_addr_out_c,
			R_active          => R_active,
			f_in_SCAAT        => f_in_SCAAT,
			SCAAT_addr        => SCAAT_addr,
			--SCAAT AMSHAL
			IRQ     => IRQ,
			attk_in => attk_active --attk_deactive --attk --attk_active
		);

	-- request only if also 2nd memory is ready
	cache_req <= cpu_req and mem2_rdy;

	-- read data is valid one clock cycle after cpu_got si asserted
	cache_rstb <= (not rst) and (not cpu_write) and cpu_got when rising_edge(clk);

	-- The 1st Memory
	memory1 : entity work.mem_model2
		generic map (
			A_BITS => MEM_ADDR_BITS,
			D_BITS => MEM_DATA_BITS)
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

	--The 2nd Memory
	memory2 : entity work.mem_model2
		generic map (
			A_BITS => CPU_ADDR_BITS,
			D_BITS => CPU_DATA_BITS)
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


	UUT_with : entity work.SI_FSM
		generic map (
			CACHE_SETS     => CACHE_SETS,
			INDEX_BITS     => SET_BITS,
			OFFSET_BITS    => LOWER_ADDR_BITS,
			CPU_ADDR_BITS  => CPU_ADDR_BITS,
			process_ID_len => process_ID_len
		)
		port map (
			clk => clk,
			rst => rst,
			-- cache hit and miss indicators
			Hit_Sig_cache  => cache_Hit,
			Miss_Sig_cache => cache_Miss,
			cache_OP       => cpu_write,
			cache_newAddr  => en_CLD,
			cpu_addr       => cpu_addr,
			--- current process perfroming access to the cache
			process_ID => process_ID_tb,
			--- process we want to secure
			safe_process_ID => safe_process_ID_tb,
			safety          => safety_tb
		);
	-- request only if request is acknowledged by cache
	mem2_req <= cpu_got;



	cpu_wdata <= wdata_val when cpu_write = '1' else (others => '-');
	wdata_got <= cpu_write and cpu_got and mem2_rdy;

	-- The Request Generator of the CPU
	CPU_RequestGen : process
		constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("CPU RequestGen");

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
				addr : in unsigned(CPU_ADDR_BITS-1 downto 0);
				--addr       : in integer;
				--data 	   : in integer;
				wmask : in std_logic_vector(BYTES_PER_WORD-1 downto 0) := (others => '0')
			) is

		begin
			cpu_req   <= '1';
			cpu_write <= '1';

			cpu_addr <= addr;


			cpu_wmask <= wmask;
			while true loop
				wait until rising_edge(clk);
				exit when cpu_got = '1';
			end loop;
		end procedure;


		procedure read(
				addr : in unsigned(CPU_ADDR_BITS-1 downto 0)
			--addr : in integer
			) is

		begin
			cpu_req   <= '1';
			cpu_write <= '0';
			cpu_addr  <= addr;

			cpu_wmask <= (others => '-');
			while true loop
				wait until rising_edge(clk);
				exit when cpu_got = '1';
			end loop;
		end procedure;

		-- Seeds for random request generation
		variable seed1 : positive := 4;
		variable seed2 : positive := 9;

		variable temp_r  : real;
		variable temp_r2 : real;

		variable rand_addr                  : RandomPType;
		variable rand_data                  : RandomPType;
		variable rand_probability           : RandomPType;
		variable addr                       : integer;
		variable attacker_addr, victim_addr : integer;

		variable v_ILINE                 : line;
		variable v_OLINE                 : line;
		variable v_OLINE_miss            : line;
		variable v_OLINE_access          : line;
		variable v_OLINE_stats           : line;
		variable v_OLINE_bench_miss      : line;
		variable v_OLINE_bench_MKPI_miss : line;
		variable v_O1LINE                : line;
		variable v_O2LINE                : line;
		variable v_O3LINE                : line;
		variable v_O4LINE                : line;
		variable v_OLINE_histo           : line;
		variable v_OLINE_histo_miss      : line;

		variable MKPI_0_line : line;
		variable MKPI_1_line : line;
		variable MKPI_2_line : line;
		variable MKPI_3_line : line;
		variable MKPI_4_line : line;
		variable MKPI_5_line : line;
		variable MKPI_6_line : line;
		variable MKPI_7_line : line;
		variable MKPI_line   : line;

		variable attkTrace : line;
		variable v_OP      : character;
		variable v_SPACE1  : character;

		variable v_ADDR_HEX : string(1 to 13);
		variable v_SPACE2   : character;
		variable v_CORE     : character;
		variable v_CORE_B   : character;
		variable v_LAST     : integer;

		variable v_Vector        : std_logic_vector(3 downto 0);
		variable v_addr_Vector   : std_logic_vector(43 downto 0);
		variable v_addr          : std_logic_vector(CPU_ADDR_BITS-1 downto 0);
		variable factor          : unsigned(31 downto 0);
		variable SCAAT_set       : unsigned(SET_BITS-1 downto 0);
		variable hist_int        : integer;
		variable Data_trace_file : string(1 to 58) := "/home/amshal/pc/Projects/TRACEFILES/DataCacheAccessTraces/";
		variable full_trace_file : string(1 to 53) := "/home/amshal/pc/Projects/TRACEFILES/DATA_INST_traces/";
		variable ctx_trace_file  : string(1 to 47) := "/home/amshal/pc/Projects/TRACEFILES/ctx_traces/";
		variable output_name     : string(1 to 22) := "CTX_1_Target_b_SCAAT_b";
		variable full_name       : string(1 to 52) := "./ctx_histo/BASELIN/ctx_1_out/CTX_1_Target_b_SCAAT_b";

		variable MPKI_str     : string(1 to 20) := "____________________";
		variable ctx_MPKI_str : string(1 to 10) := "__________";
		variable ctx_id       : string(1 to 5)  := "ctx_i";
		variable trace_file   : string(1 to 15) := "_______________";
		variable ctx_folder   : string(1 to 30) := "______________________________";
		variable target_SCAAT : string(1 to 2)  := "__";

	begin
		rand_data.InitSeed(rand_data'instance_name);
		rand_addr.InitSeed(rand_addr'instance_name);
		rand_probability.InitSeed(rand_probability'instance_name);


		-- safe process
		output_name(22) := 'T'; -- SCAAT version

		safe_proc : for safe in 0 to 7 loop
			--output_name(14)    := 'D';
			safe_process_ID_tb <= "010"; --incomplete
			                             --when 1 =>
			                             --output_name(14)    := '1';
			                             --safe_process_ID_tb <= "001";
			case (safe) is
				when 0 =>
					output_name(14)    := '0';
					safe_process_ID_tb <= "000"; --incomplete
				when 1 =>
					output_name(14)    := '1';
					safe_process_ID_tb <= "001";

				when 2 =>
					output_name(14)    := '2';
					safe_process_ID_tb <= "010";

				when 3 =>
					output_name(14)    := '3';
					safe_process_ID_tb <= "011";

				when 4 =>
					output_name(14)    := '4';
					safe_process_ID_tb <= "100";

				when 5 =>
					output_name(14)    := '5';
					safe_process_ID_tb <= "101";

				when 6 =>
					output_name(14)    := '6';
					safe_process_ID_tb <= "110";

				when 7 =>
					output_name(14)    := '7';
					safe_process_ID_tb <= "111";
				when others =>
					null;
			end case;

			trace_file     := "ctx_T_TST.trace";
			output_name(5) := 'i';

			if (output_name(22) = 'b') then
				ctx_folder := "./ctx_histo/BASELIN/ctx_"&trace_file(5)&"_out/";
			elsif (output_name(22) = '1') then
				ctx_folder := "./ctx_histo/1_SCAAT/ctx_"&trace_file(5)&"_out/";
			elsif (output_name(22) = '2') then
				ctx_folder := "./ctx_histo/R_SCAAT/ctx_"&trace_file(5)&"_out/";
			elsif (output_name(22) = 'W') then
				ctx_folder := "./ctx_histo/WORSTCS/ctx_i_out/";
			else
				ctx_folder := "./ctx_histo/FORTEST/ctx_1_out/";
			end if;

			finished_while <= false;
			--ctx_run : for ctx in 1 to 7 loop

			--end case;

			full_name := ctx_folder&output_name;
			file_open(CLD_attk_Histo_RESULTS, full_name&"_"&trace_file(1 to 9)&"_attk_CLD.txt", write_mode);
			file_open(IRQ_attk_Histo_RESULTS, full_name&"_"&trace_file(1 to 9)&"_attk_IRQ.txt", write_mode);
			file_open(SVA_attk_Histo_RESULTS, full_name&"_"&trace_file(1 to 9)&"_attk_SVA.txt", write_mode);
			file_open(access_Histo_RESULTS, full_name&"_"&trace_file(1 to 9)&"_histogram.txt", write_mode);
			file_open(miss_Histo_RESULTS, full_name&"_"&trace_file(1 to 9)&"_miss_histo.txt", write_mode);

			file_open(Stats, full_name&"_"&trace_file(1 to 9)&"_Stats.txt", write_mode);


			file_open(MKPI_0, full_name&"_"&trace_file(1 to 9)&"_MKPI_0.txt", write_mode);
			file_open(MKPI_1, full_name&"_"&trace_file(1 to 9)&"_MKPI_1.txt", write_mode);
			file_open(MKPI_2, full_name&"_"&trace_file(1 to 9)&"_MKPI_2.txt", write_mode);
			file_open(MKPI_3, full_name&"_"&trace_file(1 to 9)&"_MKPI_3.txt", write_mode);
			file_open(MKPI_4, full_name&"_"&trace_file(1 to 9)&"_MKPI_4.txt", write_mode);
			file_open(MKPI_5, full_name&"_"&trace_file(1 to 9)&"_MKPI_5.txt", write_mode);
			file_open(MKPI_6, full_name&"_"&trace_file(1 to 9)&"_MKPI_6.txt", write_mode);
			file_open(MKPI_7, full_name&"_"&trace_file(1 to 9)&"_MKPI_7.txt", write_mode);

			--file_open(Bench_0, full_name"_"&trace_file(1 to 9)&"SCAAT_addr_list.txt", write_mode);

			file_open(CLD_attk_hist, full_name&"_"&trace_file(1 to 9)&"_attk_hist_CLD.txt", write_mode);
			file_open(IRQ_attk_hist, full_name&"_"&trace_file(1 to 9)&"_attk_hist_IRQ.txt", write_mode);

			file_open(file_VECTORS, ctx_trace_file&trace_file, read_mode);

			--file_open(file_VECTORS, ctx_trace_file&"ctx_1_4KB.trace", read_mode); ctx_MPKI_str := "CTX1_hist_"; ctx_folder := "./ctx_1_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_2_4KB.trace", read_mode); ctx_MPKI_str := "CTX2_stat_"; ctx_folder := "./ctx_2_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_3_4KB.trace", read_mode); ctx_MPKI_str := "CTX3_stat_"; ctx_folder := "./ctx_3_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_4_4KB.trace", read_mode); ctx_MPKI_str := "CTX4_stat_"; ctx_folder := "./ctx_4_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_5_4KB.trace", read_mode); ctx_MPKI_str := "CTX5_stat_"; ctx_folder := "./ctx_5_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_6_4KB.trace", read_mode); ctx_MPKI_str := "CTX6_stat_"; ctx_folder := "./ctx_6_out/";
			--file_open(file_VECTORS, ctx_trace_file&"ctx_7_4KB.trace", read_mode); ctx_MPKI_str := "CTX7_stat_"; ctx_folder := "./ctx_7_out/";

			--file_open(Miss_Histo_RESULTS, ctx_folder&"CTX_"&integer'image(cur_ctx)&"_"&ctx_MPKI_str& target_SCAAT&".txt", write_mode);
			--file_open(CLD_attk_Histo_RESULTS, ctx_folder&"CTX_"&integer'image(cur_ctx)&"_"&target_SCAAT& "_CTX_attk_histo.txt", write_mode);
			--file_open(access_Histo_RESULTS, ctx_folder&"CTX_"&integer'image(cur_ctx)&"_"&target_SCAAT& "_CTX_histogram.txt", write_mode);

			--file_open(Miss_Histo_RESULTS, ctx_folder&output_name&".txt", write_mode);

			core_bench_num <= 0;
			rst            <= '1';
			--ACCESScounter      <= (others => '0');
			--TOTALACCESScounter <= (others => '0');

			wait until rising_edge(clk);
			ACCESScounter      <= (others => '0');
			TOTALACCESScounter <= (others => '0');
			--
			Histogram    <= (others => 0);
			Histo_access <= (others => (others => 0));

			--IRQ_attk_arr <= (others => 0);

			access_arr    <= (others => 0);
			access_arr(0) <= 0;
			rst           <= '0';
			--for i in 0 to 1 loop nop; end loop;




			while (finished_while = false) loop
				v_addr_Vector := "00000000000000000000000000000000000000000000";
				v_addr_Vector := (others => "0");

				ADDR_HEX <= "0xfffffffffff";
				--				"0x04b44784781"
				v_ADDR_HEX := "0xfffffffffff";
				op         <= '0';
				core_bench <= '0';
				readline(file_VECTORS, v_ILINE);
				read(v_ILINE, v_OP);
				op <= v_OP;
				read(v_ILINE, v_SPACE1);
				read(v_ILINE, v_ADDR_HEX);
				ADDR_ORG <= v_ADDR_HEX;
				read(v_ILINE, v_SPACE2);
				read(v_ILINE, v_CORE);
				core_bench <= v_CORE;

				if (v_CORE /= '8') then
					v_ADDR_HEX(3) := v_CORE;
					--v_ADDR_HEX(7) := v_ADDR_HEX(3);
					-- w 0x04b44784781 1
					ADDR_HEX <= v_ADDR_HEX;
					for ii in 3 to 13 loop
						case v_ADDR_HEX(ii) is
							when '0'    => v_Vector := std_logic_vector'(x"0");
							when '1'    => v_Vector := std_logic_vector'(x"1");
							when '2'    => v_Vector := std_logic_vector'(x"2");
							when '3'    => v_Vector := std_logic_vector'(x"3");
							when '4'    => v_Vector := std_logic_vector'(x"4");
							when '5'    => v_Vector := std_logic_vector'(x"5");
							when '6'    => v_Vector := std_logic_vector'(x"6");
							when '7'    => v_Vector := std_logic_vector'(x"7");
							when '8'    => v_Vector := std_logic_vector'(x"8");
							when '9'    => v_Vector := std_logic_vector'(x"9");
							when 'a'    => v_Vector := std_logic_vector'(x"a");
							when 'A'    => v_Vector := std_logic_vector'(x"a");
							when 'b'    => v_Vector := std_logic_vector'(x"b");
							when 'B'    => v_Vector := std_logic_vector'(x"b");
							when 'c'    => v_Vector := std_logic_vector'(x"c");
							when 'C'    => v_Vector := std_logic_vector'(x"c");
							when 'd'    => v_Vector := std_logic_vector'(x"d");
							when 'D'    => v_Vector := std_logic_vector'(x"d");
							when 'e'    => v_Vector := std_logic_vector'(x"e");
							when 'E'    => v_Vector := std_logic_vector'(x"e");
							when 'f'    => v_Vector := std_logic_vector'(x"f");
							when 'F'    => v_Vector := std_logic_vector'(x"f");
							when others => v_Vector := std_logic_vector'(x"0");
						end case;

						case ii is
							when 3      => v_addr_Vector(43 downto 40) := v_Vector;
							when 4      => v_addr_Vector(39 downto 36) := v_Vector;
							when 5      => v_addr_Vector(35 downto 32) := v_Vector;
							when 6      => v_addr_Vector(31 downto 28) := v_Vector;
							when 7      => v_addr_Vector(27 downto 24) := v_Vector;
							when 8      => v_addr_Vector(23 downto 20) := v_Vector;
							when 9      => v_addr_Vector(19 downto 16) := v_Vector;
							when 10     => v_addr_Vector(15 downto 12) := v_Vector;
							when 11     => v_addr_Vector(11 downto 8)  := v_Vector;
							when 12     => v_addr_Vector(7 downto 4)   := v_Vector;
							when 13     => v_addr_Vector(3 downto 0)   := v_Vector;
							when others => v_addr_Vector(31 downto 27) := v_Vector;
						end case;
					end loop;
					bench_miss_enable <= '1' when target_bench = core_bench else '0';

					case (v_CORE) is
						when '1'    => core_bench_num <= 1; process_ID_tb <= "001";
						when '2'    => core_bench_num <= 2; process_ID_tb <= "010";
						when '3'    => core_bench_num <= 3; process_ID_tb <= "011";
						when '4'    => core_bench_num <= 4; process_ID_tb <= "100"; --v_addr_Vector(13) := '1';
						when '5'    => core_bench_num <= 5; process_ID_tb <= "101"; --v_addr_Vector(13) := '1';
						when '6'    => core_bench_num <= 6; process_ID_tb <= "110"; --v_addr_Vector(13) := '1';
						when '7'    => core_bench_num <= 7; process_ID_tb <= "111"; --v_addr_Vector(13) := '1';
						when others => core_bench_num <= 0; process_ID_tb <= "000";
					end case;



					access_arr(core_bench_num) <= access_arr(core_bench_num)+1;

					--if (v_CORE = '0') then
					--	write(v_O1LINE,v_OP& ' ' &v_ADDR_HEX& ' ' & v_CORE);
					--	writeline(Bench_0, v_O1LINE);
					--end if;


					if (access_arr(1)=0 and access_arr(2)=0 and access_arr(3)=0 and access_arr(4)=0) then
						if (access_arr(5)=0 and access_arr(6)=0 and access_arr(7)=0) then
							access_arr(0) <= 0;
						end if;
					end if;
					if op = 'l' or op = 'w' or op = 'r' then
						ACCESScounter      <= ACCESScounter + 1;
						TOTALACCESScounter <= TOTALACCESScounter + 1;
						read(unsigned(v_addr_Vector(CPU_ADDR_BITS-1 downto 0)));
					elsif op = 's' then
						ACCESScounter      <= ACCESScounter + 1;
						TOTALACCESScounter <= TOTALACCESScounter + 1;
						write(unsigned(v_addr_Vector(CPU_ADDR_BITS-1 downto 0)));
					end if;

					SCAAT_set := SCAAT_addr(high_bound_set downto low_bound_set);
					hist_int  := to_integer(SCAAT_set);

					Histogram(hist_int)                   <= Histogram(hist_int) + 1;
					Histo_access(hist_int,core_bench_num) <= Histo_access(hist_int,core_bench_num) + 1;

					if (ACCESScounter = 998) then
						write(v_O4LINE, ' '&integer'image(CLD_attk_counter));
						writeline(CLD_attk_Histo_RESULTS, v_O4LINE);

						write(v_O3LINE, ' '&integer'image(attk_counter));
						writeline(SVA_attk_Histo_RESULTS, v_O3LINE);

						write(v_O2LINE, ' '&integer'image(IRQ_attk_counter));
						writeline(IRQ_attk_Histo_RESULTS, v_O2LINE);

					end if;
					if (ACCESScounter = 1000) then
						ACCESScounter <= (others => '0');
					end if;
					if (access_arr(core_bench_num) mod 1000 = 0) then
						write(MKPI_line, ' ' & integer'image(MKPI_arr(core_bench_num)));
						case (core_bench_num) is
							when 1 =>
								writeline(MKPI_1, MKPI_line);
							when 2 =>
								writeline(MKPI_2, MKPI_line);
							when 3 =>
								writeline(MKPI_3, MKPI_line);
							when 4 =>
								writeline(MKPI_4, MKPI_line);
							when 5 =>
								writeline(MKPI_5, MKPI_line);
							when 6 =>
								writeline(MKPI_6, MKPI_line);
							when 7 =>
								writeline(MKPI_7, MKPI_line);
							when 0 =>
								writeline(MKPI_0, MKPI_line);
							when others =>
								null;
						end case;
					end if;

					if ((to_integer(unsigned(TOTALACCESScounter) mod 1500000) = 0) and (to_integer(unsigned(TOTALACCESScounter))/= 0)) then
						finished_while <= true;

						writeLoop111 : for locat in CACHE_SETS-1 downto 0 loop
							write(v_OLINE_histo, ' '&integer'image(CLD_attk_arr(locat))&' ');
							writeline(CLD_attk_hist, v_OLINE_histo);
						end loop writeLoop111;

						writeLoop112 : for locat in CACHE_SETS-1 downto 0 loop
							write(v_OLINE_histo, ' '&integer'image(IRQ_attk_arr(locat))&' ');
							writeline(IRQ_attk_hist, v_OLINE_histo);
						end loop writeLoop112;

						writeLoop : for locat in CACHE_SETS-1 downto 0 loop
							write(v_OLINE_histo, ' '&
								integer'image(Histo_access(locat,0))&' '&
								integer'image(Histo_access(locat,1))&' '&
								integer'image(Histo_access(locat,2))&' '&
								integer'image(Histo_access(locat,3))&' '&
								integer'image(Histo_access(locat,4))&' '&
								integer'image(Histo_access(locat,5))&' '&
								integer'image(Histo_access(locat,6))&' '&
								integer'image(Histo_access(locat,7))
							);
							writeline(access_Histo_RESULTS, v_OLINE_histo);
						end loop writeLoop;

						writeLoop_miss : for locat in CACHE_SETS-1 downto 0 loop
							write(v_OLINE_histo_miss, ' '&
								integer'image(Histo_miss(locat,0))&' '&
								integer'image(Histo_miss(locat,1))&' '&
								integer'image(Histo_miss(locat,2))&' '&
								integer'image(Histo_miss(locat,3))&' '&
								integer'image(Histo_miss(locat,4))&' '&
								integer'image(Histo_miss(locat,5))&' '&
								integer'image(Histo_miss(locat,6))&' '&
								integer'image(Histo_miss(locat,7))
							);
							writeline(miss_Histo_RESULTS, v_OLINE_histo_miss);
						end loop writeLoop_miss;

						write(v_OLINE_miss,
							integer'image(miss_count)&' '&
							integer'image(miss_arr(0))&' '&
							integer'image(miss_arr(1))&' '&
							integer'image(miss_arr(2))&' '&
							integer'image(miss_arr(3))&' '&
							integer'image(miss_arr(4))&' '&
							integer'image(miss_arr(5))&' '&
							integer'image(miss_arr(6))&' '&
							integer'image(miss_arr(7)));
						writeline(Stats, v_OLINE_miss);

						write(v_OLINE_access,
							integer'image(to_integer(unsigned(TOTALACCESScounter)))&' '&
							integer'image(access_arr(0))&' '&
							integer'image(access_arr(1))&' '&
							integer'image(access_arr(2))&' '&
							integer'image(access_arr(3))&' '&
							integer'image(access_arr(4))&' '&
							integer'image(access_arr(5))&' '&
							integer'image(access_arr(6))&' '&
							integer'image(access_arr(7)));
						writeline(Stats, v_OLINE_access);

						write(v_OLINE_stats,
							integer'image(SCAAT_addr_out_c)&' '&
							integer'image(R_active)&' '&
							integer'image(found_in_SCAAT_count_reg));
						writeline(Stats, v_OLINE_stats);

						finished_while <= true;
					end if;

					wait until rising_edge(clk);
				end if;
			end loop;
			if (finished_while) then



			end if;

			for i in 0 to 1 loop nop; end loop;
			file_close(file_VECTORS);
			file_close(access_Histo_RESULTS);
			file_close(miss_Histo_RESULTS);
			file_close(SVA_attk_Histo_RESULTS);
			file_close(IRQ_attk_Histo_RESULTS);
			file_close(CLD_attk_Histo_RESULTS);
			file_close(Stats);
			--file_close(Bench_0);
			file_close(CLD_attk_hist);

			file_close(IRQ_attk_hist);


			file_close(MKPI_0); file_close(MKPI_1); file_close(MKPI_2); file_close(MKPI_3);
			file_close(MKPI_4); file_close(MKPI_5); file_close(MKPI_6); file_close(MKPI_7);
			--file_close(attk_0); file_close(attk_1); file_close(attk_2); file_close(attk_3); file_close(attk_4); file_close(attk_5); file_close(attk_6); file_close(attk_7);
			--end loop sim_loop;
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI___________";
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";

			-- SPEC200
			--file_open(file_VECTORS, full_trace_file&"ASTAR_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_ASTAR_____";
			--file_open(file_VECTORS, full_trace_file&"BZIP_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_BZIP______";
			--file_open(file_VECTORS, full_trace_file&"GCC_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_GCC_______";
			--file_open(file_VECTORS, full_trace_file&"H264Ref_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_H264Ref___";
			--file_open(file_VECTORS, full_trace_file&"LIBQUANTUM_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_LIBQUANTUM";
			--file_open(file_VECTORS, full_trace_file&"SJENG_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_SJENG_____";
			--file_open(file_VECTORS, full_trace_file&"HMMER_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_HMMER_____";
			--file_open(file_VECTORS, full_trace_file&"MCF_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_MCF_______";
			--file_open(file_VECTORS, full_trace_file&"SPECRAND_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_SPECRAND__";
			--file_open(file_VECTORS, full_trace_file&"LBM_BOTH_SPEC2006_4KB.trace", read_mode); MPKI_str := "SPEC_MKPI_LBM_______";

			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
			--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
			--file_open(file_VECTORS, full_trace_file&"CHOLESKY_BOTH_SPLASH3_4KB.trace", read_mode); MPKI_str := "SPLASH_MKPI_CHOLESKY";

		--###############################################
		--###############################################
		--###############################################
		--end loop ctx_run;
		end loop safe_proc;
		--nop;
		finished <= true;
		simDeactivateProcess(simProcessID);
		wait;
	end process CPU_RequestGen;

	attk_active <= '1' when (safety_tb='1' and process_ID_tb = safe_process_ID_tb) else '0';

	--attk_active <= '1' when (safety_tb='1') else '0';

	diff_index <= false when prev_hex_addr_reg = cpu_addr
	else true;

	diff_index2 <= false when prev_hex_addr_reg2 = prev_hex_addr_reg
	else true;

	diff_index3 <= false when prev_hex_addr_reg3 = prev_hex_addr_reg2
	else true;

	en_SVA <= '1'; --when diff_index or diff_index2 or diff_index3 else '0';

	en_CLD <= '1' when diff_index else '0';

	cld_attl : process (clk,rst,attk_active, ACCESScounter)
		variable SCAAT_set_CLD : unsigned(SET_BITS-1 downto 0);
		variable hist_int_CLD  : integer;
	begin
		if (ACCESScounter = 999) then
			CLD_attk_counter <= 0;
		elsif (falling_edge(clk) and attk_active= '1') then
			CLD_attk_counter <= CLD_attk_counter+1;
		end if;

		SCAAT_set_CLD := SCAAT_addr(high_bound_set downto low_bound_set);
		hist_int_CLD  := to_integer(SCAAT_set_CLD);
		if (rst = '1') then
			CLD_attk_arr <= (others => 0);
		elsif (falling_edge(clk) and attk_active = '1') then
			CLD_attk_arr(hist_int_CLD) <= CLD_attk_arr(hist_int_CLD)+1;
		end if;

	end process cld_attl;


	SVA_attl : process (clk,attk, ACCESScounter)
	begin
		if (ACCESScounter = 999) then
			attk_counter <= 0;
		elsif (falling_edge(clk) and attk='1') then
			attk_counter <= attk_counter+1;
		end if;

	end process SVA_attl;

	IRQ_attl : process (clk,IRQ, ACCESScounter)
		variable SCAAT_set_IRQ : unsigned(SET_BITS-1 downto 0);
		variable hist_int_IRQ  : integer;
	begin
		if (ACCESScounter = 999) then
			IRQ_attk_counter <= 0;
		elsif (falling_edge(clk) and IRQ= '1') then
			IRQ_attk_counter <= IRQ_attk_counter+1;
		end if;
		SCAAT_set_IRQ := SCAAT_addr(high_bound_set downto low_bound_set);
		hist_int_IRQ  := to_integer(SCAAT_set_IRQ);
		if (rst = '1') then
			IRQ_attk_arr <= (others => 0);
		elsif (falling_edge(clk) and IRQ = '1') then
			IRQ_attk_arr(hist_int_IRQ) <= IRQ_attk_arr(hist_int_IRQ)+1;
		end if;
	end process IRQ_attl;

	miss_process : process (clk, rst)
		variable SCAAT_set_miss : unsigned(SET_BITS-1 downto 0);
		variable hist_int_miss  : integer;
	begin
		SCAAT_set_miss := SCAAT_addr(high_bound_set downto low_bound_set);
		hist_int_miss  := to_integer(SCAAT_set_miss);

		if (access_arr(core_bench_num) mod 1001 = 0) then
			MKPI_arr(core_bench_num) <= 0;
		end if;


		if (rst = '1') then
			miss_count <= 0;
			miss_arr   <= (others => 0);
			MKPI_arr   <= (others => 0);
			Histo_miss <= (others => (others => 0));
		elsif falling_edge(clk) and cache_Miss = '1' and diff_index then
			miss_count                               <= miss_count+1;
			MKPI_arr(core_bench_num)                 <= MKPI_arr(core_bench_num)+1;
			Histo_miss(hist_int_miss,core_bench_num) <= Histo_miss(hist_int_miss,core_bench_num) + 1;
			miss_arr(core_bench_num)                 <= miss_arr(core_bench_num)+1;
		end if;
	end process miss_process;

	address_register : process (clk, rst)
	begin

		if rst = '1' then
			prev_hex_addr_reg <= (others => '0');
		elsif rising_edge(clk) then
			prev_hex_addr_reg <= cpu_addr;
		end if;
		if rst = '1' then
			prev_hex_addr_reg2 <= (others => '0');
		elsif rising_edge(clk) then
			prev_hex_addr_reg2 <= prev_hex_addr_reg;
		end if;

		if rst = '1' then
			prev_hex_addr_reg3 <= (others => '0');
		elsif rising_edge(clk) then
			prev_hex_addr_reg3 <= prev_hex_addr_reg2;
		end if;

		if rst = '1' then
			found_in_SCAAT_count_reg <= 0;
		elsif falling_edge(clk) and (diff_index and f_in_SCAAT='1') then
			found_in_SCAAT_count_reg <= found_in_SCAAT_count_reg + 1;
		end if;

	end process address_register;

	miss_histo_proc : process (clk,rst)
		variable SCAAT_set_miss : unsigned(SET_BITS-1 downto 0);
		variable hist_int_miss  : integer;

	begin


	end process miss_histo_proc;

end architecture sim;


--case (safe_process_ID_tb) is
--							when "111" =>
--								-- l 117440513
--								-- h 134217713
--								PREG_PROTECT_L <= 117440513;
--								PREG_PROTECT_H <= 134217713;
--							when "110" =>
--								-- l 100663297
--								-- h 117440497
--								PREG_PROTECT_L <= 100663297;
--								PREG_PROTECT_H <= 117440497;
--							when "101" =>
--								-- l 83886081
--								-- h 100663281
--								PREG_PROTECT_L <= 83886081;
--								PREG_PROTECT_H <= 100663281;
--							when "100" =>
--								-- l 67108865
--								-- h 83886065
--								PREG_PROTECT_L <= 67108865;
--								PREG_PROTECT_H <= 83886065;
--							when "011" =>
--								-- l 50331649
--								-- h 67108849
--								PREG_PROTECT_L <= 50331649;
--								PREG_PROTECT_H <= 67108849;
--							when "010" =>
--								-- l 33554433
--								-- h 50331633
--								PREG_PROTECT_L <= 33554433;
--								PREG_PROTECT_H <= 50331633;
--							when "001" =>
--								-- l 16777217
--								-- h 33554430
--								PREG_PROTECT_L <= 16777217;
--								PREG_PROTECT_H <= 33554431;
--							when others =>
--								-- l 1
--								-- h 16777214
--								PREG_PROTECT_L <= 1;
--								PREG_PROTECT_H <= 16777214;
--						end case;
