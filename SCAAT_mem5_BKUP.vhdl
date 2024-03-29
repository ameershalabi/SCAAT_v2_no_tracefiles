--------------------------------------------------------------------------------
--
-- Title		: SCAAT_mem5.vhdl
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


entity SCAAT_CAM_mem is
	generic(
		memDim        : natural  := 12; --9
		tag_bits      : positive := 2; --13
		cam_count_log : natural  := 0
	);

	port (
		clk      : in std_logic;                     -- clk
		rst      : in std_logic;                     -- reset
		enable_w : in std_logic;                     -- global write enable
		addr     : in unsigned(memDim-1 downto 0);   -- address location in memory
		addr_tag : in unsigned(tag_bits-1 downto 0); -- data
		                                             --hit_out_test: out  std_logic;
		dataout : out unsigned(memDim downto 0)      -- data out
	);

end entity SCAAT_CAM_mem;

--------------------------------------------------------------------------------

architecture SCAAT_CAM_mem_RTL of SCAAT_CAM_mem is

	--------------------------------------------------------------------------------
	--	components
	--------------------------------------------------------------------------------

	component SCAAT_CAM2 is
		generic (
			cam_depth    : natural := 64;
			cam_width    : natural := 6;
			cam_addr_len : natural := 4
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
	constant cam_count    : natural                        := 2**cam_count_log;
	constant mem_depth    : natural                        := (2**memDim)/cam_count;
	constant cam_addr_len : natural                        := log2ceil(mem_depth);
	constant mem_width    : natural                        := tag_bits;
	--------------------------------------------------------------------------------
	signal CAM_addr_out : unsigned(cam_addr_len-1 downto 0);

	signal CAM_hit_out : std_logic;

	--------------------------------------------------------------------------------
	--	Signals
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	-- control signals
	signal hit_signal     : std_logic_vector(cam_count-1 downto 0);
	signal hit_signal_vec : std_logic_vector(cam_count-1 downto 0);
	signal hit_out        : std_logic;
	--------------------------------------------------------------------------------
	-- data signals	
	signal CAM_addr_in : unsigned(cam_addr_len-1 downto 0);
	signal CAM_data_in : unsigned(tag_bits-1 downto 0);
	signal selector    : natural;

begin

	CAM_addr_in <= addr(cam_addr_len-1 downto 0); -- write operation
	                                              -- assign data
	CAM_data_in <= addr_tag;

	--------------------------------------------------------------------------------
	-- Generate loop for creating the cam array
	--------------------------------------------------------------------------------
	GEN_CAM_array : for cam_number in 0 to cam_count-1 generate
		-- cam array
		cam : SCAAT_CAM2
			generic map(mem_depth,mem_width,cam_addr_len)
			port map(
				clk,
				rst,
				'0', --global_f_rst_signal(cam_number),
				enable_w,
				CAM_addr_in,
				CAM_data_in,
				--f_rst_signals(cam_number),
				CAM_addr_out,
				CAM_hit_out
			);
	end generate;

	hit_out <= CAM_hit_out;
	dataout <= hit_out&CAM_addr_out;

end SCAAT_CAM_mem_RTL;

