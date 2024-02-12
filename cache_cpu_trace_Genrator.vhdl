library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use IEEE.std_logic_unsigned.all;

entity cache_cpu_trace_Genrator is
	generic (
		CPU_ADDR_LEN      : positive	:= 32;
        BRAM_ADDR_LEN      : positive    := 14;
        READ_LATENCY     : positive    := 2;
        WRITE_LATENCY      : positive    := 3
	);
	port (
	    clk : in std_logic; -- clock
	    rst : in std_logic; -- reset
	    trace : in unsigned(35 downto 0);
	        --- 36 bits as trace string needed for the generator to work 
	        --- it is obtained from 
	        --- cpu_req     / 1 bit
	        --- cpu_write   / 1 bit
	        --- mem_rdy     / 1 bit
	        --- mem_rstb    / 1 bit
	        --- cpu_addr can not exceed 32-bit addresses since 
	        --- the benchmark traces are of 32bit cahe addresses
	        ---             / 32 bits
	        --- Total is 36 bits or (35 downto 0)
	    
	    cpu_req   : out  std_logic;
	    cpu_write : out  std_logic;
	    cpu_addr  : out  unsigned(CPU_ADDR_LEN-1 downto 0);
		--mem_rdy   : out	std_logic;
		--mem_rstb  : out	std_logic;
		env_en   : out  std_logic;
	    BRAM_addr : out unsigned(BRAM_ADDR_LEN-1 downto 0)
    );
end entity;

architecture rtl of cache_cpu_trace_Genrator is
    signal counter: std_logic_vector(0 to 2);
    signal addr_bram: unsigned(BRAM_ADDR_LEN-1 downto 0);
    signal tracer : unsigned(35 downto 0);
    signal done : std_logic;
    signal cpu_req_sig   :  std_logic;
    signal cpu_write_sig :  std_logic;
    signal cpu_addr_sig  :  unsigned(CPU_ADDR_LEN-1 downto 0);
    --signal mem_rdy_sig   : std_logic;
    --signal mem_rstb_sig  : std_logic;

    begin  -- architecture rtl
    	tracer<=trace;
        Trace_GEN: process(rst,clk,tracer,addr_bram,counter) is
    	begin
    		--SCAAT_env_trace_vector(31 downto 0) <= v_addr_Vector;
      		--SCAAT_env_trace_vector(32) <= cache_req;
      		--SCAAT_env_trace_vector(33) <= cpu_write;
      		--SCAAT_env_trace_vector(34) <= mem1_rdy;
      		--SCAAT_env_trace_vector(35) <= mem1_rstb;
    	   --trace <= "000000000000000000000000000000000000";
    		if rst = '1' then
    			cpu_req_sig		<= '0';
        		cpu_write_sig 	<= '0';
        		cpu_addr_sig	<= (others => '0');
    			--mem_rdy_sig   	<= '0';
    			--mem_rstb_sig 	<= '0';
                counter     <= (others => '0');
                addr_bram   <= (others => '0');
                --;
                done 		<= '0';
    		else
    			cpu_req_sig		<= tracer(32);
        		cpu_write_sig 	<= tracer(33);
        		cpu_addr_sig	<= tracer(CPU_ADDR_LEN-1 downto 0);
    			--mem_rdy_sig   	<= tracer(34);
    			--mem_rstb_sig 	<= tracer(35);
    			if clk'event and rising_edge(clk) then 
                    if (tracer(33) = '0') then -- a read
                    	done <= '0';
                        -- to_unsigned(READ_LATENCY, counter'length);
                        if (counter = "011") then
                            counter     <= (others => '0');
                           	addr_bram <= addr_bram+1;
                            done <= '1';
                        else
                            counter <= counter+1;
                        end if;
                    elsif (tracer(33) = '1') then -- a write
                    	done <= '0';
                        -- to_unsigned(WRITE_LATENCY, counter'length);
                       if (counter = "101") then
                            counter     <= (others => '0');
                            addr_bram <= addr_bram+1;
                            done <= '1';
                        else
                            counter <= counter+1;
                        end if;
                    else
                        done <= '0';
                       if (counter = "010") then
                            counter     <= (others => '0');
                            addr_bram <= addr_bram+1;
                            done <= '1';
                        else
                            counter <= counter+1;
                        end if;
                    end if;
    			end if;
    		end if;
    		if (addr_bram = (2**BRAM_ADDR_LEN)-1) then
                addr_bram   <= (others => '0');
            end if;
    	end process Trace_GEN;
        cpu_req <= cpu_req_sig;
        cpu_write <= cpu_write_sig;
        cpu_addr <= cpu_addr_sig;
        --mem_rdy <= mem_rdy_sig;
        --mem_rstb <= mem_rstb_sig;
    	BRAM_addr <= addr_bram;
    	env_en <= done;
    end architecture rtl;
