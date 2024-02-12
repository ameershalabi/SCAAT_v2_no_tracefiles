--------------------------------------------------------------------------------
-- Title       : A simple FSM example
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : FSM_eg.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Wed Jan 27 14:55:10 2021
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: An FSM sample
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity FSM_eg is
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
end entity FSM_eg;

architecture arch of FSM_eg is

	type FSM_state is (start, st1, st2); -- st3, st4, etc .. other states
	signal curState : FSM_state;
	signal nexState : FSM_state;

	signal o0  : std_logic;
	signal oNN : std_logic;

begin
	-- sequantial logic
	clk_rst_proc : process (clk, rst)
	begin
		if ( rst = '1') then
			-- if reset, return to the start state
			curState <= start;
		elsif clk'event and clk = '1' then
			-- if not reset, and rising edge of clk, 
			-- assign the next state to the current state
			curState <= nexState;
		end if;
	end process clk_rst_proc;

	-- control logic (combinational)
	control_logic : process (curState, in0, inN)
	begin
		case (curState) is
			when start =>
				o0       <= '1';
				oNN      <= NOT o0;
				nexState <= st1;
			when st1 =>
				o0       <= in0 or inN;
				oNN      <= in0 nand inN;
				nexState <= st2;
			when others =>
				o0       <= in0 and inN;
				oNN      <= o0;
				nexState <= start;
		end case;
	end process control_logic;

	out0 <= o0;
	outN <= oNN;
end architecture arch;

