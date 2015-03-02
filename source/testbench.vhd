LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
use work.tb_data.all;

ENTITY tb IS
END ENTITY tb;

ARCHITECTURE behav OF tb IS


  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;

type statetype is (idle, s0, s1, s2, done);
signal state,nstate : statetype;

  SIGNAL clk, reset, start, command, done_bit : std_logic;
  SIGNAL size                             : std_logic_vector(31 DOWNTO 0);
  SIGNAL address                          : std_logic_vector(31 DOWNTO 0);
  SIGNAL saddr                            : std_logic_vector(31 DOWNTO 0);

  SIGNAL CtrCounter : integer := 0;
  signal reqcount : integer := 0;
  signal req_index :integer;

BEGIN
  Buddy_Allocator : ENTITY rbuddy_top
    PORT MAP(
      clk         => clk,
      reset       => reset,
      start       => start,
      cmd         => command,
      size        => size,
      free_addr   => address,
      malloc_addr => saddr,
	  done => done_bit
	  );

  p1_clkgen : PROCESS
  BEGIN
    clk <= '0';
    WAIT FOR 50 ns;
    clk <= '1';
    WAIT FOR 50 ns;
  END PROCESS p1_clkgen;
  
  p0: process(state,done_bit,reqcount)
  begin
	nstate <= idle;
	
	case state is 
	when idle => nstate <= s0;
	when s0 => nstate <= s1; -- send req
	when s1 => nstate <= s1;
	if done_bit = '1' then 
	nstate <= s2;
	if reqcount = 7 then 
	nstate <= done;	
	end if;
	end if;
	when s2 => nstate <= s0;
	when done => nstate <= done;
	when others => null;
	end case;
end process;
  reset_process : PROCESS
  BEGIN

    WAIT UNTIL clk'event AND clk = '1';

    CtrCounter <= CtrCounter + 1;
    start      <= '0';

	state <= nstate;
	
	if state = s0 then 
		req_index <= data(reqcount).req_index;
		start <= '1';
		command <= data(reqcount).command;
		size <= slv(to_unsigned(data(reqcount).size,size'length));
		address <= slv(to_unsigned(data(reqcount).address,address'length));
	end if;
	
	if state = s2 then 
	
	reqcount <= reqcount + 1;
	
	end if;

  END PROCESS;

END ARCHITECTURE;
