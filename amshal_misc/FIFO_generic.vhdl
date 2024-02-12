--------------------------------------------------------------------------------
-- Title       : A generic FIFO 
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : FIFO_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 29 17:22:41 2020
-- Last update : Fri Oct 30 15:24:42 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: A generic FIFO with full/empty and ALMOST full/empty signals
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

entity FIFO_generic is
	generic (
		FIFO_WIDTH        : natural := 2;
		FIFO_DEPTH        : integer := 8;
		FIFO_AF_THRESHOLD : integer := 7;
		FIFO_AE_THRESHOLD : integer := 1
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		-- write to FIFO signals
		FIFO_write : in  std_logic;
		write_data : in  std_logic_vector(FIFO_WIDTH-1 downto 0);
		FIFO_AF    : out std_logic;
		FIFO_full  : out std_logic;
		-- read from FIFO signals
		FIFO_read  : in  std_logic;
		read_data  : out std_logic_vector(FIFO_WIDTH-1 downto 0);
		FIFO_AE    : out std_logic;
		FIFO_empty : out std_logic
	);
end FIFO_generic;

architecture FIFO_generic_arch of FIFO_generic is

	type FIFO_DATA is array (0 to FIFO_DEPTH-1) of std_logic_vector(FIFO_WIDTH-1 downto 0);
	signal FIFO_DATA_reg : FIFO_DATA := (others => (others => '0'));

	signal write_loc : integer range 0 to FIFO_DEPTH-1 := 0;
	signal read_loc  : integer range 0 to FIFO_DEPTH-1 := 0;

	-- # Words in FIFO, has extra range to allow for assert conditions
	signal FIFO_count : integer range -1 to FIFO_DEPTH+1 := 0;

	signal FIFO_full_sig  : std_logic;
	signal FIFO_empty_sig : std_logic;

	signal incr_FIFO      : boolean;
	signal decr_FIFO      : boolean;
	signal can_write_FIFO : boolean;
	signal can_read_FIFO  : boolean;

begin
	--------------------------------------------------------------------------------
	-- CONTROL SIGNALS
	--------------------------------------------------------------------------------
	-- increment FIFO when write to FIFO is performed
	incr_FIFO <= true when FIFO_write = '1' and FIFO_read = '0' else false;
	-- decrement FIFO when read from FIFO is performed
	decr_FIFO <= true when FIFO_write = '0' and FIFO_read = '1' else false;
	-- is it possible to write to FIFO? (write signal and FIFO not full)
	can_write_FIFO <= true when FIFO_write = '1' and FIFO_full_sig = '0' else false;
	-- is it possible to read from FIFO? (read signal and FIFO not empty)
	can_read_FIFO <= true when FIFO_read = '1' and FIFO_empty_sig = '0' else false;

	--------------------------------------------------------------------------------
	-- Synched control process
	--------------------------------------------------------------------------------
	control_proc : process (clk) is
	begin
		if rising_edge(clk) then
			-- Reset FIFO
			if rst = '1' then
				FIFO_count <= 0;
				write_loc  <= 0;
				read_loc   <= 0;
			else
				-- Check if can write to FIFO
				if (can_write_FIFO) then
					-- If write location is highest, roll-over writing location 
					-- to begining of FIFO
					if write_loc = FIFO_DEPTH-1 then
						write_loc <= 0;
					else
						write_loc <= write_loc + 1;
					end if;
				end if;

				-- If read location is highest, roll-over read location 
				-- to begining of FIFO
				if (can_read_FIFO) then
					if read_loc = FIFO_DEPTH-1 then
						read_loc <= 0;
					else
						read_loc <= read_loc + 1;
					end if;
				end if;

				-- Write to FIFO when write is enabled
				if FIFO_write = '1' then
					FIFO_DATA_reg(write_loc) <= write_data;
				end if;

				-- Keeps track of the total number of words in the FIFO
				if (incr_FIFO) then
					-- increment FIFO
					FIFO_count <= FIFO_count + 1;
				elsif (decr_FIFO) then
					-- decrement FIFO
					FIFO_count <= FIFO_count - 1;
				end if;
			end if;
		end if;
	end process control_proc;

	-- Read from current read location
	read_data <= FIFO_DATA_reg(read_loc);

	-- Check if FIFO is full
	FIFO_full_sig  <= '1' when FIFO_count = FIFO_DEPTH else '0';
	-- Check if FIFO is empty
	FIFO_empty_sig <= '1' when FIFO_count = 0 else '0';

	-- Signal if FIFO is almost full
	FIFO_AF <= '1' when FIFO_count > FIFO_AF_THRESHOLD else '0';
	-- Signal if FIFO is almost empty
	FIFO_AE <= '1' when FIFO_count < FIFO_AE_THRESHOLD else '0';

	-- Send full/empty signals
	FIFO_full  <= FIFO_full_sig;
	FIFO_empty <= FIFO_empty_sig;

end FIFO_generic_arch;