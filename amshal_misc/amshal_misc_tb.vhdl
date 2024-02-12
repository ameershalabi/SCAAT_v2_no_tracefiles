--------------------------------------------------------------------------------
-- Title       : A test bench for amshal_misc package
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : amshal_misc_tb.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Fri Oct 30 09:30:08 2020
-- Last update : Wed Nov 11 12:01:23 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Description: A test bench for  the components and functions of amshal package
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.amshal_misc_pkg.all;

entity amshal_misc_tb is
end amshal_misc_tb;

architecture amshal_misc_tb_sim of amshal_misc_tb is
	constant clk_period : time    := 20 ns;

	constant wait_p     : time    := 10 ns;
	constant width      : natural := 8;
	constant depth      : natural := 4;
	constant addr_len   : natural := log2ceil(depth);

	signal end_sim        : boolean   := false;
	signal clk            : std_logic := '1';
	signal rst            : std_logic := '0';
	signal en             : std_logic := '0';
	signal w_en           : std_logic := '0';
	signal r_en           : std_logic := '0';
	signal FIFO_w         : std_logic := '0';
	signal FIFO_r         : std_logic := '0';
	signal f_rst          : std_logic := '0';
	signal sft_r_l        : std_logic := '0';
	signal serial_in      : std_logic := '1';
	signal load_en        : std_logic := '0';
	signal FIFO_AF        : std_logic;
	signal FIFO_full      : std_logic;
	signal FIFO_AE        : std_logic;
	signal FIFO_empty     : std_logic;
	signal incr_over_flow : std_logic;
	signal decr_zero      : std_logic;
	signal SISO_out       : std_logic;
	signal SI_SPO_S_out   : std_logic;
	signal w_l            : std_logic := '0';
	signal b_l            : std_logic := 'Z';

	signal selector : natural := 0;

	signal in_32       : std_logic_vector (31 downto 0)         := (others => '0');
	signal in_16       : std_logic_vector (15 downto 0)         := (others => '0');
	signal in_8        : std_logic_vector (7 downto 0)          := (others => '0');
	signal DEC_addr    : unsigned (width-1 downto 0)            := (others => '0');
	signal rst_value   : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal reg_in      : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal FIFO_in     : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal incr_in     : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal decr_in     : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal load_d      : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal RAM_w_addr  : std_logic_vector (addr_len-1 downto 0) := (others => '0');
	signal RAM_w_data  : std_logic_vector (width-1 downto 0)    := (others => '0');
	signal RAM_r1_addr : std_logic_vector (addr_len-1 downto 0) := (others => '0');
	signal RAM_r2_addr : std_logic_vector (addr_len-1 downto 0) := (others => '0');
	signal rand_load   : std_logic_vector (width-1 downto 0)    := (others => '0');

	signal rand_out      : std_logic_vector (width-1 downto 0);
	signal out_5         : std_logic_vector (4 downto 0);
	signal out_4         : std_logic_vector (3 downto 0);
	signal out_3         : std_logic_vector (2 downto 0);
	signal dec_out       : std_logic_vector ((2**width)-1 downto 0);
	signal reg_f_rst_out : std_logic_vector (width-1 downto 0);
	signal reg_out       : std_logic_vector (width-1 downto 0);
	signal FIFO_out      : std_logic_vector (width-1 downto 0);
	signal incr_out      : std_logic_vector (width-1 downto 0);
	signal decr_out      : std_logic_vector (width-1 downto 0);
	signal SIPO_out      : std_logic_vector (width-1 downto 0);
	signal SI_SPO_P_out  : std_logic_vector (width-1 downto 0);
	signal RAM_r1_data   : std_logic_vector (width-1 downto 0);
	signal RAM_r2_data   : std_logic_vector (width-1 downto 0);

	signal b_l_vec : std_logic_vector (1 downto 0) := (others => 'Z');


	signal mux_out     : std_logic_vector (3 downto 0);
	constant mux_input : gen_mux_array := (
			('0','0','0','0'),
			('1','1','0','0'),
			('1','1','1','1')
		);
begin

	Clock_gen : process
	begin
		while not end_sim loop
			wait for clk_period/4;
			clk <= not clk;
		end loop;
		wait;
	end process Clock_gen;

		--LFSR_RAND_4_test : LFSR_RAND generic map (width)port map (clk,rst,en,rand_out);
		LFSR_gen_4_test : LFSR_generic generic map (width)port map (clk,rst,w_en,rand_load,en,rand_out);
	--------------------------------------------------------------------------------
	-- Encoders
	--------------------------------------------------------------------------------
	--OR_ARRAY_32x5_Enc_4_test : OR_ARRAY_32x5_Enc port map(in_32, out_5);
	--OR_ARRAY_16x4_Enc_4_test : OR_ARRAY_16x4_Enc port map(in_16,out_4);
	--OR_ARRAY_8x3_Enc_4_test  : OR_ARRAY_8x3_Enc port map(in_8,out_3);
	--------------------------------------------------------------------------------

		--DEC_4_test       : DEC_generic generic map (width)port map (DEC_addr,dec_out);
		--MUX_4_test       : MUX_generic generic map (4,3)port map (mux_input,selector,mux_out);
		--REG_f_rst_4_test : REG_generic_f_rst generic map (width,'1')port map (clk,rst,f_rst,rst_value,en,reg_in,reg_f_rst_out);
		--REG_4_test       : REG_generic generic map (width,'1')port map (clk,rst,rst_value,en,reg_in,reg_out);
		--SISO_4_test      : SISO_rl_shift_reg_generic generic map (width)port map (clk,en,sft_r_l,serial_in,load_en,load_d,SISO_out);
		--SIPO_4_test      : SIPO_rl_shift_reg_generic generic map (width)port map (clk,en,sft_r_l,serial_in,load_en,load_d,SIPO_out);
		--SI_SPO_4_test    : SI_SPO_rl_shift_reg_generic generic map (width)port map (clk,en,sft_r_l,serial_in,load_en,load_d,SI_SPO_S_out,SI_SPO_P_out);
		--FIFO_4_test      : FIFO_generic generic map (width,4,3,1)port map (clk,rst,FIFO_w,FIFO_in,FIFO_AF,FIFO_full,FIFO_r,FIFO_out,FIFO_AE,FIFO_empty);
		--incr_4_test      : incr_generic generic map (width)port map (incr_in,incr_over_flow,incr_out);
		--decr_4_test      : decr_generic generic map (width)port map (decr_in,decr_zero,decr_out);
		--RAM_4_test       : RAM_dual_R generic map (width,depth)port map (clk,rst,en,RAM_w_addr,RAM_w_data,RAM_r1_addr,RAM_r2_addr,RAM_r1_data,RAM_r2_data);
		--latch_4_test       : latch port map (en,w_en,rst);
		--latch_R_4_test       : latch_row generic map (width)port map (en,w_en,RAM_w_data);
		--latch_A_4_test       : SRAM_latch_array generic map (width,depth)port map (clk,RAM_w_addr,en,w_en,RAM_w_data);
		--cell          : SRAM_cell port map (w_l,b_l_vec(0));
		--cell2         : SRAM_cell port map (w_l,b_l_vec(1));
		cell_A_4_test : SRAM_cell_array generic map (width,depth)port map (clk,RAM_w_addr,en,w_en,r_en,RAM_w_data,RAM_r1_data);

	run_proc : process
	begin
		wait for wait_p;
		rst <= '1';
		wait for wait_p;
		rst <= '0';
		wait for wait_p;
		en <= '1';
		wait for wait_p;
		en <= '0';
		wait for wait_p;
		en <= '1';
		wait for wait_p;
		en <= '1';
		wait for wait_p;
		en <= '0';
		w_en <= '0';
		wait for wait_p;
		w_en <= '1';
		rand_load <= "11001010";
		wait for wait_p;
		w_en <= '0';
		wait for wait_p;
		en <= '1';
		wait for wait_p;


		wait for 2*wait_p;wait for 2*wait_p;wait for 2*wait_p;

		RAM_w_data <= "10000001";
		FOR_PREP : for i in depth-1 downto 0 loop
			RAM_w_addr <= std_logic_vector(to_unsigned(i,log2ceil(depth)));
			en         <= '1';
			w_en       <= '1';
			wait for wait_p;
		end loop FOR_PREP;

		RAM_w_addr <= (others => '0');
		RAM_w_data <= (others => '0');
		--en         <= '0';
		w_en <= '0';
		wait for wait_p;
		wait for wait_p;
		RAM_w_addr <= "10";

		wait for wait_p;
		en   <= '1';
		r_en <= '1';
		wait for wait_p;
		--en   <= '0';
		r_en <= '0';

		wait for wait_p;
		w_en <= '1';
		--en         <= '1';
		RAM_w_data <= "10011001";
		wait for wait_p;
		w_en <= '0';
		--en   <= '0';
		wait for wait_p;
		--en   <= '1';
		r_en <= '1';
		wait for wait_p;
		--en   <= '0';
		r_en <= '0';
		wait for wait_p;
		FOR_READ : for i in depth-1 downto 0 loop
			RAM_w_addr <= std_logic_vector(to_unsigned(i,log2ceil(depth)));
			wait for wait_p;
			en   <= '1';
			r_en <= '1';
			wait for wait_p;
			--en   <= '0';
			r_en <= '0';

		end loop FOR_READ;
		wait;

	end process run_proc;

--
end amshal_misc_tb_sim;

--run_proc : process
--	begin
--		RAM_w_addr <= (others => '0');
--		RAM_w_data <= (others => '0');
--		en         <= '0';
--		w_en       <= '0';
--		wait for wait_p;
--		wait for wait_p; --20 ns
--		RAM_w_addr <= "11";
--		RAM_w_data <= "10100101";
--		wait for wait_p; -- 30 ns
--		en <= '1';
--		wait for wait_p; 
--		wait for wait_p; --50
--		w_en <= '1';
--		en   <= '0';
--		wait for wait_p;
--		en <= '1';
--		wait for wait_p;
--		--RAM_w_addr <= "00";

--		w_en <= '1';
--		wait for wait_p;
--		en <= '1';
--		en   <= '1';
--		wait for wait_p;
--		en <= '0';
--		w_en <= '0';

--		wait for wait_p;
--		en         <= '1';
--		w_en       <= '0';
--		RAM_w_addr <= "00";
--		RAM_w_data <= "11110101";
--		wait for wait_p;
--		en <= '0';
--		--en <= '1';
--		wait;
--	end process run_proc;