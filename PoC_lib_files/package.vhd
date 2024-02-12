
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
 use ieee.math_real.all;
 use std.textio.all;
 use ieee.std_logic_misc.all;

library PoC;
use         PoC.utils.all;
use         PoC.vectors.all;

package type_def_pack is
      constant CACHE_LINES: positive := 64;
      constant ASSOCIATIVITY: positive := 1;
      constant CACHE_SETS: positive := CACHE_LINES / ASSOCIATIVITY; 
      constant ADDRESS_BITS: positive := 10; -- = MEM_ADDR_BITS
      constant INDEX_BITS: positive := log2ceilnz(CACHE_SETS);
      constant TAG_BITS: positive := ADDRESS_BITS - INDEX_BITS;
      constant WAY_BITS: positive := log2ceilnz(ASSOCIATIVITY);
      constant CPU_DATA_BITS: positive := 32;
      constant MEM_DATA_BITS: positive := 128; -- 16-Byte Cache line size
      constant ALL_ONES: std_logic_vector(ASSOCIATIVITY-1 downto 0) := (others => '1');
      constant ALL_ZEROS: std_logic_vector(ASSOCIATIVITY-1 downto 0) := (others => '0');
      constant CPU_DATA_ALL_ZEROS: std_logic_vector(CPU_DATA_BITS-1 downto 0) := (others => '0');
      constant CPU_WIDE_DATA_ALL_ZEROS: std_logic_vector(MEM_DATA_BITS-1 downto 0) := (others => '0');
      constant MEM_DATA_ALL_ZEROS: std_logic_vector(MEM_DATA_BITS-1 downto 0) := (others => '0');

      type T_FSM is (READY, ACCESS_MEM, READING_MEM, UNKNOWN);

      type LINE_TYPE is array(CACHE_SETS-1 downto 0) of std_logic_vector(TAG_BITS-1 downto 0);
      type LINE_TYPE_2 is array(CACHE_SETS-1 downto 0) of std_logic;

      --type WAY_TYPE is array(ASSOCIATIVITY-1 downto 0) of LINE_TYPE;
      --type WAY_TYPE_2 is array(ASSOCIATIVITY-1 downto 0) of LINE_TYPE_2;

      subtype T_TAG_LINE is std_logic_vector(TAG_BITS - 1 downto 0);
      type T_TAG_LINE_VECTOR is array (CACHE_LINES-1 downto 0) of T_TAG_LINE;

      --subtype T_TAG_LINE_2 is std_logic_vector(TAG_BITS - 1 downto 0);
      --type T_TAG_LINE_VECTOR_2 is array (ASSOCIATIVITY-1 downto 0) of T_TAG_LINE;

end type_def_pack;
