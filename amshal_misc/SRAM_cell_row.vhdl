--------------------------------------------------------------------------------
-- Title       : Row of SRAM emulation cells
-- Project     : amshal_misc
--------------------------------------------------------------------------------
-- File        : SRAM_cell_row.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov  4 13:09:12 2020
-- Last update : Wed Nov  4 13:10:04 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Description: a row of latches between two enable AND gates
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity SRAM_cell_row is
	generic (
		row_width : natural := 4
	);
	port (
		en        : in  std_logic;
		w         : in  std_logic;
		r         : in  std_logic;
		row_d_in  : in  std_logic_vector(row_width-1 downto 0);
		row_d_out : out std_logic_vector(row_width-1 downto 0)
	);
end entity SRAM_cell_row;

architecture SRAM_cell_row_arch of SRAM_cell_row is
	signal la_in  : std_logic_vector(row_width-1 downto 0);
	signal n_la   : std_logic_vector(row_width-1 downto 0);
	signal la_out : std_logic_vector(row_width-1 downto 0);
	signal w_ctrl : std_logic;
	signal r_ctrl : std_logic;
begin
	w_ctrl <= en and w;
	r_ctrl <= en and (r and NOT w);

		en_w : en_and generic map (row_width) port map (w_ctrl, row_d_in, la_in);

	FOR_GEN_LATCH_ROW : for i in row_width-1 downto 0 generate
			cell : SRAM_cell port map (en,la_in(i),n_la(i));
	end generate FOR_GEN_LATCH_ROW;

		en_r : en_and generic map (row_width) port map (r_ctrl, la_in,row_d_out);

	row_d_out <= la_out;
end architecture SRAM_cell_row_arch;
