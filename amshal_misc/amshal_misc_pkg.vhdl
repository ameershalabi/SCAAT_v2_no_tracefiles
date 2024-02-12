
--------------------------------------------------------------------------------
--
-- Title		: amshal_misc_pkg.vhdl
-- Project		: SCAAT
-- Design 		: SCAAT package
-- Author		: Ameer Shalabi
-- Date			: --/--/2020
-- Institution	: Tallinn University of Technology
--------------------------------------------------------------------------------
--
-- Description
-- This is a package that contains functions, constants, and arrays used in the
-- simulation and synthsis of the SCAAT mitigation system.
--------------------------------------------------------------------------------

-- Package Declaration Section
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package amshal_misc_pkg is
	---	AMSHAL
	constant LFSRSEED : std_logic_vector(31 downto 0) := "10011101001100100101100111100011";
	--	LFSR polynomials
	type XOR_placment_Type is array(2 to 32) of std_logic_vector(31 downto 0);
	--	Taps are used to identify the location of XOR gates as well as used as seed for the initializing the LFSR
	constant XOR_placment_ROM : XOR_placment_Type := (
			"00000000000000000000000000000011",
			"00000000000000000000000000000101",
			"00000000000000000000000000001001",
			"00000000000000000000000000010010",
			"00000000000000000000000000100001",
			"00000000000000000000000001000001",
			"00000000000000000000000010001110",
			"00000000000000000000000100001000",
			"00000000000000000000001000000100",
			"00000000000000000000010000000010",
			"00000000000000000000100000101001",
			"00000000000000000001000000001101",
			"00000000000000000010000000010101",
			"00000000000000000100000000000001",
			"00000000000000001000000000010110",
			"00000000000000010000000000000100",
			"00000000000000100000000001000000",
			"00000000000001000000000000010011",
			"00000000000010000000000000000100",
			"00000000000100000000000000000010",
			"00000000001000000000000000000001",
			"00000000010000000000000000010000",
			"00000000100000000000000000001101",
			"00000001000000000000000000000100",
			"00000010000000000000000000100011",
			"00000100000000000000000000010011",
			"00001000000000000000000000000100",
			"00010000000000000000000000000010",
			"00100000000000000000000000101001",
			"01000000000000000000000000000100",
			"10000000000000000000000001100010"
		);

	type gen_mux_array is array (natural range <>,natural range <>) of std_logic;
	function log2ceil( arg                     : positive) return natural;
	function xlog2( arg                        : positive) return natural;
	function XYdem( arg                        : positive) return natural;
	function mod2( arg                         : natural) return boolean;
	function CAM_enc_num( arg                  : natural) return natural;
	function nearest_power_of_2( arg           : natural) return natural;
	function has_undefined( arg                : unsigned) return boolean;
	function std_logic_2_int( arg              : std_logic) return integer;
	function TF_2_10( arg                      : boolean) return std_logic;
	function b10_2_TF( arg                     : std_logic) return boolean;
	function char_2_INT( arg                   : character) return integer;
	impure function rand_gen_vec( vector_width : integer) return std_logic_vector;
	-- array for generic MUX

	--------------------------------------------------------------------------------
	-- Component declarations
	--------------------------------------------------------------------------------
	component OR_ARRAY_32x5_Enc is
		port (
			in_32 : in  std_logic_vector (31 downto 0);
			out_5 : out std_logic_vector (4 downto 0)
		);
	end component OR_ARRAY_32x5_Enc;

	component OR_ARRAY_16x4_Enc is
		port (
			in_16 : in  std_logic_vector (15 downto 0);
			out_4 : out std_logic_vector (3 downto 0)
		);
	end component OR_ARRAY_16x4_Enc;

	component OR_ARRAY_8x3_Enc is
		port (
			in_8  : in  std_logic_vector (7 downto 0);
			out_3 : out std_logic_vector (2 downto 0)
		);
	end component OR_ARRAY_8x3_Enc;

	component DEC_generic is
		generic (
			addr_width : natural := 4
		);
		port (
			addr    : in  unsigned(addr_width-1 downto 0);
			dec_out : out std_logic_vector((2**addr_width)-1 downto 0)
		);
	end component DEC_generic;

	component MUX_generic is
		generic (
			len_inputs : natural := 5;
			num_inputs : natural := 4
		);
		port (
			inputs_array : in  gen_mux_array(0 to num_inputs-1,len_inputs-1 downto 0);
			sel          : in  natural range num_inputs-1 downto 0;
			mux_out      : out std_logic_vector(len_inputs-1 downto 0)
		);
	end component MUX_generic;

	component incr_generic is
		generic (
			incr_LENGTH : natural := 10
		);
		port (
			data_in  : in  std_logic_vector(incr_LENGTH-1 downto 0);
			overFlow : out std_logic;
			data_out : out std_logic_vector (incr_LENGTH-1 downto 0)
		);
	end component incr_generic;

	component decr_generic is
		generic (
			decr_LENGTH : natural := 10
		);
		port (
			data_in  : in  std_logic_vector(decr_LENGTH-1 downto 0);
			zero     : out std_logic;
			data_out : out std_logic_vector (decr_LENGTH-1 downto 0)
		);
	end component decr_generic;

	component en_and is
		generic (
			en_width : natural := 4
		);
		port (
			en   : in  std_logic;
			en_i : in  std_logic_vector(en_width-1 downto 0);
			en_o : out std_logic_vector(en_width-1 downto 0)
		);
	end component en_and;
	--------------------------------------------------------------------------------
	-- REGISTER 
	--------------------------------------------------------------------------------

	component LFSR_RAND is
		generic(addr_len : natural := 12); -- length of pseudo-random sequence
		port (
			clk      : in  std_logic;
			rst      : in  std_logic;
			gen_e    : in  std_logic;
			rand_out : out std_logic_vector(addr_len-1 downto 0) -- parallel data out
		);
	end component LFSR_RAND;

	component LFSR_generic is
		generic(LFSR_len : natural := 12);
		port (
			clk       : in  std_logic;
			rst       : in  std_logic;
			load      : in  std_logic;
			load_data : in  std_logic_vector(LFSR_len-1 downto 0);
			gen_e     : in  std_logic;
			LFSR_out  : out std_logic_vector(LFSR_len-1 downto 0)
		);

	end component LFSR_generic;

	component counter_generic is
		generic (
			counter_len : natural := 4
		);
		port (
			clk       : in  std_logic;
			rst       : in  std_logic;
			em        : in  std_logic;
			enable    : in  std_logic;
			count_out : out std_logic_vector (counter_len-1 downto 0)
		);
	end component counter_generic;

	component REG_generic_f_rst is
		generic (
			reg_width        : natural   := 4;
			clk_edge_trigger : std_logic := '1'
		);
		port (
			clk       : in  std_logic;
			rst       : in  std_logic;
			f_rst     : in  std_logic;
			rst_value : in  std_logic_vector(reg_width-1 downto 0);
			en_load   : in  std_logic;
			reg_in    : in  std_logic_vector(reg_width-1 downto 0);
			reg_out   : out std_logic_vector(reg_width-1 downto 0)
		);
	end component REG_generic_f_rst;

	component REG_generic is
		generic (
			reg_width        : natural   := 5;
			clk_edge_trigger : std_logic := '1'
		-- 0 is falling edge, 1 is rising edge1
		);
		port (
			clk       : in  std_logic;
			rst       : in  std_logic;
			rst_value : in  std_logic_vector(reg_width-1 downto 0);
			en_load   : in  std_logic;
			reg_in    : in  std_logic_vector(reg_width-1 downto 0);
			reg_out   : out std_logic_vector(reg_width-1 downto 0)
		);
	end component REG_generic;

	component SISO_rl_shift_reg_generic is
		generic (
			SISO_len : natural := 8
		);
		port(
			clk     : in std_logic;
			en      : in std_logic;
			sft_r_l : in std_logic; -- 0 = right / 1 = left
			                        --  0 1 2 3 ... MSB
			                        --  -- right ----> 
			                        --  <---- left --
			serial_in  : in  std_logic;
			load_en    : in  std_logic;
			load_d     : in  std_logic_vector(SISO_len-1 downto 0);
			serial_out : out std_logic
		);
	end component SISO_rl_shift_reg_generic;

	component SIPO_rl_shift_reg_generic is
		generic (
			SIPO_len : natural := 8
		);
		port(
			clk     : in std_logic;
			en      : in std_logic;
			sft_r_l : in std_logic; -- 0 = right / 1 = left
			                        --  0 1 2 3 ... MSB
			                        --  -- right ----> 
			                        --  <---- left --
			serial_in    : in  std_logic;
			load_en      : in  std_logic;
			load_d       : in  std_logic_vector(SIPO_len-1 downto 0);
			Parallel_out : out std_logic_vector(SIPO_len-1 downto 0)
		);
	end component SIPO_rl_shift_reg_generic;

	component SI_SPO_rl_shift_reg_generic is
		generic (
			SI_SPO_len : natural := 8
		);
		port(
			clk     : in std_logic;
			en      : in std_logic;
			sft_r_l : in std_logic; -- 0 = right / 1 = left
			                        --  0 1 2 3 ... MSB
			                        --  -- right ----> 
			                        --  <---- left --
			serial_in    : in  std_logic;
			load_en      : in  std_logic;
			load_d       : in  std_logic_vector(SI_SPO_len-1 downto 0);
			serial_out   : out std_logic;
			Parallel_out : out std_logic_vector(SI_SPO_len-1 downto 0)
		);
	end component SI_SPO_rl_shift_reg_generic;

	--------------------------------------------------------------------------------
	-- REGISTER -- END
	--------------------------------------------------------------------------------

	component FIFO_generic is
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
	end component FIFO_generic;

	component RAM_dual_R is
		generic (
			ram_width : natural := 4;
			ram_depth : natural := 8
		);
		port (
			clk : in std_logic;
			rst : in std_logic;
			-- write port
			w_en   : in std_logic;
			w_addr : in std_logic_vector(ram_depth-1 downto 0);
			w_data : in std_logic_vector(ram_width-1 downto 0);
			-- read ports
			r_addr_1 : in  std_logic_vector(ram_depth-1 downto 0);
			r_addr_2 : in  std_logic_vector(ram_depth-1 downto 0);
			r_data_1 : out std_logic_vector(ram_width-1 downto 0);
			r_data_2 : out std_logic_vector(ram_width-1 downto 0)
		);
	end component RAM_dual_R;
	--------------------------------------------------------------------------------
	-- latches
	--------------------------------------------------------------------------------
	component latch is
		port (
			en : in  std_logic;
			w  : in  std_logic;
			d  : in  std_logic;
			q  : out std_logic
		);
	end component latch;

	component SRAM_cell is
		port (
			w_l  : in    std_logic;
			b_l  : inout std_ulogic;
			nb_l : inout std_ulogic
		);
	end component SRAM_cell;

	component latch_row is
		generic (
			row_width : natural := 4
		);
		port (
			en        : in  std_logic;
			w         : in  std_logic;
			row_d_in  : in  std_logic_vector(row_width-1 downto 0);
			row_d_out : out std_logic_vector(row_width-1 downto 0)
		);
	end component latch_row;

	component SRAM_cell_row is
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
	end component SRAM_cell_row;

	component SRAM_latch_array is
		generic (
			SRAM_width : natural := 8;
			SRAM_depth : natural := 4
		);
		port (
			clk       : in  std_logic;
			addr      : in  std_logic_vector(log2ceil(SRAM_depth)-1 downto 0);
			en        : in  std_logic;
			write_pin : in  std_logic;
			data_in   : in  std_logic_vector(SRAM_width-1 downto 0);
			data_out  : out std_logic_vector(SRAM_width-1 downto 0)
		);
	end component SRAM_latch_array;

	component SRAM_cell_array is
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
	end component SRAM_cell_array;

	component FSM_eg is
		port (
			clk : in std_logic;
			rst : in std_logic;
			in0 : in std_logic;
			inN : in std_logic;
			-- in1, in2, etc ... -- other inputs
			out0 : out std_logic;
			outN : out std_logic
		-- out1, out2, etc ... -- other outputs
		);
	end component FSM_eg;

	component fa is
		port (
			in_a : in std_logic;
			in_b : in std_logic;
			c_in : in std_logic;

			sum   : out std_logic;
			c_out : out std_logic
		);
	end component fa;

	component parallel_fa_generic is
		generic (
			adder_len : natural := 8
		);
		port (
			in_a : in std_logic_vector(adder_len-1 downto 0);
			in_b : in std_logic_vector(adder_len-1 downto 0);
			c_in : in std_logic;

			sum      : out std_logic_vector(adder_len-1 downto 0);
			OVERFLOW : out std_logic
		);
	end component parallel_fa_generic;
	--------------------------------------------------------------------------------
	-- Component declarations -- END
	--------------------------------------------------------------------------------

end package amshal_misc_pkg;
-- Package Body Section
package body amshal_misc_pkg is
	--- taken from PoC utils.vhdl -- https://github.com/VLSI-EDA/PoC/blob/master/src/common/utils.vhdl
	function log2ceil(arg : positive) return natural is
		variable tmp : positive;
		variable log : natural;
	begin
		if arg = 1 then return 0; end if;
		tmp := 1;
		log := 0;
		while arg > tmp loop
			tmp := tmp * 2;
			log := log + 1;
		end loop;
		if log < 0 then
			return 0;
		else
			return log;
		end if;
	end function;
	---AMSHAL
	function xlog2(arg : positive) return natural is
		variable tmp : positive;
		variable log : natural;
	begin
		if arg = 1 then return 0; end if;
		tmp := 1;
		log := 0;
		while arg > tmp loop
			tmp := tmp * 2;
			log := log + 1;
		end loop;
		if log < 0 then
			return 0;
		else
			return log;
		end if;
	end function;
	function XYdem(arg : positive) return natural is
		variable dem : integer;
	begin
		dem := 2**(arg/2);
		return dem;
	end function;
	--------------------------------------------------------------------------------
	-- Check if arg modulo 2 is equal to 0, return true. 
	-- else, return false
	--------------------------------------------------------------------------------
	function mod2(arg : natural) return boolean is
		variable mod2_out : boolean;
	begin

		if (arg mod 2 = 0) then
			mod2_out := true;
		else
			mod2_out := false;
		end if;
		return mod2_out;
	end function;
	--------------------------------------------------------------------------------
	-- function to return the number of encoders needed inside the CAM2 modules
	--------------------------------------------------------------------------------
	function CAM_enc_num(arg : natural) return natural is
		variable cam_num : natural;
	begin

		if (arg < 32) or (arg = 32) then
			cam_num := 1;
		else
			cam_num := arg / 32;
		end if;
		return cam_num;
	end function;

	function nearest_power_of_2( arg : natural) return natural is
		variable P_2 : natural;
	begin
		find_power_2 : for i in 1 to 9 loop
			if (arg > 2**i-1) and (arg < 2**i) then
				P_2 := i;
			end if;
		end loop find_power_2;
		return P_2;
	end function;


	function has_undefined( arg : unsigned) return boolean is
	begin
		if (is_x(std_logic_vector(arg)) = true) then
			return true;
		else
			return false;
		end if;
	end function;

	function std_logic_2_int( arg : std_logic) return integer is
	begin
		if ( arg = '1') then
			return 1;
		else
			return 0;
		end if;
	end function;

	function TF_2_10( arg : boolean) return std_logic is
	begin
		if arg then
			return '1';
		else
			return '0';
		end if;
	end function;

	function b10_2_TF( arg : std_logic) return boolean is
	begin
		if arg = '1' then
			return true;
		else
			return false;
		end if;
	end function;

	impure function rand_gen_vec(vector_width : integer) return std_logic_vector is
		variable seed1, seed2 : integer := 999;
		variable gen_rand     : real;
		variable rand_vec     : std_logic_vector(vector_width - 1 downto 0);
	begin
		for i in rand_vec'range loop
			uniform(seed1, seed2, gen_rand);
			if (gen_rand > 0.5) then
				rand_vec(i) := '1';
			else
				rand_vec(i) := '0';
			end if;
		end loop;
		return rand_vec;
	end function;

	function char_2_INT( arg : character) return integer is
		variable int_out : integer := 0;
	begin
		case (arg) is
			when '1' =>
				int_out := 1;
			when '2' =>
				int_out := 2;
			when '3' =>
				int_out := 3;
			when '4' =>
				int_out := 4;
			when '5' =>
				int_out := 5;
			when '6' =>
				int_out := 6;
			when '7' =>
				int_out := 7;
			when '8' =>
				int_out := 8;
			when '9' =>
				int_out := 9;
			when others =>
				int_out := 0;
		end case;
		return int_out;
	end function;

end package body amshal_misc_pkg;
