--------------------------------------------------------------------------------
--
-- Title		: SCAAT_mem5_4MB.vhdl
-- Project		: SCAAT
-- Design 		: SCAAT CAM array with index
-- Author		: Ameer Shalabi
-- Date			: 15/10/2020
-- Institution	: Tallinn University of Technology
--------------------------------------------------------------------------------
--
-- Description
-- A CAM array controller for SCAAT 
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
-- for addition & counting
use ieee.std_logic_unsigned.all;
-- for type conversions				
use ieee.numeric_std.all;
-- for the ceiling and log constant calculation functions			
use ieee.math_real.all;

library work;
--use work.SCAAT_pkg.all;
use work.amshal_misc_pkg.all;


entity SCAAT_CAM_4MB is
	generic(
		memDim        : natural  := 12; --9
		tag_bits      : positive := 2;  --13
		cam_count_log : natural  := 0
	);

	port (
		clk      : in std_logic; -- clk
		rst      : in std_logic; -- reset
		f_rst    : in std_logic;
		enable_w : in std_logic;                     -- global write enable
		addr     : in unsigned(memDim-1 downto 0);   -- address location in memory
		addr_tag : in unsigned(tag_bits-1 downto 0); -- data
		                                             --hit_out_test: out  std_logic;
		dataout : out unsigned(memDim downto 0)      -- data out
	);

end entity SCAAT_CAM_4MB;

--------------------------------------------------------------------------------

architecture SCAAT_CAM_4MB_RTL of SCAAT_CAM_4MB is

	--------------------------------------------------------------------------------
	--	components
	--------------------------------------------------------------------------------

	component SCAAT_CAM2 is
		generic (
			cam_depth    : natural := 1024;
			cam_width    : natural := 6;
			cam_addr_len : natural := 10
		);
		port (
			clk      : in std_logic;
			rst      : in std_logic;
			f_rst_in : in std_logic;
			en_CAM   : in std_logic;
			cam_addr : in unsigned(cam_addr_len-1 downto 0);  -- address location in memory
			cam_data : in unsigned(cam_width-1 downto 0);     -- data
			                                --f_rst_out					: out	std_logic;
			data_out : out unsigned(cam_addr_len-1 downto 0); -- data out
			hit_out  : out std_logic                          -- CAM_hit (found in SCAAT)
		);
	end component SCAAT_CAM2;

	--------------------------------------------------------------------------------
	-- constants
	constant resetVal     : unsigned (tag_bits-1 downto 0) := (others => '1');
	constant cam_count    : natural                        := (2**memDim)/1024;
	constant mem_depth    : natural                        := 1024;
	constant cam_addr_len : natural                        := log2ceil(mem_depth);
	constant mem_width    : natural                        := tag_bits;

	--------------------------------------------------------------------------------
	signal CAM_addr_out : unsigned(cam_addr_len-1 downto 0);

	signal CAM_hit_out : std_logic;

	type CAMs is array (3 downto 0) of std_logic;
	signal CAM_hits : CAMs;

	type enabler is array (3 downto 0) of std_logic;
	signal en : enabler;

	type CAM_out is array (3 downto 0) of unsigned(cam_addr_len-1 downto 0);
	signal CAM_addr_o : CAM_out;

	--------------------------------------------------------------------------------
	--	Signals
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	-- control signals
	--signal hit_signal                    : std_logic_vector(cam_count-1 downto 0);
	--signal hit_signal_vec                : std_logic_vector(cam_count-1 downto 0);
	signal hit_out,CAM_hits01,CAM_hits23 : std_logic;
	--------------------------------------------------------------------------------
	-- data signals	
	signal CAM_addr_in : unsigned(cam_addr_len-1 downto 0);
	signal CAM_data_in : unsigned(tag_bits-1 downto 0);
	signal selector    : unsigned(1 downto 0);
	signal hit_CAM     : unsigned(1 downto 0);


begin

	CAM_addr_in <= addr(9 downto 0);
	selector    <= addr(11 downto 10);

	en(0) <= '1' when enable_w='1' and selector="00" else '0';
	en(1) <= '1' when enable_w='1' and selector="01" else '0';
	en(2) <= '1' when enable_w='1' and selector="10" else '0';
	en(3) <= '1' when enable_w='1' and selector="11" else '0';

	CAM_data_in <= addr_tag; -- assign data
	                         --------------------------------------------------------------------------------
	                         -- Generate loop for creating the cam array
	                         --------------------------------------------------------------------------------
	GEN_CAM_array : for cam_count in 0 to 3 generate
		-- cam array
		cam : SCAAT_CAM2
			generic map(mem_depth,mem_width,cam_addr_len)
			port map(
				clk,
				rst,
				f_rst, --global_f_rst_signal(cam_number),
				en(cam_count),
				CAM_addr_in,
				CAM_data_in,
				--f_rst_signals(cam_number),
				CAM_addr_o(cam_count),
				CAM_hits(cam_count)
			);
	end generate;

	CAM_hits01  <= CAM_hits(0) or CAM_hits(1);
	CAM_hits23  <= CAM_hits(2) or CAM_hits(3);
	CAM_hit_out <= CAM_hits01 or CAM_hits23;

	hit_CAM <= "00" when CAM_hits(0)='1' else
		"01" when CAM_hits(1)='1' else
		"10" when CAM_hits(2)='1' else
		"11" when CAM_hits(3)='1';

	CAM_addr_out <= CAM_addr_o(0) when CAM_hits(0)='1' else
		CAM_addr_o(1) when CAM_hits(1)='1' else
		CAM_addr_o(2) when CAM_hits(2)='1' else
		CAM_addr_o(3) when CAM_hits(3)='1';

	hit_out <= CAM_hit_out;
	dataout <= hit_out&hit_CAM&CAM_addr_out;

end SCAAT_CAM_4MB_RTL;

