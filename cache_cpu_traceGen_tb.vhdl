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


entity cache_cpu_traceGen_tb is
end entity cache_cpu_traceGen_tb;

architecture sim of cache_cpu_traceGen_tb is
	constant CLOCK_FREQ : FREQ := 1000 MHz;
	constant CPU_ADDR_LEN        : positive := 32;
	constant BRAM_ADDR_LEN        : positive := 1;

	signal clk : std_logic := '1';
	signal rst : std_logic;
	signal cpu_req   : std_logic;
	signal cpu_write : std_logic;
	signal cpu_addr  : unsigned(CPU_ADDR_LEN-1 downto 0);
	signal cache_req   : std_logic;
	--signal mem1_rstb  : std_logic;
	signal env_enable  : std_logic;
	signal addr_bram: unsigned(BRAM_ADDR_LEN-1 downto 0);

	signal trace : unsigned(35 downto 0);
begin

	simInitialize;
	simGenerateClock(clk, CLOCK_FREQ);
	UUT_with: entity work.cache_cpu_trace_Genrator
		generic map (
			CPU_ADDR_LEN      => CPU_ADDR_LEN,
			BRAM_ADDR_LEN      => BRAM_ADDR_LEN
			)
		port map (
			clk       	=> clk,
			rst       	=> rst,
			trace 		=> trace,
			cpu_req   	=> cache_req,
			cpu_write 	=> cpu_write,
			cpu_addr  	=> cpu_addr,
			--mem_rdy   	=> mem1_rdy,
			--mem_rstb  	=> mem1_rstb,
			env_en  	=> env_enable,
			BRAM_addr 	=> addr_bram
	);
  CPU_RequestGen: process
  constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU RequestGen");
  begin
	
	wait until rising_edge(clk);
	rst <='1';
	wait until rising_edge(clk);
	rst <='0';
	wait until rising_edge(clk);
	if (addr_bram = "0") then
		trace <= "110100011111111111111111111101010000";
	end if;
	if (addr_bram = "1") then
		trace <= "011100011111111111111111111101011000";
	end if;
	simDeactivateProcess(simProcessID);
	simFinalize;
    wait;
  end process CPU_RequestGen;

end architecture sim;
