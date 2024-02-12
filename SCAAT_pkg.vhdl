--------------------------------------------------------------------------------
--
-- Title		: SCAAT_pkg.vhdl
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


package SCAAT_pkg is
	--- taken from PoC utils.vhdl -- https://github.com/VLSI-EDA/PoC/blob/master/src/common/utils.vhdl
	function log2ceil(arg : positive) return natural;
	---	AMSHAL
	constant LFSRSEED : std_logic_vector(31 downto 0) := "10011101001100100101100111100011";
	--	LFSR polynomials
	type TapsArrayType is array(2 to 32) of std_logic_vector(31 downto 0);
	--	Taps are used to identify the location of XOR gates as well as used as seed for the initializing the LFSR
	constant TapsArray : TapsArrayType := (
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
	--	calculate the demintions of the 2D array according to size of address
	function XYdem(arg : positive) return natural;
	function mod2(arg  : natural) return boolean;
	function CAM_enc_num(arg  : natural) return natural;
	-- array for generic MUX
	type gen_mux_array is array (natural range <>,natural range <>) of std_logic;

end package SCAAT_pkg;
-- Package Body Section
package body SCAAT_pkg is
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
	function CAM_enc_num(arg  : natural) return natural is
		variable cam_num : natural;
	begin

		if (arg < 32) or (arg = 32) then
			cam_num := 1;
		else
			cam_num := arg / 32;
		end if;
		return cam_num;
	end function;
end package body SCAAT_pkg;
