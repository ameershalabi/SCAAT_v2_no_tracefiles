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
	constant CACHE_LINES        : positive := 1024;   --Direct mapped 32bit bench
	                                                  --constant ASSOCIATIVITY      : positive := 1; --Direct mapped 32bit bench
	                                                  --constant CACHE_LINES        : positive := 512; --k-way associative 32bit bench
	constant ASSOCIATIVITY : positive := 16;          --k-way associative 32bit bench
	constant CACHE_SETS    : positive := CACHE_LINES; --/ASSOCIATIVITY;
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
	signal finished              : boolean := false;
	signal finished_while        : boolean := false;
	signal cache_Hit, cache_Miss : std_logic;
	signal bench_miss_enable     : std_logic;
	signal process_type          : character;
	signal target_bench          : character;
	signal SCAAT_v               : character;
	------ FILE READER SIGNALS -- AMSHAL
	file file_VECTORS       : text;
	file Miss_Histo_RESULTS : text;
	file MKPI_0             : text;
	file MKPI_1             : text;
	file MKPI_2             : text;
	file MKPI_3             : text;
	file MKPI_4             : text;
	file MKPI_5             : text;
	file MKPI_6             : text;
	file MKPI_7             : text;
	file attk_0             : text;
	file attk_1             : text;
	file attk_2             : text;
	file attk_3             : text;
	file attk_4             : text;
	file attk_5             : text;
	file attk_6             : text;
	file attk_7             : text;

	signal ctx_string : string(1 to 34) := "__________________________________";

	--file file_RESULTS : text;
	file attk_RESULTS : text;
	signal ADDR_HEX   : string(1 to 10);
	signal op         : character;
	--signal input_addr_vector : std_logic_vector(31 downto 0);
	signal addr_int : integer;
	--AMSHAL 
	--signal ralloc_RandX  : unsigned(CPU_ADDR_BITS-1 downto 0); --address from checker to reallocator
	--signal addr_star  : unsigned(CPU_ADDR_BITS-1 downto 0); --address output from reallocator
	type CORE_ARRAY is array (7 downto 0) of integer;
	signal MKPI_arr   : CORE_ARRAY;
	signal miss_arr   : CORE_ARRAY;
	signal access_arr : CORE_ARRAY;
	signal attk_arr   : CORE_ARRAY;

	type safe_proc_arr is array (7 downto 0) of std_logic_vector(2 downto 0);
	signal safe_procs : safe_proc_arr := ("000", "001", "010", "011", "100", "101", "110", "111");

	signal attk                   : std_logic;        -- attack signal from checker
	signal attk_deactive          : std_logic := '0'; -- attack signal from checker
	signal attk_active            : std_logic := '0'; -- attack signal from checker
	signal attk_CLD               : std_logic := '0'; -- attack signal from checker
	signal caseNum                : std_logic_vector(4 downto 0);
	signal SCAAT_env_trace_vector : std_logic_vector(33 downto 0) := "0000000000000000000000000000000000";
	signal diff_index             : boolean;
	signal diff_index2            : boolean;
	signal diff_index3            : boolean;
	signal en_SVA                 : std_logic;
	signal prev_hex_addr_reg      : unsigned(CPU_ADDR_BITS-1 downto 0);
	signal prev_hex_addr_reg2     : unsigned(CPU_ADDR_BITS-1 downto 0);
	signal prev_hex_addr_reg3     : unsigned(CPU_ADDR_BITS-1 downto 0);



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
	signal SCAAT_addr_out_c          : integer;
	signal R_active                  : integer;
	signal f_in_SCAAT                : std_logic;
	signal found_in_SCAAT_count_reg  : integer := 0;

	signal process_ID_tb      : std_logic_vector(process_ID_len - 1 downto 0);
	signal safe_process_ID_tb : std_logic_vector(process_ID_len - 1 downto 0);
	signal safety_tb          : std_logic;




	signal core_bench : character;


	constant PREG_PROTECT_L : integer  := 44739242;
	constant PREG_PROTECT_H : positive := 89478485;

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
			--SCAAT AMSHAL
			attk_in => attk_deactive --attk_active --attk --attk_deactive
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
			cache_newAddr  => en_SVA,
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

		variable attkTrace : line;
		variable v_OP      : character;
		variable v_SPACE1  : character;

		variable v_ADDR_HEX      : string(1 to 10);
		variable v_SPACE2        : character;
		variable v_CORE          : character;
		variable v_CORE_B        : character;
		variable v_LAST          : integer;
		variable v_Vector        : std_logic_vector(3 downto 0);
		variable v_addr_Vector   : std_logic_vector(31 downto 0);
		variable factor          : unsigned(31 downto 0);
		variable Data_trace_file : string(1 to 58) := "/home/amshal/pc/Projects/TRACEFILES/DataCacheAccessTraces/";
		variable full_trace_file : string(1 to 53) := "/home/amshal/pc/Projects/TRACEFILES/DATA_INST_traces/";
		variable ctx_trace_file  : string(1 to 47) := "/home/amshal/pc/Projects/TRACEFILES/ctx_traces/";

		variable MPKI_str     : string(1 to 20) := "____________________";
		variable ctx_MPKI_str : string(1 to 10) := "__________";
		variable trace_file   : string(1 to 11) := "___________";
		variable ctx_folder   : string(1 to 22) := "______________________";
		variable target_SCAAT : string(1 to 2)  := "__";

	begin
		rand_data.InitSeed(rand_data'instance_name);
		rand_addr.InitSeed(rand_addr'instance_name);
		rand_probability.InitSeed(rand_probability'instance_name);


		-- safe process
		target_SCAAT(2) := 'b'; -- SCAAT version

		safe_proc : for safe in 0 to 0 loop

			safe_process_ID_tb <= safe_procs(safe);

			case (safe) is
				when 0 =>
					--target_SCAAT(1) := '0';
					target_SCAAT(1) := 'b';
				--when 1 =>
				--	target_SCAAT(1) := '1';
				--when 2 =>
				--	target_SCAAT(1) := '2';
				--when 3 =>
				--	target_SCAAT(1) := '3';
				--when 4 =>
				--	target_SCAAT(1) := '4';
				--when 5 =>
				--	target_SCAAT(1) := '5';
				--when 6 =>
				--	target_SCAAT(1) := '6';
				--when 7 =>
				--	target_SCAAT(1) := '7';
				when others =>
					null;
			end case;

			ctx_run : for ctx in 1 to 7 loop
				case (ctx) is
					when 1 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_1.trace";
						ctx_MPKI_str := "CTX1_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_1_out/";
						finished_while <= false;
					when 2 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_2.trace";
						ctx_MPKI_str := "CTX2_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_2_out/";
						finished_while <= false;
					when 3 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_3.trace";
						ctx_MPKI_str := "CTX3_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_3_out/";
						finished_while <= false;
					when 4 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_4.trace";
						ctx_MPKI_str := "CTX4_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_4_out/";
						finished_while <= false;
					when 5 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_5.trace";
						ctx_MPKI_str := "CTX5_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_5_out/";
						finished_while <= false;
					when 6 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_6.trace";
						ctx_MPKI_str := "CTX6_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_6_out/";
						finished_while <= false;
					when 7 =>
						cur_ctx      <= ctx;
						trace_file   := "ctx_7.trace";
						ctx_MPKI_str := "CTX7_stat_";
						--ctx_folder     := "./ctx_files
						ctx_folder := "./ctx_stats/ctx_7_out/";
						finished_while <= false;
					when others =>
						null;
				end case;

				ctx_string <= ctx_folder&ctx_MPKI_str&target_SCAAT; -- 22 + 10 + 2 = 

				file_open(file_VECTORS, ctx_trace_file&trace_file, read_mode);

				--file_open(file_VECTORS, ctx_trace_file&"ctx_1.trace", read_mode); ctx_MPKI_str := "CTX1_stat_"; ctx_folder := "./ctx_1_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_2.trace", read_mode); ctx_MPKI_str := "CTX2_stat_"; ctx_folder := "./ctx_2_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_3.trace", read_mode); ctx_MPKI_str := "CTX3_stat_"; ctx_folder := "./ctx_3_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_4.trace", read_mode); ctx_MPKI_str := "CTX4_stat_"; ctx_folder := "./ctx_4_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_5.trace", read_mode); ctx_MPKI_str := "CTX5_stat_"; ctx_folder := "./ctx_5_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_6.trace", read_mode); ctx_MPKI_str := "CTX6_stat_"; ctx_folder := "./ctx_6_out/";
				--file_open(file_VECTORS, ctx_trace_file&"ctx_7.trace", read_mode); ctx_MPKI_str := "CTX7_stat_"; ctx_folder := "./ctx_7_out/";

				--file_open(Miss_Histo_RESULTS, ctx_MPKI_str&"_"&target_bench&"_"&SCAAT_v&".txt", write_mode);
				file_open(MKPI_0, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_0.txt", write_mode);
				file_open(MKPI_1, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_1.txt", write_mode);
				file_open(MKPI_2, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_2.txt", write_mode);
				file_open(MKPI_3, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_3.txt", write_mode);
				file_open(MKPI_4, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_4.txt", write_mode);
				file_open(MKPI_5, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_5.txt", write_mode);
				file_open(MKPI_6, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_6.txt", write_mode);
				file_open(MKPI_7, ctx_folder&ctx_MPKI_str&target_SCAAT&"_MKPI_7.txt", write_mode);


				file_open(attk_0, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_0.txt", write_mode);
				file_open(attk_1, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_1.txt", write_mode);
				file_open(attk_2, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_2.txt", write_mode);
				file_open(attk_3, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_3.txt", write_mode);
				file_open(attk_4, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_4.txt", write_mode);
				file_open(attk_5, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_5.txt", write_mode);
				file_open(attk_6, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_6.txt", write_mode);
				file_open(attk_7, ctx_folder&ctx_MPKI_str&target_SCAAT&"_attk_7.txt", write_mode);

				file_open(Miss_Histo_RESULTS, ctx_folder&ctx_MPKI_str&target_SCAAT&".txt", write_mode);

				rst <= '1';
				--ACCESScounter      <= (others => '0');
				--TOTALACCESScounter <= (others => '0');
				wait until rising_edge(clk);

				rst <= '0';
				--for i in 0 to 1 loop nop; end loop;

				ACCESScounter      <= (others => '0');
				TOTALACCESScounter <= (others => '0');
				access_arr         <= (others => 0);

				while (finished_while = false) loop
					v_addr_Vector := "00000000000000000000000000000000";
					ADDR_HEX      <= "0xffffffff";
					v_ADDR_HEX    := "0xffffffff";
					op            <= '0';
					core_bench    <= '0';


					readline(file_VECTORS, v_ILINE);
					read(v_ILINE, v_OP);
					op <= v_OP;
					read(v_ILINE, v_SPACE1);
					read(v_ILINE, v_ADDR_HEX);
					read(v_ILINE, v_SPACE2);
					read(v_ILINE, v_CORE);
					core_bench    <= v_CORE;
					v_ADDR_HEX(3) := v_CORE;
					ADDR_HEX      <= v_ADDR_HEX;
					for ii in 3 to 10 loop
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
							when 3      => v_addr_Vector(31 downto 28) := v_Vector;
							when 4      => v_addr_Vector(27 downto 24) := v_Vector;
							when 5      => v_addr_Vector(23 downto 20) := v_Vector;
							when 6      => v_addr_Vector(19 downto 16) := v_Vector;
							when 7      => v_addr_Vector(15 downto 12) := v_Vector;
							when 8      => v_addr_Vector(11 downto 8)  := v_Vector;
							when 9      => v_addr_Vector(7 downto 4)   := v_Vector;
							when 10     => v_addr_Vector(3 downto 0)   := v_Vector;
							when others => v_addr_Vector(31 downto 27) := v_Vector;
						end case;
					end loop;
					bench_miss_enable <= '1' when target_bench = core_bench else '0';

					if op = 'l' or op = 'w' or op = 'r' then
						ACCESScounter      <= ACCESScounter + 1;
						TOTALACCESScounter <= TOTALACCESScounter + 1;
						case (core_bench) is
							when '1' =>
								access_arr(1) <= access_arr(1)+1;
								process_ID_tb <= "001";
							when '2' =>
								access_arr(2) <= access_arr(2)+1;
								process_ID_tb <= "010";
							when '3' =>
								access_arr(3) <= access_arr(3)+1;
								process_ID_tb <= "011";
							when '4' =>
								access_arr(4) <= access_arr(4)+1;
								process_ID_tb <= "100";
							when '5' =>
								access_arr(5) <= access_arr(5)+1;
								process_ID_tb <= "101";
							when '6' =>
								access_arr(6) <= access_arr(6)+1;
								process_ID_tb <= "110";
							when '7' =>
								access_arr(7) <= access_arr(7)+1;
								process_ID_tb <= "111";
							when others =>
								access_arr(0) <= access_arr(0)+1;
								process_ID_tb <= "000";
						end case;
						read(unsigned(v_addr_Vector(CPU_ADDR_BITS-1 downto 0)));
					elsif op = 's' then
						ACCESScounter      <= ACCESScounter + 1;
						TOTALACCESScounter <= TOTALACCESScounter + 1;
						write(unsigned(v_addr_Vector(CPU_ADDR_BITS-1 downto 0)));
						case (core_bench) is
							when '1' =>
								access_arr(1) <= access_arr(1)+1;
								process_ID_tb <= "001";
							when '2' =>
								access_arr(2) <= access_arr(2)+1;
								process_ID_tb <= "010";
							when '3' =>
								access_arr(3) <= access_arr(3)+1;
								process_ID_tb <= "011";
							when '4' =>
								access_arr(4) <= access_arr(4)+1;
								process_ID_tb <= "100";
							when '5' =>
								access_arr(5) <= access_arr(5)+1;
								process_ID_tb <= "101";
							when '6' =>
								access_arr(6) <= access_arr(6)+1;
								process_ID_tb <= "110";
							when '7' =>
								access_arr(7) <= access_arr(7)+1;
								process_ID_tb <= "111";
							when others =>
								access_arr(0) <= access_arr(0)+1;
								process_ID_tb <= "000";
						end case;
					end if;

					if (ACCESScounter = 1000) then
						ACCESScounter <= (others => '0');
					--write(v_OLINE, integer'image(MPKI_miss)&' '&integer'image(MKPI_arr(0))&' '&integer'image(MKPI_arr(1))&' '&integer'image(MKPI_arr(2))&' '&integer'image(MKPI_arr(3))&' '&integer'image(MKPI_arr(4))&' '&integer'image(MKPI_arr(5))&' '&integer'image(MKPI_arr(6))&' '&integer'image(MKPI_arr(7)));
					--writeline(Miss_Histo_RESULTS, v_OLINE);
					end if;

					if ((to_integer(unsigned(TOTALACCESScounter) mod 500000) = 0) and (to_integer(unsigned(TOTALACCESScounter))/= 0)) then
						finished_while <= true;
					end if;


					wait until rising_edge(clk);
				end loop;
				if (finished_while) then
					--write(v_OLINE_miss, integer'image(miss_count));
					write(v_OLINE_miss, integer'image(miss_count)&' '&integer'image(miss_arr(0))&' '&integer'image(miss_arr(1))&' '&integer'image(miss_arr(2))&' '&integer'image(miss_arr(3))&' '&integer'image(miss_arr(4))&' '&integer'image(miss_arr(5))&' '&integer'image(miss_arr(6))&' '&integer'image(miss_arr(7)));
					writeline(Miss_Histo_RESULTS, v_OLINE_miss);
					write(v_OLINE_access, "500000 "&integer'image(access_arr(0))&' '&integer'image(access_arr(1))&' '&integer'image(access_arr(2))&' '&integer'image(access_arr(3))&' '&integer'image(access_arr(4))&' '&integer'image(access_arr(5))&' '&integer'image(access_arr(6))&' '&integer'image(access_arr(7)));
					writeline(Miss_Histo_RESULTS, v_OLINE_access);
					write(v_OLINE_stats, integer'image(SCAAT_addr_out_c)&' '&integer'image(R_active)&' '&integer'image(found_in_SCAAT_count_reg));
					writeline(Miss_Histo_RESULTS, v_OLINE_stats);

				end if;

				for i in 0 to 1 loop nop; end loop;
				file_close(file_VECTORS);
				file_close(Miss_Histo_RESULTS);
				file_close(MKPI_0); file_close(MKPI_1); file_close(MKPI_2); file_close(MKPI_3); file_close(MKPI_4); file_close(MKPI_5); file_close(MKPI_6); file_close(MKPI_7);
				file_close(attk_0); file_close(attk_1); file_close(attk_2); file_close(attk_3); file_close(attk_4); file_close(attk_5); file_close(attk_6); file_close(attk_7);
				--end loop sim_loop;
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI___________";
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";

				-- SPEC200
				--file_open(file_VECTORS, full_trace_file&"ASTAR_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_ASTAR_____";
				--file_open(file_VECTORS, full_trace_file&"BZIP_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_BZIP______";
				--file_open(file_VECTORS, full_trace_file&"GCC_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_GCC_______";
				--file_open(file_VECTORS, full_trace_file&"H264Ref_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_H264Ref___";
				--file_open(file_VECTORS, full_trace_file&"LIBQUANTUM_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_LIBQUANTUM";
				--file_open(file_VECTORS, full_trace_file&"SJENG_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_SJENG_____";
				--file_open(file_VECTORS, full_trace_file&"HMMER_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_HMMER_____";
				--file_open(file_VECTORS, full_trace_file&"MCF_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_MCF_______";
				--file_open(file_VECTORS, full_trace_file&"SPECRAND_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_SPECRAND__";
				--file_open(file_VECTORS, full_trace_file&"LBM_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_LBM_______";

				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
				--file_open(file_VECTORS, full_trace_file&"_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_________";
				--file_open(file_VECTORS, full_trace_file&"CHOLESKY_BOTH_SPLASH3.trace", read_mode); MPKI_str := "SPLASH_MKPI_CHOLESKY";

			--###############################################
			--###############################################
			--###############################################
			end loop ctx_run;
		end loop safe_proc;
		--nop;
		finished <= true;
		simDeactivateProcess(simProcessID);
		wait;
	end process CPU_RequestGen;

	attk_active <= '1' when (safety_tb='1' and process_ID_tb = safe_process_ID_tb) else '0';

	diff_index <= false when prev_hex_addr_reg = cpu_addr
	else true;

	diff_index2 <= false when prev_hex_addr_reg2 = prev_hex_addr_reg
	else true;

	diff_index3 <= false when prev_hex_addr_reg3 = prev_hex_addr_reg2
	else true;

	en_SVA <= '1' when diff_index else '0';

	cld_attl : process (rst,clk,safety_tb)
	begin
		if rst = '1' then
			attk_CLD <= '0';
		elsif clk'event then
			attk_CLD <= safety_tb;
		end if;

	end process cld_attl;


	address_register : process (clk, rst)

		variable MKPI_0_line : line;
		variable MKPI_1_line : line;
		variable MKPI_2_line : line;
		variable MKPI_3_line : line;
		variable MKPI_4_line : line;
		variable MKPI_5_line : line;
		variable MKPI_6_line : line;
		variable MKPI_7_line : line;

		variable attk_0_line : line;
		variable attk_1_line : line;
		variable attk_2_line : line;
		variable attk_3_line : line;
		variable attk_4_line : line;
		variable attk_5_line : line;
		variable attk_6_line : line;
		variable attk_7_line : line;

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


		if rst = '1' then
			miss_count <= 0;
			miss_arr   <= (others => 0);
		elsif falling_edge(clk) and cache_Miss = '1' then
			miss_count <= miss_count + 1;
			case (core_bench) is
				when '1' =>
					miss_arr(1) <= miss_arr(1)+1;
				when '2' =>
					miss_arr(2) <= miss_arr(2)+1;
				when '3' =>
					miss_arr(3) <= miss_arr(3)+1;
				when '4' =>
					miss_arr(4) <= miss_arr(4)+1;
				when '5' =>
					miss_arr(5) <= miss_arr(5)+1;
				when '6' =>
					miss_arr(6) <= miss_arr(6)+1;
				when '7' =>
					miss_arr(7) <= miss_arr(7)+1;
				when others =>
					miss_arr(0) <= miss_arr(0)+1;
			end case;
		end if;

		if rst = '1' then
			MKPI_arr <= (others => 0);

			attk_arr <= (others => 0);
		elsif (ACCESScounter = 0) then
			MPKI_miss <= 0;
		elsif falling_edge(clk) then
			MPKI_miss <= MPKI_miss + 1;
			case (core_bench) is
				when '1' =>
					if (cache_Miss = '1') then MKPI_arr(1) <= MKPI_arr(1)+1; end if;
					if (attk = '1') then attk_arr(1) <= attk_arr(1)+1; end if;
					--access_arr(1) <= access_arr(1)+1;
					if (access_arr(1) mod 1000 = 0) then
						write(MKPI_1_line, integer'image(MKPI_arr(1)));
						writeline(MKPI_1, MKPI_1_line);

						write(attk_1_line, ' '&integer'image(attk_arr(1)));
						writeline(attk_1, attk_1_line);

						MKPI_arr(1) <= 0;
						attk_arr(1) <= 0;
					end if;
				when '2' =>
					if (cache_Miss = '1') then MKPI_arr(2) <= MKPI_arr(2)+1; end if;
					if (attk = '1') then attk_arr(2) <= attk_arr(2)+1; end if;
					--access_arr(2) <= access_arr(2)+1;
					if (access_arr(2) mod 1000 = 0) then
						write(MKPI_2_line, integer'image(MKPI_arr(2)));
						writeline(MKPI_2, MKPI_2_line);

						write(attk_2_line, ' '&integer'image(attk_arr(2)));
						writeline(attk_2, attk_2_line);

						MKPI_arr(2) <= 0;
						attk_arr(2) <= 0;

					end if;
				when '3' =>
					if (cache_Miss = '1') then MKPI_arr(3) <= MKPI_arr(3)+1; end if;
					if (attk = '1') then attk_arr(3) <= attk_arr(3)+1; end if;
					--access_arr(3) <= access_arr(3)+1;
					if (access_arr(3) mod 1000 = 0) then
						write(MKPI_3_line, integer'image(MKPI_arr(3)));
						writeline(MKPI_3, MKPI_3_line);

						write(attk_3_line, ' '&integer'image(attk_arr(3)));
						writeline(attk_3, attk_3_line);

						MKPI_arr(3) <= 0;
						attk_arr(3) <= 0;

					end if;
				when '4' =>
					if (cache_Miss = '1') then MKPI_arr(4) <= MKPI_arr(4)+1; end if;
					if (attk = '1') then attk_arr(4) <= attk_arr(4)+1; end if;
					--access_arr(4) <= access_arr(4)+1;
					if (access_arr(4) mod 1000 = 0) then
						write(MKPI_4_line, integer'image(MKPI_arr(4)));
						writeline(MKPI_4, MKPI_4_line);

						write(attk_4_line, ' '&integer'image(attk_arr(4)));
						writeline(attk_4, attk_4_line);

						MKPI_arr(4) <= 0;
						attk_arr(4) <= 0;

					end if;
				when '5' =>
					if (cache_Miss = '1') then MKPI_arr(5) <= MKPI_arr(5)+1; end if;
					if (attk = '1') then attk_arr(5) <= attk_arr(5)+1; end if;

					--access_arr(5) <= access_arr(5)+1;
					if (access_arr(5) mod 1000 = 0) then
						write(MKPI_5_line, integer'image(MKPI_arr(5)));
						writeline(MKPI_5, MKPI_5_line);

						write(attk_5_line, ' '&integer'image(attk_arr(5)));
						writeline(attk_5, attk_5_line);

						MKPI_arr(5) <= 0;
						attk_arr(5) <= 0;

					end if;
				when '6' =>
					if (cache_Miss = '1') then MKPI_arr(6) <= MKPI_arr(6)+1; end if;
					if (attk = '1') then attk_arr(6) <= attk_arr(6)+1; end if;

					--	access_arr(6) <= access_arr(6)+1;
					if (access_arr(6) mod 1000 = 0) then
						write(MKPI_6_line, integer'image(MKPI_arr(6)));
						writeline(MKPI_6, MKPI_6_line);

						write(attk_6_line, ' '&integer'image(attk_arr(6)));
						writeline(attk_6, attk_6_line);

						MKPI_arr(6) <= 0;
						attk_arr(6) <= 0;

					end if;
				when '7' =>
					if (cache_Miss = '1') then MKPI_arr(7) <= MKPI_arr(7)+1; end if;
					if (attk = '1') then attk_arr(7) <= attk_arr(7)+1; end if;

					--	access_arr(7) <= access_arr(7)+1;
					if (access_arr(7) mod 1000 = 0) then
						write(MKPI_7_line, integer'image(MKPI_arr(7)));
						writeline(MKPI_7, MKPI_7_line);

						write(attk_7_line, ' '&integer'image(attk_arr(7)));
						writeline(attk_7, attk_7_line);

						MKPI_arr(7) <= 0;
						attk_arr(7) <= 0;

					end if;
				when others =>
					if (cache_Miss = '1') then MKPI_arr(0) <= MKPI_arr(0)+1; end if;
					if (attk = '1') then attk_arr(0) <= attk_arr(0)+1; end if;

					--	access_arr(0) <= access_arr(0)+1;
					if (access_arr(0) mod 1000 = 0) then
						write(MKPI_0_line, integer'image(MKPI_arr(0)));
						writeline(MKPI_0, MKPI_0_line);

						write(attk_0_line, ' '&integer'image(attk_arr(0)));
						writeline(attk_0, attk_0_line);

						MKPI_arr(0) <= 0;
						attk_arr(0) <= 0;

					end if;
			end case;
		end if;

	end process address_register;
	-- The Checker of the CPU
	--CPU_Checker: process
	--	constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU Checker");
	--	variable saved_rdata  : std_logic_vector(CPU_DATA_BITS-1 downto 0);
	--begin
	--	-- wait until reset completes
	--	wait until rising_edge(clk) and rst = '0';

	--	-- wait until all requests have been applied
	--	while not finished loop
	--		wait until rising_edge(clk);
	--		simAssertion(not is_x(cache_rstb) and not is_x(mem2_rstb), "Meta-value on rstb.");
	--		if mem2_rstb = '1' then
	--			saved_rdata := mem2_rdata;
	--			-- If cache does not return data in same clock cycle (i.e. cache miss),
	--			-- then wait for cache_rstb.
	--			while cache_rstb = '0' loop
	--				wait until rising_edge(clk);
	--				-- No new data from 2nd memory must arrive here.
	--				simAssertion(not is_x(cache_rstb) and mem2_rstb = '0',
	--										 "Meta-value on rstb or invalid reply from 2nd memory.");
	--			end loop;

	--			simAssertion(cache_rdata = saved_rdata, "Read data differs.");
	--		end if;
	--	end loop;

	--	simDeactivateProcess(simProcessID);
	--	simFinalize;
	--	wait;
	--end process CPU_Checker;



end architecture sim;
--file_open(file_VECTORS, Data_trace_file&"GCC_DATA_SPEC2006.trace", read_mode); MPKI_str := "MKPI_GCC_0";
--file_open(file_VECTORS, full_trace_file&"GCC_BOTH_SPEC2006.trace", read_mode); MPKI_str := "MKPI_GCC_2";
--file_open(file_VECTORS, Data_trace_file&"ASTAR_DATA_SPEC2006.trace", read_mode); MPKI_str := "MKPI_ASTAR";
--file_open(file_VECTORS, Data_trace_file&"LIBQUANTUM_DATA_SPEC2006.trace",  read_mode); MPKI_str := "MKPI_LIBQU";
--file_open(file_VECTORS, Data_trace_file&"SJENG_DATA_SPEC2006.trace", read_mode); MPKI_str := "MKPI_SJENG";
--file_open(file_VECTORS, Data_trace_file&"H264Ref_DATA_SPEC2006.trace",  read_mode); MPKI_str := "MKPI_H264R";
--file_open(file_VECTORS, Data_trace_file&"BZIP_DATA_SPEC2006.trace",  read_mode); MPKI_str := "MKPI_BZIP0";


-- PARSEC
--file_open(file_VECTORS, Data_trace_file&"VIPS_DATA_PARSEC.trace",  read_mode); MPKI_str := "MKPI_VIPS0";
--file_open(file_VECTORS, Data_trace_file&"STREAMCLUSTER_DATA_PARSEC.trace",  read_mode); MPKI_str := "MKPI_STREA";
--file_open(file_VECTORS, Data_trace_file&"FACESIM_DATA_PARSEC.trace",  read_mode); MPKI_str := "MKPI_FACES";
--file_open(file_VECTORS, Data_trace_file&"BLACKSCHOLES_DATA_PARSEC.trace",  read_mode); MPKI_str := "MKPI_BLACK";

-- SPLASH
--file_open(file_VECTORS, Data_trace_file&"FFT_DATA_SPLASH3.trace",  read_mode); MPKI_str := "MKPI_FFT_0";
--file_open(file_VECTORS, Data_trace_file&"RADIX_DATA_SPLASH3.trace",  read_mode); MPKI_str := "MKPI_RADIX";
--file_open(file_VECTORS, Data_trace_file&"VOLREND_DATA_SPLASH3.trace",  read_mode); MPKI_str := "MKPI_VOLRE";
--file_open(file_VECTORS, Data_trace_file&"FMM_DATA_SPLASH3.trace",  read_mode); MPKI_str := "MKPI_FMM_0";

--case (iii) is
--				when 0      => file_open(file_VECTORS, full_trace_file&"ASTAR_BOTH_SPEC2006.trace", read_mode); MPKI_str      := "SPEC_MKPI_ASTAR_____";
--				when 1      => file_open(file_VECTORS, full_trace_file&"BZIP_BOTH_SPEC2006.trace", read_mode); MPKI_str       := "SPEC_MKPI_BZIP______";
--				when 2      => file_open(file_VECTORS, full_trace_file&"GCC_BOTH_SPEC2006.trace", read_mode); MPKI_str        := "SPEC_MKPI_GCC_______";
--				when 3      => file_open(file_VECTORS, full_trace_file&"H264Ref_BOTH_SPEC2006.trace", read_mode); MPKI_str    := "SPEC_MKPI_H264Ref___";
--				when 4      => file_open(file_VECTORS, full_trace_file&"LIBQUANTUM_BOTH_SPEC2006.trace", read_mode); MPKI_str := "SPEC_MKPI_LIBQUANTUM";
--				when 5      => file_open(file_VECTORS, full_trace_file&"SJENG_BOTH_SPEC2006.trace", read_mode); MPKI_str      := "SPEC_MKPI_SJENG_____";
--				when 6      => file_open(file_VECTORS, full_trace_file&"HMMER_BOTH_SPEC2006.trace", read_mode); MPKI_str      := "SPEC_MKPI_HMMER_____";
--				when 7      => file_open(file_VECTORS, full_trace_file&"MCF_BOTH_SPEC2006.trace", read_mode); MPKI_str        := "SPEC_MKPI_MCF_______";
--				when 8      => file_open(file_VECTORS, full_trace_file&"SPECRAND_BOTH_SPEC2006.trace", read_mode); MPKI_str   := "SPEC_MKPI_SPECRAND__";
--				when 9      => file_open(file_VECTORS, full_trace_file&"LBM_BOTH_SPEC2006.trace", read_mode); MPKI_str        := "SPEC_MKPI_LBM_______";
--				when 10     => file_open(file_VECTORS, full_trace_file&"BARNES_BOTH_SPLASH3.trace", read_mode); MPKI_str      := "SPLASH_MKPI_BARNES__";
--				when 11     => file_open(file_VECTORS, full_trace_file&"FFT_BOTH_SPLASH3.trace", read_mode); MPKI_str         := "SPLASH_MKPI_FFT_____";
--				when 12     => file_open(file_VECTORS, full_trace_file&"FMM_BOTH_SPLASH3.trace", read_mode); MPKI_str         := "SPLASH_MKPI_FMM_____";
--				when 13     => file_open(file_VECTORS, full_trace_file&"RADIX_BOTH_SPLASH3.trace", read_mode); MPKI_str       := "SPLASH_MKPI_RADIX___";
--				when 14     => file_open(file_VECTORS, full_trace_file&"VOLREND_BOTH_SPLASH3.trace", read_mode); MPKI_str     := "SPLASH_MKPI_VOLREND_";
--				when 15     => file_open(file_VECTORS, full_trace_file&"CHOLESKY_BOTH_SPLASH3.trace", read_mode); MPKI_str    := "SPLASH_MKPI_CHOLESKY";
--				when others =>
--					null;
--			end case;
