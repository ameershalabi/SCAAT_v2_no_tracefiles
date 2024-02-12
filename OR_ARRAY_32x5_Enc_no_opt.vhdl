
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
	signal input_sig : std_logic_vector (31 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (4 downto 0); -- signal for output
begin
	input_sig <= in_32;

	process (input_sig)
	begin
		output_sig(4) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(27) or input_sig(26) or input_sig(25) or input_sig(24) or input_sig(23) or input_sig(22) or input_sig(21) or input_sig(20) or input_sig(19) or input_sig(18) or input_sig(17) or input_sig(16);
		output_sig(3) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(27) or input_sig(26) or input_sig(25) or input_sig(24) or input_sig(15) or input_sig(14) or input_sig(13) or input_sig(12) or input_sig(11) or input_sig(10) or input_sig(9) or input_sig(8);
		output_sig(2) <= input_sig(31) or input_sig(30) or input_sig(29) or input_sig(28) or input_sig(23) or input_sig(22) or input_sig(21) or input_sig(20) or input_sig(15) or input_sig(14) or input_sig(13) or input_sig(12) or input_sig(7) or input_sig(6) or input_sig(5) or input_sig(4);
		output_sig(1) <= input_sig(31) or input_sig(30) or input_sig(27) or input_sig(26) or input_sig(23) or input_sig(22) or input_sig(19) or input_sig(18) or input_sig(15) or input_sig(14) or input_sig(11) or input_sig(10) or input_sig(7) or input_sig(6) or input_sig(3) or input_sig(2);
		output_sig(0) <= input_sig(31) or input_sig(29) or input_sig(27) or input_sig(25) or input_sig(23) or input_sig(21) or input_sig(19) or input_sig(17) or input_sig(15) or input_sig(13) or input_sig(11) or input_sig(9) or input_sig(7) or input_sig(5) or input_sig(3) or input_sig(1);
	end process;
	out_5 	<= output_sig; 
end OR_ARRAY_8x3_Enc_arch;