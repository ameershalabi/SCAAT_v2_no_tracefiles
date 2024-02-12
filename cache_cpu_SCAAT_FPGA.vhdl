-- Author:         Ameer Shalabi
----

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use IEEE.std_logic_unsigned.all;
library PoC;
use PoC.utils.all;
use PoC.type_def_pack.all;

--library osvvm;
--use osvvm.RandomPkg.all;


entity cache_cpu_SCAAT is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES        : positive	:= 64;
		ASSOCIATIVITY      : positive	:= 1;
		CPU_DATA_BITS      : positive	:= 32;
		MEM_ADDR_BITS      : positive	:= 14;
		MEM_DATA_BITS      : positive	:= 128
	);
	port (
    clk : in std_logic; -- clock
    rst : in std_logic; -- reset

    -- "CPU" side
    cpu_req   : in  std_logic;
    cpu_write : in  std_logic;
    cpu_addr  : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
    cpu_wdata : in  std_logic_vector(CPU_DATA_BITS-1 downto 0);
    cpu_wmask : in  std_logic_vector(CPU_DATA_BITS/8-1 downto 0);
    cpu_got   : out std_logic;
    --cpu_rdata : out std_logic_vector(CPU_DATA_BITS-1 downto 0);

	-- Memory side
	mem_req		: out std_logic;
	mem_write   : out std_logic;
	--mem_addr	: out unsigned(MEM_ADDR_BITS-1 downto 0);
	--mem_wdata   : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
	--mem_wmask   : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
	mem_rdy		: in  std_logic;
	mem_rstb	: in  std_logic;
	--mem_rdata   : in  std_logic_vector(MEM_DATA_BITS-1 downto 0); 

	output_cache_Hit  : out std_logic;
	output_cache_Miss  : out std_logic;
	--AMSHAL
	attk_in : in std_logic
	--SCAAT_addr_out: out unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0)
    );
end entity;

architecture cache_cpu_SCAAT_rtl of cache_cpu_SCAAT is

	component cache_cpu is
		generic (
			REPLACEMENT_POLICY : string		:= "LRU";
			CACHE_LINES        : positive	:= 256;
			ASSOCIATIVITY      : positive	:= 4;
			CPU_DATA_BITS      : positive	:= 32;
			MEM_ADDR_BITS      : positive	:= 14;
			MEM_DATA_BITS      : positive	:= 128
		);
		port (
	    clk : in std_logic; -- clock
	    rst : in std_logic; -- reset

	    -- "CPU" side
	    cpu_req   : in  std_logic;
	    cpu_write : in  std_logic;
	    cpu_addr  : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
	    cpu_wdata : in  std_logic_vector(CPU_DATA_BITS-1 downto 0);
	    cpu_wmask : in  std_logic_vector(CPU_DATA_BITS/8-1 downto 0);
	    cpu_got   : out std_logic;
	    --cpu_rdata : out std_logic_vector(CPU_DATA_BITS-1 downto 0);

		-- Memory side
		mem_req		: out std_logic;
		mem_write   : out std_logic;
		--mem_addr	: out unsigned(MEM_ADDR_BITS-1 downto 0);
		--mem_wdata   : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
		--mem_wmask   : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
		mem_rdy		: in  std_logic;
		mem_rstb	: in  std_logic;
		--mem_rdata   : in  std_logic_vector(MEM_DATA_BITS-1 downto 0);

		output_cache_Hit: out std_logic; 
		output_cache_Miss: out std_logic 
	    );
	end component;

	component SCAAT_unit is
		generic (
		CACHE_LINES        : positive	:= 64;
		ASSOCIATIVITY	   : positive	:= 1;
		CPU_DATA_BITS      : positive	:= 32;
		MEM_ADDR_BITS      : positive	:= 10; -- 2^10 Memory locations
		MEM_DATA_BITS      : positive	:= 128 -- 16-Byte cache line size
	);
	port (
		clk   : in  std_logic;
		cpu_addr  : in  unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
		attk : in std_logic;
		rst: in std_logic;
		SCAAT_addr_out: out unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0)
		);
	end component;


	--type CACHE_WRAPPER_TABLE is array (CACHE_LINES-1 downto 0) of std_logic_vector(MEM_ADDR_BITS+log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);

	--signal wrapper_table, wrapper_table_in: CACHE_WRAPPER_TABLE;

	signal cpu_req_cache   : std_logic;
	signal cpu_write_cache : std_logic;
	signal cpu_addr_cache  : unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
	signal cpu_wdata_cache : std_logic_vector(CPU_DATA_BITS-1 downto 0);
	signal cpu_wmask_cache : std_logic_vector(CPU_DATA_BITS/8-1 downto 0);
	signal cpu_got_cache   : std_logic;
	signal cpu_rdata_cache : std_logic_vector(CPU_DATA_BITS-1 downto 0);

	signal mem_req_cache    : std_logic;
	signal mem_write_cache  : std_logic;
	signal mem_addr_cache   : unsigned(MEM_ADDR_BITS-1 downto 0);
	signal mem_wdata_cache  : std_logic_vector(MEM_DATA_BITS-1 downto 0);
	signal mem_wmask_cache  : std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
	signal mem_rdy_cache    : std_logic;
	signal mem_rstb_cache   : std_logic;
	signal mem_rdata_cache  : std_logic_vector(MEM_DATA_BITS-1 downto 0);

	-- Ratio 1:n between CPU data bus and cache-line size (memory data bus)
	constant RATIO : positive := MEM_DATA_BITS/CPU_DATA_BITS;

	-- Number of address bits identifying the CPU data word within a cache line (memory word)
	constant LOWER_ADDR_BITS : natural := log2ceil(RATIO);
	-- We temporarily take these signals to output to perform formal verification
	signal cache_Request: std_logic; 
	signal cache_ReadWrite: std_logic;  
	--signal cache_Hit: std_logic; 
	--signal cache_Miss: std_logic; 
	signal DM_TagHit_signal: std_logic;
	--signal TagHits_signal: std_logic_vector(ASSOCIATIVITY-1 downto 0);
	--signal TagMemory_signal: T_TAG_LINE_VECTOR;
	signal fsm_cs: T_FSM;
	--#########################################
	--AMSHAL 
	signal SCAAT_addr_out: unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);
	signal final_addr_out: unsigned(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);

begin  -- architecture rtl


 	cache_cpu_inst: entity work.cache_cpu
	    generic map (
					REPLACEMENT_POLICY => REPLACEMENT_POLICY,
					CACHE_LINES        => CACHE_LINES,
					ASSOCIATIVITY      => ASSOCIATIVITY,
					CPU_DATA_BITS      => CPU_DATA_BITS,
					MEM_ADDR_BITS      => MEM_ADDR_BITS,
					MEM_DATA_BITS      => MEM_DATA_BITS
				    )
	    port map (
					clk          => clk,
					rst          => rst,

					 cpu_req      => cpu_req,
					 cpu_write    => cpu_write,
					 --cpu_addr     => cpu_addr,
					 cpu_addr     => SCAAT_addr_out,
					 cpu_wdata    => cpu_wdata,
					 cpu_wmask    => cpu_wmask,
					 cpu_got      => cpu_got,
					 --cpu_rdata	=> cpu_rdata,

					 mem_req 	 => mem_req,
					 mem_write 	 => mem_write,
					 ----mem_addr 	 => --mem_addr,
					 ----mem_wdata	 => --mem_wdata,
					 ----mem_wmask 	 => --mem_wmask,
					 mem_rdy	 => mem_rdy,
					 mem_rstb	 => mem_rstb,
					 --mem_rdata	 => mem_rdata, 
					output_cache_Hit => output_cache_Hit, 
					output_cache_Miss => output_cache_Miss
				);

	--SCAAT_tbl3: entity work.SCAAT_unit3
	SCAAT_tbl2: entity work.SCAAT_unit2
	--SCAAT_tbl: entity work.SCAAT_unit
	    generic map (
	    			CACHE_LINES        => CACHE_LINES,
					ASSOCIATIVITY      => ASSOCIATIVITY,
					CPU_DATA_BITS      => CPU_DATA_BITS,
					MEM_ADDR_BITS      => MEM_ADDR_BITS,
					MEM_DATA_BITS      => MEM_DATA_BITS
				    )
	    port map (
					clk 			=> clk,
					cpu_addr 		=> cpu_addr,
					attk 			=> attk_in,
					rst 			=> rst,
					SCAAT_addr_out 	=> SCAAT_addr_out
				);

end architecture cache_cpu_SCAAT_rtl;
