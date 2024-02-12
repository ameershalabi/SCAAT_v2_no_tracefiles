

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


entity cache_cpu_memModel_tb is
end entity cache_cpu_memModel_tb;

architecture sim of cache_cpu_memModel_tb is
	constant CLOCK_FREQ : FREQ := 1000 MHz;

	constant A_BITS : positive := 5;
	constant D_BITS : positive := 10;
	constant LATENCY : positive := 2;  


	signal mem_req   :  std_logic;
    signal mem_write :  std_logic;
    signal mem_addr  :  unsigned(A_BITS-1 downto 0);
    signal mem_wdata :  std_logic_vector(D_BITS-1 downto 0);
    signal mem_wmask :  std_logic_vector(D_BITS/8-1 downto 0);
    signal mem_rdy   :  std_logic;
    signal mem_rstb  :  std_logic;
    signal mem_rdata :  std_logic_vector(D_BITS-1 downto 0);
	signal clk : std_logic := '1';
	signal rst : std_logic;

begin

	simInitialize;
	simGenerateClock(clk, CLOCK_FREQ);
	UUT_with: entity work.mem_model_fsm
		generic map (
			A_BITS      => A_BITS,
			D_BITS      => D_BITS,
			LATENCY     => LATENCY
			)
		port map (
			clk       	=> clk,
			rst       	=> rst,
    		mem_req => mem_req,
    		mem_write => mem_write,
    		mem_addr => mem_addr,
    		mem_wdata => mem_wdata,
    		mem_wmask => mem_wmask,
    		mem_rdy => mem_rdy,
    		mem_rstb => mem_rstb,
    		mem_rdata => mem_rdata
	);
  CPU_RequestGen: process
  constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU RequestGen");
  begin
	mem_req <='1';
	rst <='1';
	mem_wmask <="1";
	mem_write <='0';
	mem_addr <= "10010";

	wait until rising_edge(clk);
	wait until rising_edge(clk);
	rst <='0';
	wait until rising_edge(clk);
	mem_write <='1';
	mem_wdata <= (others => '0');
	mem_wdata(0) <= '1';
	mem_wdata(2) <= '1';
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	mem_addr <= "00010";
	mem_write <='0';

	simDeactivateProcess(simProcessID);
	simFinalize;
    wait;
  end process CPU_RequestGen;

end architecture sim;
