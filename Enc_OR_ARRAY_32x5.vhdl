
--------------------------------------------------------------------------------
--
-- Title		: 
-- Project		: SCAAT
-- Design 		: SCAAT CAM
-- Author		: Ameer Shalabi
-- Date			: 14/10/2020
-- Institution	: Tallinn University of Technology
--------------------------------------------------------------------------------
--
-- Description
-- 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions

use work.SCAAT_pkg.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;



entity OR_ARRAY_8x3_Enc is
	port (
		in_32 : in  std_logic_vector (31 downto 0);
		out_5 : out std_logic_vector (4 downto 0)
	);
end OR_ARRAY_8x3_Enc;

--75 OR gates required

architecture OR_ARRAY_8x3_Enc_arch of OR_ARRAY_8x3_Enc is
	type OR_place is array (4 downto 0, 15 downto 0) of integer;
	signal OR_gates : OR_place ;

	type OR_vector is array (4 downto 0) of std_logic_vector(7 downto 0);
	signal OR_vectors : OR_vector ;

	constant OR_gates_init : OR_place := (
			(31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16),
			(31, 30, 29, 28, 27, 26, 25, 24, 15, 14, 13, 12, 11, 10, 9, 8),
			(31, 30, 29, 28, 23, 22, 21, 20, 15, 14, 13, 12, 7, 6, 5, 4),
			(31, 30, 27, 26, 23, 22, 19, 18, 15, 14, 11, 10, 7, 6, 3, 2),
			(31, 29, 27, 25, 23, 21, 19, 17, 15, 13, 11, 9, 7, 5, 3, 1)
		);

	signal input_sig  : std_logic_vector (31 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (4 downto 0);     -- signal for output
begin
	input_sig <= in_32;
	OR_gates  <= OR_gates_init;

	GEN_OUT_SIGNAL : for array_index in 4 downto 0 generate
		FOR_GEN_GATES : for array_element in 15 downto 0 generate
			IF_GEN_vectors : if (array_element mod 2 = 0) generate
				OR_vectors(array_index)(((array_element)/2)) <= input_sig(OR_gates(array_index,array_element)) or input_sig(OR_gates(array_index,array_element+1));
			end generate IF_GEN_vectors;
		end generate FOR_GEN_GATES;
	end generate GEN_OUT_SIGNAL;

	output_sig(0) <= OR_vectors(0)(1);
	output_sig(1) <= OR_vectors(1)(1);
	output_sig(2) <= OR_vectors(2)(1);
	output_sig(3) <= OR_vectors(2)(1);
	output_sig(4) <= OR_vectors(4)(1);

	--process (input_sig)
	--begin
	--output_sig(4) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(27) or input_sig(26) or input_sig(25) or input_sig(24) or input_sig(23) or input_sig(22) or input_sig(21) or input_sig(20) or input_sig(19) or input_sig(18) or input_sig(17) or input_sig(16);
	--output_sig(3) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(27) or input_sig(26) or input_sig(25) or input_sig(24) or input_sig(15) or input_sig(14) or input_sig(13) or input_sig(12) or input_sig(11) or input_sig(10) or input_sig(9) or input_sig(8);
	--output_sig(2) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(23) or input_sig(22) or input_sig(21) or input_sig(20) or input_sig(15) or input_sig(14) or input_sig(13) or input_sig(12) or input_sig(7) or input_sig(6) or input_sig(5) or input_sig(4);
	--output_sig(1) <= input_sig(31) or input_sig(30) or input_sig(27) or input_sig(26) or input_sig(23) or input_sig(22) or input_sig(19) or input_sig(18) or input_sig(15) or input_sig(14) or input_sig(11) or input_sig(10) or input_sig(7) or input_sig(6) or input_sig(3) or input_sig(2);
	--output_sig(0) <= input_sig(31) or input_sig(29) or input_sig(27) or input_sig(25) or input_sig(23) or input_sig(21) or input_sig(19) or input_sig(17) or input_sig(15) or input_sig(13) or input_sig(11) or input_sig(9) or input_sig(7) or input_sig(5) or input_sig(3) or input_sig(1);
	--end process;
	out_5 <= output_sig;
end OR_ARRAY_8x3_Enc_arch;