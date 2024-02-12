--------------------------------------------------------------------------------
--
-- Title		: SCAAT_CAM.vhdl
-- Project		: SCAAT
-- Design 		: SCAAT CAM
-- Author		: Ameer Shalabi
-- Date			: 14/10/2020
-- Institution	: Tallinn University of Technology
--------------------------------------------------------------------------------
--
-- Description
-- A CAM for SCAAT memeory
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.SCAAT_pkg.all;

entity SCAAT_CAM is
	generic (
		cam_depth    : natural := 64;
		cam_width    : natural := 1;
		cam_addr_len : natural := 6
	);
	port (
		clk      : in std_logic;
		rst      : in std_logic;
		f_rst_in : in std_logic;
		en_CAM   : in std_logic;
		cam_addr : in unsigned(cam_addr_len-1 downto 0);  -- address location in memeory
		cam_data : in unsigned(cam_width-1 downto 0);     -- data
		                                --f_rst_out					: out	std_logic;
		data_out : out unsigned(cam_addr_len-1 downto 0); -- data out
		hit_out  : out std_logic                          -- CAM_hit (found in SCAAT)
	);
end SCAAT_CAM;

architecture SCAAT_CAM_arc of SCAAT_CAM is
	--------------------------------------------------------------------------------
	--  Signals
	--------------------------------------------------------------------------------
	constant rst_value : unsigned (cam_width-1 downto 0) := (others => '1');
	--	create the memory 2D array of depth
	type SCAAT_CAM_mem is array (cam_depth - 1 downto 0) of unsigned(cam_width-1 downto 0);
	--	create the access signal to the array
	signal SCAAT_CAM_accs : SCAAT_CAM_mem;
	-- signal for write location
	signal location : natural range 0 to cam_depth - 1;

	signal data_in : unsigned(cam_width-1 downto 0);
	-- signal to carry output
	signal read_CAM : unsigned (cam_addr_len-1 downto 0);
	-- a buffer for output
	--signal read_CAM_BUF : unsigned (cam_addr_len-1 downto 0);
	-- a hit signal indicating the
	signal CAM_hit : std_logic;

	-- forced  rst signals
	signal local_f_rst_loc_proc : unsigned (cam_addr_len-1 downto 0);
	signal local_f_rst_proc     : std_logic;

	signal global_f_rst_loc_proc : unsigned (cam_addr_len-1 downto 0);
	signal global_f_rst_proc     : std_logic;
begin
	-- location for write
	location <= to_integer(cam_addr);
	-- data in
	data_in <= cam_data;
	--------------------------------------------------------------------------------
	--  write process
	--------------------------------------------------------------------------------
	write_to_CAM : process (rst, clk)
	begin
		if (falling_edge(clk)) then

			if (rst = '1') then
				-- reset all the CAM locations
				SCAAT_CAM_accs <= (others => (rst_value));
			elsif (en_CAM = '1') then
				-- when enabled, store data at location
				SCAAT_CAM_accs(location) <= data_in;
			end if;
		end if;
		if (local_f_rst_proc = '1') then
			SCAAT_CAM_accs(to_integer(local_f_rst_loc_proc)) <= rst_value;
		elsif (global_f_rst_proc = '1') then
			SCAAT_CAM_accs(to_integer(global_f_rst_loc_proc)) <= rst_value;
		end if;
	end process write_to_CAM;


	--------------------------------------------------------------------------------
	--  read process
	--------------------------------------------------------------------------------
	read_from_CAM : process (SCAAT_CAM_accs,data_in,location,en_CAM)
	begin
		-- read the output
		read_CAM             <= to_unsigned(0, cam_addr_len);
		CAM_hit              <= '0';
		local_f_rst_loc_proc <= (others => '1');
		local_f_rst_proc     <= '0';

		CAM_read_loop : for i in 0 to cam_depth-1 loop
			-- if the data found in the CAM, return the location
			if (SCAAT_CAM_accs(i) = data_in) then
				if en_CAM ='1' and (i /= location) then
					local_f_rst_loc_proc <= to_unsigned(i, cam_addr_len);
					local_f_rst_proc     <= '1';
				end if;
				read_CAM <= to_unsigned(i, cam_addr_len);
				-- send a hit signal
				CAM_hit <= '1';
			end if;
		end loop;
	end process read_from_CAM;

	--------------------------------------------------------------------------------
	-- force reset process
	--------------------------------------------------------------------------------
	force_reset_global : process (SCAAT_CAM_accs,data_in,f_rst_in)
	begin
		global_f_rst_loc_proc <= (others => '1');
		global_f_rst_proc     <= '0';
		CAM_read_loop : for i in 0 to cam_depth-1 loop
			if (SCAAT_CAM_accs(i) = data_in) then
				if f_rst_in ='1' then
					global_f_rst_loc_proc <= to_unsigned(i, cam_addr_len);
					global_f_rst_proc     <= '1';
				end if;
			end if;
		end loop;
	end process force_reset_global;
	--------------------------------------------------------------------------------
	--  output signals
	--------------------------------------------------------------------------------
	hit_out  <= CAM_hit;
	data_out <= read_CAM;
end SCAAT_CAM_arc;
