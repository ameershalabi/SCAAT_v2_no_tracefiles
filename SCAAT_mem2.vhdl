library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.SCAAT_pkg.all;

entity SCAAT_mem2 is
 	generic(	
 	memDim        		: positive	:= 6; --index bits
 	tag_bits        	: positive	:= 6;
 	addr_len 			: positive 	:= 12
 	);

	port (
	clk		: in  std_logic; -- clk
	rst		: in  std_logic; -- reset
	enable_w		: in  std_logic; -- write enable
	cpu_addr	: in  unsigned(addr_len-1 downto 0); -- address location in memeory
	datain		: in  unsigned(memDim downto 0); -- data in
	dataout		: out unsigned(memDim downto 0) -- data out
	);

end entity SCAAT_mem2;

architecture SCAAT_mem2_RTL of SCAAT_mem2 is
	--	TYPES
	--	create the memory 2D array according to the length of the address
	constant offset: positive := addr_len - (tag_bits+memDim);
	--type SCAAT is array (XYdem(tag_bits) - 1 downto 0, XYdem(tag_bits) - 1 downto 0) of unsigned(memDim downto 0);
	type SCAAT is array ((2**tag_bits) - 1 downto 0) of unsigned(memDim downto 0);
	signal addr_index: unsigned (memDim -1 downto 0);
	signal addr_tag: unsigned (tag_bits -1 downto 0);
	signal addr_store: unsigned (addr_len downto 0);
	--	SIGNALS
	--	create the access signal to the array
	signal SCAATacss : SCAAT;
	--signal tblX, tblY  : integer range 0 to XYdem(tag_bits) - 1;
	signal location  : integer range 0 to 2**tag_bits - 1;
	
begin
	--	assign the memeory location
	addr_index <= cpu_addr(offset+memDim-1 downto offset);
	addr_tag <= cpu_addr(addr_len -1 downto offset+memDim);
	--tblX <= to_integer(addr_tag((tag_bits/2)-1 downto 0));
	--tblY <= to_integer(addr_tag(tag_bits-1 downto (tag_bits/2)));
	location <= to_integer(addr_tag);
	--addr_store <= datain(addr_len downto tag_bits);
	--addr_store(tag_bits -1 downto 0) <= addr_index;
	mem_proc: process(clk) is
	begin
		--	check at the falling edge of the clk,
		if falling_edge(clk) then ---switch wit the if of the rst
			--	if a reset, all the locations are initialized to 0s
			if rst = '1' then
				--SCAATacss <= (others=>(others=>(others=>'0')));
				SCAATacss <= (others=>(others=>'0'));
			--	if a write enable, the input is stored in the XY memeory location
			elsif enable_w = '1' then
				--SCAATacss(tblX,tblY) <= datain;
				SCAATacss(location) <= datain;
			end if;
		end if;
	end process mem_proc;
	--	the address in XY location is always output
	--dataout <= SCAATacss(tblX,tblY);
	dataout <= SCAATacss(location);
		
end SCAAT_mem2_RTL;
