--------------------------------------------------------------------------------
-- Title       : Latch array
-- Project     : amshal_misc
--------------------------------------------------------------------------------
-- File        : SRAM_latch_array.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Nov  3 16:16:45 2020
-- Last update : Fri Nov  6 11:58:07 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: Latch array to emulate SRAM array
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity SRAM_latch_array is
	generic (
		SRAM_width : natural := 32;
		SRAM_depth : natural := 64
	);
	port (
		clk       : in  std_logic;
		addr      : in  std_logic_vector(log2ceil(SRAM_depth)-1 downto 0);
		en        : in  std_logic;
		write_pin : in  std_logic;
		data_in   : in  std_logic_vector(SRAM_width-1 downto 0);
		data_out  : out std_logic_vector(SRAM_width-1 downto 0)
	);
end entity SRAM_latch_array;

architecture SRAM_latch_array_arch of SRAM_latch_array is
	constant addr_len : natural := log2ceil(SRAM_depth);

	type SRAM_latches is array (SRAM_depth-1 downto 0) of std_logic_vector(SRAM_width-1 downto 0);
	signal latches : SRAM_latches;
	--signal latches_w : SRAM_latches;

	signal latch_mux_array : gen_mux_array(SRAM_depth-1 downto 0,SRAM_width-1 downto 0);
	signal out_mux_array : gen_mux_array(1 downto 0,SRAM_width-1 downto 0);

	signal dec_in  : unsigned(addr_len-1 downto 0);
	signal dec_out : std_logic_vector((2**addr_len)-1 downto 0);

	signal w_en      : std_logic;
	signal w_enabler : std_logic_vector(SRAM_depth-1 downto 0);
	signal writer    : std_logic_vector(SRAM_depth-1 downto 0);

	signal last_mux_sel : integer range 0 to 1;

	signal l_mux_2_output : std_logic_vector(SRAM_width-1 downto 0);
	signal o_mux_2_output : std_logic_vector(SRAM_width-1 downto 0);

begin
	clk_proc : process (clk)
	begin
		if rising_edge(clk) then
			if (en = '1') then
				if (write_pin = '1') then
					w_en <= '1';
					
				else
					w_en <= '0';
				end if;
			end if;
		end if;
	end process clk_proc;
	
	dec_in <= unsigned(addr);
		decoder : DEC_generic generic map (addr_len) port map (dec_in,dec_out);
	--generate enable signals

	--generate write signals
	FOR_GEN_WRITEER : for w in SRAM_depth-1 downto 0 generate
		writer(w)    <= dec_out(w) and w_en;
		w_enabler(w) <= dec_out(w) and en;
	end generate FOR_GEN_WRITEER;

	--generate the latch rows
	FOR_GEN_LATCH_ROWS : for i in SRAM_depth-1 downto 0 generate
			l_row : latch_row generic map (SRAM_width) port map (w_enabler(i), writer(i), data_in, latches(i));
	end generate FOR_GEN_LATCH_ROWS;

	FOR_GEN_SRAM_2_mux : for i in SRAM_depth-1 downto 0 generate
		FOR_GEN_SRAM_2_mux_2 : for j in SRAM_width-1 downto 0 generate
			latch_mux_array(i,j) <= latches(i)(j);
		end generate FOR_GEN_SRAM_2_mux_2;
	end generate FOR_GEN_SRAM_2_mux;

	-- Output MUX
	latch_2_out : MUX_generic
		generic map (
			SRAM_width,
			SRAM_depth
		)
		port map (
			latch_mux_array,
			to_integer(dec_in),
			l_mux_2_output
		);

	FOR_GEN_L_MUX_2_O_MUX : for v in SRAM_width-1 downto 0 generate
		out_mux_array(0,v) <= l_mux_2_output(v);
		out_mux_array(1,v) <= '0';
	end generate FOR_GEN_L_MUX_2_O_MUX;
	last_mux_sel <= std_logic_2_int(w_en);
	mux_2_out : MUX_generic
		generic map (
			SRAM_width,
			2
		)
		port map (
			out_mux_array,
			last_mux_sel,
			o_mux_2_output
		);
	
	 data_out <= o_mux_2_output;
end architecture SRAM_latch_array_arch;