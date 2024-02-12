-- Authors:         Siavoosh Payandeh Azad, Behrad Niazmand
--
-- Entity:          Reconfigurable/parameterized cache wrapper with interface to CPU and Main memory
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library PoC;
use PoC.utils.all;
use PoC.type_def_pack.all;

--library osvvm;
--use osvvm.RandomPkg.all;


entity cache_cpu_wrapper is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES        : positive	:= 64;
		ASSOCIATIVITY      : positive	:= 1;
		CPU_DATA_BITS      : positive	:= 32;
		MEM_ADDR_BITS      : positive	:= 10; -- 2^10 Memory locations
		MEM_DATA_BITS      : positive	:= 128 -- 16-Byte cache line size
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
    cpu_rdata : out std_logic_vector(CPU_DATA_BITS-1 downto 0);

	-- Memory side
	mem_req		: out std_logic;
	mem_write   : out std_logic;
	mem_addr	: out unsigned(MEM_ADDR_BITS-1 downto 0);
	mem_wdata   : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
	mem_wmask   : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
	mem_rdy		: in  std_logic;
	mem_rstb	: in  std_logic;
	mem_rdata   : in  std_logic_vector(MEM_DATA_BITS-1 downto 0); 

	output_cache_Hit  : out std_logic;
	output_cache_Miss  : out std_logic		
    );
end entity;

architecture rtl of cache_cpu_wrapper is

	component cache_cpu is
		generic (
			REPLACEMENT_POLICY : string		:= "LRU";
			CACHE_LINES        : positive	:= 64;
			ASSOCIATIVITY      : positive	:= 4;
			CPU_DATA_BITS      : positive	:= 32;
			MEM_ADDR_BITS      : positive	:= 10; -- 2^10 Memory locations
			MEM_DATA_BITS      : positive	:= 128 -- 16B cache line size
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
	    cpu_rdata : out std_logic_vector(CPU_DATA_BITS-1 downto 0);

		-- Memory side
		mem_req		: out std_logic;
		mem_write   : out std_logic;
		mem_addr	: out unsigned(MEM_ADDR_BITS-1 downto 0);
		mem_wdata   : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
		mem_wmask   : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
		mem_rdy		: in  std_logic;
		mem_rstb	: in  std_logic;
		mem_rdata   : in  std_logic_vector(MEM_DATA_BITS-1 downto 0);

		-- We temporarily take these signals to output to perform formal verification
		--output_cache_Request: out std_logic; 
		--output_cache_ReadWrite: out std_logic;  
		--output_DM_TagHit_signal: out std_logic;
		--output_TagHits_signal: out std_logic_vector(ASSOCIATIVITY-1 downto 0);
		--output_TagMemory_signal: out T_TAG_LINE_VECTOR;
		--output_TagMemory_signal: out WAY_TYPE;
		--output_Address_Index_signal: out unsigned(INDEX_BITS - 1 downto 0);
		--output_ValidMemory_signal: out std_logic_vector(CACHE_LINES-1 downto 0);
		--output_ValidMemory_signal: out WAY_TYPE_2;
		--output_Address_Tag_signal: out std_logic_vector(TAG_BITS-1 downto 0);
		--output_fsm_cs: out T_FSM;
		output_cache_Hit: out std_logic; 
		output_cache_Miss: out std_logic 
	    );
	end component;


	type CACHE_WRAPPER_TABLE is array (CACHE_LINES-1 downto 0) of std_logic_vector(MEM_ADDR_BITS+log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0);

	signal wrapper_table, wrapper_table_in: CACHE_WRAPPER_TABLE;

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
	signal TagMemory_signal: T_TAG_LINE_VECTOR;
	signal Address_Index_signal: unsigned(INDEX_BITS - 1 downto 0);
	signal ValidMemory_signal: std_logic_vector(CACHE_LINES-1 downto 0);
	--signal ValidMemory_signal: WAY_TYPE_2;
	signal Address_Tag_signal: std_logic_vector(TAG_BITS-1 downto 0);
	signal fsm_cs: T_FSM;


begin  -- architecture rtl
-------------------------------------------
   --cpu_req_cache   <= cpu_req;
   --cpu_write_cache <= cpu_write;
  
   --cpu_wdata_cache <= cpu_wdata;
   --cpu_wmask_cache <= cpu_wmask;
   --cpu_got         <= cpu_got_cache;
   --cpu_rdata       <= cpu_rdata_cache;
   ---------------------------------------------
   --mem_req         <= mem_req_cache;
   --mem_write       <= mem_write_cache;
  
   --mem_wdata       <= mem_wdata_cache;
   --mem_wmask       <= mem_wmask_cache;
   --mem_rdy_cache   <= mem_rdy;
   --mem_rstb_cache  <= mem_rstb;
   --mem_rdata_cache <= mem_rdata;
-------------------------------------------

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
				 cpu_addr     => cpu_addr,
				 cpu_wdata    => cpu_wdata,
				 cpu_wmask    => cpu_wmask,
				 cpu_got      => cpu_got,
				 cpu_rdata	=> cpu_rdata,

				--cpu_req      => cpu_req_cache,
				--cpu_write    => cpu_write_cache,
				--cpu_addr     => cpu_addr_cache,
				--cpu_wdata    => cpu_wdata_cache,
				--cpu_wmask    => cpu_wmask_cache,
				--cpu_got      => cpu_got_cache,
				--cpu_rdata	 => cpu_rdata_cache,

				 mem_req 	 => mem_req,
				 mem_write 	 => mem_write,
				 mem_addr 	 => mem_addr,
				 mem_wdata	 => mem_wdata,
				 mem_wmask 	 => mem_wmask,
				 mem_rdy	 => mem_rdy,
				 mem_rstb	 => mem_rstb,
				 mem_rdata	 => mem_rdata, 

				--mem_req 	 => mem_req_cache,
				--mem_write  => mem_write_cache,
				--mem_addr 	 => mem_addr_cache,
				--mem_wdata	 => mem_wdata_cache,
				--mem_wmask  => mem_wmask_cache,
				--mem_rdy	 => mem_rdy_cache,
				--mem_rstb	 => mem_rstb_cache,
				--mem_rdata	 => mem_rdata_cache, 

				-- We temporarily take these signals to output to perform formal verification
				--output_cache_Request => cache_Request, 
				--output_cache_ReadWrite => cache_ReadWrite, 
				--output_DM_TagHit_signal => DM_TagHit_signal, 
				--output_TagHits_signal <= TagHits_signal;
				--output_TagMemory_signal => TagMemory_signal, 
				--output_Address_Index_signal => Address_Index_signal, 
				--output_ValidMemory_signal => ValidMemory_signal, 
				--output_Address_Tag_signal => Address_Tag_signal, 
				--output_fsm_cs => fsm_cs, 
				output_cache_Hit => output_cache_Hit, 
				output_cache_Miss => output_cache_Miss
			);


 	-- Any further code needed to write for the wrapper!
 	-- We need to initialize the CACHE WRAPPER TABLE when reseting the wrapper!
ClkProcess:	process(clk, rst)begin
		if rst = '1' then
				wrapper_table <= (others => (others => '0'));

		elsif clk'event and clk = '1' then
				wrapper_table <= wrapper_table_in;

		end if;
	end process;

UpdateTable: process(cpu_addr, wrapper_table, cpu_req)
	variable found  : boolean := False;
	variable counter :  std_logic_vector(6-1 downto 0) := std_logic_vector(to_unsigned(1,6));
	variable pointer :  std_logic_vector(log2ceil(CACHE_LINES)-1 downto 0) := (others => '0');
	variable addr_val :std_logic_vector(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0) := (others => '0');
	variable countershift : std_logic := '0';
begin

	cpu_addr_cache <= to_unsigned(0,log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS);
	wrapper_table_in <= wrapper_table;

	if cpu_req = '1' then
		found := False;
		for i in 0 to CACHE_LINES-1 loop
			if wrapper_table(i)(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto LOWER_ADDR_BITS) = std_logic_vector(cpu_addr (log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto LOWER_ADDR_BITS)) then
				found := True;
				if (RATIO > 1) then
					addr_val := wrapper_table_in (i) (MEM_ADDR_BITS+log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS) &  std_logic_vector(cpu_addr(LOWER_ADDR_BITS-1 downto 0));
				else
					addr_val := wrapper_table_in (i) (MEM_ADDR_BITS+log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS);				
				end if;
			end if;
		end loop;
		if found = False then
			countershift := counter(0);
			counter(6-2 downto 0) := counter(6-1 downto 1);
			counter(6-1) :=  counter(2) xor countershift; 
			pointer :=  std_logic_vector(unsigned(pointer) + 1);
			wrapper_table_in (to_integer(unsigned(pointer))) (log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto 0) <= std_logic_vector(cpu_addr);
			wrapper_table_in (to_integer(unsigned(pointer))) (MEM_ADDR_BITS+log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS) <=  "0000" & counter;
			if (RATIO > 1) then
				addr_val :=  "0000" & counter & std_logic_vector(cpu_addr(LOWER_ADDR_BITS-1 downto 0));
			else
				addr_val :=  "0000" & counter;
			end if;
		end if;
			cpu_addr_cache <= unsigned(addr_val);
	end if;

end process;

mem_addr <= unsigned(cpu_addr(log2ceil(MEM_DATA_BITS/CPU_DATA_BITS)+MEM_ADDR_BITS-1 downto LOWER_ADDR_BITS));



end architecture rtl;
