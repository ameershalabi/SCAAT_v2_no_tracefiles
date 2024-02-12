
library ieee;
use ieee.std_logic_1164.all;

entity reg_SCAAT_reset is
	generic (
		reg_width : natural := 9
	);
	port (
		clk   : in  std_logic;
		rst   : in  std_logic;
		v_in  : in  std_logic_vector(reg_width-1 downto 0);
		v_out : out std_logic_vector(reg_width-1 downto 0)
	);
end entity reg_SCAAT_reset;

architecture arch of reg_SCAAT_reset is
	signal vector_a      : std_logic_vector(reg_width-1 downto 0);
	signal xor_1st_round : std_logic_vector(reg_width-1 downto 0);
	signal xor_2nd_round : std_logic_vector(reg_width-1 downto 0);
	signal xor_reg       : std_logic_vector(reg_width-1 downto 0);
begin
	vector_a <= v_in;

	IF_GEN_EVEN : if (reg_width mod 2 = 0) generate
		FOR_GEN_XOR_GATES : for xor_gate_even in 0 to reg_width-1 generate
			IF_GEN_EVEN_XOR : if (xor_gate_even mod 2 = 0) generate
				xor_1st_round(xor_gate_even/2)  <= vector_a(xor_gate_even) xor vector_a(xor_gate_even+1);
			end generate IF_GEN_EVEN_XOR;
		end generate FOR_GEN_XOR_GATES;
	end generate IF_GEN_EVEN;

	IF_GEN_ODD : if (reg_width mod 2 /= 0) generate
		xor_1st_round(reg_width-1)  <= vector_a(reg_width-1);
		FOR_GEN_XOR_GATES : for xor_gate_even in 0 to reg_width-2 generate
			IF_GEN_ODD_XOR : if (xor_gate_even mod 2 = 0) generate
				xor_1st_round(xor_gate_even/2)  <= vector_a(xor_gate_even) xor vector_a(xor_gate_even+1);
			end generate IF_GEN_ODD_XOR;
		end generate FOR_GEN_XOR_GATES;
	end generate IF_GEN_ODD;

	FOR_GEN_XOR_GATES2 : for xor_gate_reg in 0 to reg_width-1 generate
			xor_2nd_round(xor_gate_reg)  <= xor_1st_round(xor_gate_reg) xor xor_reg(xor_gate_reg);
	end generate FOR_GEN_XOR_GATES2;

	xor_reg_proc : process (clk, rst)
	begin
		if (rst = '1') then
			xor_reg <= (others => '0');
		elsif rising_edge(clk) then
			xor_reg <= xor_2nd_round;
		end if;
	end process xor_reg_proc;
	
	IF_GEN_V_OUT_EVEN : if (reg_width mod 2 = 0) generate
		FOR_GEN_V_OUT_EVEN : for v_out_bit in 0 to (reg_width/2)-1 generate
			v_out(v_out_bit) <= xor_reg(v_out_bit);
		end generate FOR_GEN_V_OUT_EVEN;
	end generate IF_GEN_V_OUT_EVEN;

	V_OUT_GEN_ODD : if (reg_width mod 2 /= 0) generate
		FOR_GEN_V_OUT_EVEN : for v_out_bit in 0 to ((reg_width+1)/2)-1 generate
			v_out(v_out_bit) <= xor_reg(v_out_bit);
		end generate FOR_GEN_V_OUT_EVEN;
	end generate V_OUT_GEN_ODD;
	--v_out <= xor_reg;

end architecture arch;

