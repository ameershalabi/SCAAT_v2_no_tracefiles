library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.amshal_misc_pkg.all;

entity en_and is
	generic (
		en_width : natural := 4
	);
	port (
		en   : in  std_logic;
		en_i : in  std_logic_vector(en_width-1 downto 0);
		en_o : out std_logic_vector(en_width-1 downto 0)
	);
end entity en_and;

architecture en_and_arch of en_and is
	signal inn : std_logic_vector(en_width-1 downto 0);
	signal ott : std_logic_vector(en_width-1 downto 0);
begin
	inn <= en_i;

	FOR_GEN_EN : for i in en_width-1 downto 0 generate
		ott(i) <= inn(i) when en = '1' else 'Z';
	end generate FOR_GEN_EN;

	en_o <= ott;
end architecture en_and_arch;