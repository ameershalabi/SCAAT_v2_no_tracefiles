--------------------------------------------------------------------------------
-- Title       : Array of SRAM emulation cells
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : SRAM_cell_array.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov  4 13:10:11 2020
-- Last update : Sat Nov  7 15:08:04 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: Array of SRAM emulation cells
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity SRAM_cell_array is
	generic (
		array_width : natural := 2;
		array_depth : natural := 4
	);
	port (
		clk       : in  std_logic                                          := 'Z';
		addr      : in  std_logic_vector(log2ceil(array_depth)-1 downto 0) := (others => 'Z');
		en        : in  std_logic                                          := 'Z';
		write_pin : in  std_logic                                          := 'Z';
		read_pin  : in  std_logic                                          := 'Z';
		data_in   : in  std_logic_vector(array_width-1 downto 0)           := (others => 'Z');
		b_l_out   : out std_logic_vector(array_width-1 downto 0)           := (others => 'Z');
		nb_l_out  : out std_logic_vector(array_width-1 downto 0)           := (others => 'Z')

	);
end entity SRAM_cell_array;

architecture SRAM_cell_array_arch of SRAM_cell_array is
	constant addr_len : natural := log2ceil(array_depth);

	-- inputs
	signal in_data : std_logic_vector(array_width-1 downto 0) := (others => 'Z');
	signal in_addr : std_logic_vector(addr_len-1 downto 0)    := (others => 'Z');
	signal in_en   : std_logic                                := 'Z';
	signal in_w    : std_logic                                := 'Z';
	signal in_r    : std_logic                                := 'Z';

	--control
	signal dec_in    : unsigned(addr_len-1 downto 0)              := (others => 'Z');
	signal dec_out   : std_logic_vector((2**addr_len)-1 downto 0) := (others => 'Z');
	signal arr_w_l   : std_logic_vector((2**addr_len)-1 downto 0) := (others => 'Z');
	signal b_l_cell  : std_logic_vector(array_width-1 downto 0)   := (others => 'Z');
	signal nb_l_cell : std_logic_vector(array_width-1 downto 0)   := (others => 'Z');
	signal out_b_l   : std_logic_vector(array_width-1 downto 0)   := (others => 'Z');
	signal out_nb_l  : std_logic_vector(array_width-1 downto 0)   := (others => 'Z');

begin
	-- clocked input registers
	--clk_proc : process (clk)
	--begin
	--	if clk'event and clk='1' then
	--		in_data <= (others => '0');
	--		in_addr <= (others => '0');
	--		in_en   <= '0';
	--		in_w    <= '0';
	--		in_r    <= '0';
	--		if (en = '1') then
	--			in_data <= data_in;
	--			in_addr <= addr;
	--			in_en   <= en;
	--			in_w    <= write_pin;
	--			in_r    <= read_pin;
	--		end if;
	--	end if;
	--end process clk_proc;
	
	-- buffer inputs
	in_data <= data_in;
	in_addr <= addr;
	in_en <= en;
	in_w <= write_pin;
	in_r <= read_pin;
	-- Assign the address to decoder input
	dec_in <= unsigned(in_addr);
		-- decode the address to obtain row selection
		decoder : DEC_generic generic map (addr_len) port map (dec_in,dec_out);
	--decoder : DEC_generic generic map (addr_len) port map (unsigned(in_addr),dec_out);

	-- the word line is activated if select bit and enabled
	FOR_GEN_W_L : for w_l in array_depth-1 downto 0 generate
		--arr_w_l(w_l) <= dec_out(w_l) when in_en='1' else '0';
		arr_w_l(w_l) <= dec_out(w_l) and in_en;
	end generate FOR_GEN_W_L;
	-- data is written into the bit line if write is enabled
	b_l_cell <= in_data when in_w='1' else (others => 'Z');

	-- connect array of cells to word line and bit line
	FOR_GEN_ARRAY_DEPTH : for dep in array_depth-1 downto 0 generate
		FOR_GEN_ARRAY_WIDTH : for wid in array_width-1 downto 0 generate
				cell : SRAM_cell port map (arr_w_l(dep),b_l_cell(wid),nb_l_cell(wid));
		end generate FOR_GEN_ARRAY_WIDTH;
	end generate FOR_GEN_ARRAY_DEPTH;

	-- data is read from bit line if read is enabled
	FOR_GEN_B_L : for b_nb_l in array_width-1 downto 0 generate
		--out_b_l(b_nb_l)  <= b_l_cell(b_nb_l)  when in_r='1' else '0';
		--out_nb_l(b_nb_l) <= nb_l_cell(b_nb_l) when in_r='1' else '0';
		out_b_l(b_nb_l)  <= b_l_cell(b_nb_l) and in_r;
		out_nb_l(b_nb_l) <= nb_l_cell(b_nb_l) and in_r;
	end generate FOR_GEN_B_L;

	-- output is sent out only if read is enabled
	b_l_out  <= out_b_l;
	nb_l_out <= out_nb_l;

end architecture SRAM_cell_array_arch;