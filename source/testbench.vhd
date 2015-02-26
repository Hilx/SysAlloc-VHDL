LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY tb IS
END ENTITY tb;

ARCHITECTURE behav OF tb IS

  SIGNAL clk, reset, start, command, done : std_logic;
  SIGNAL size                             : std_logic_vector(31 DOWNTO 0);
  SIGNAL address                          : std_logic_vector(31 DOWNTO 0);
  SIGNAL saddr                            : std_logic_vector(31 DOWNTO 0);

  SIGNAL CtrCounter : integer := 0;

BEGIN
  Buddy_Allocator : ENTITY rbuddy_top
    PORT MAP(
      clk         => clk,
      reset       => reset,
      start       => start,
      cmd         => command,
      size        => size,
      free_addr   => address,
      malloc_addr => saddr);

  p1_clkgen : PROCESS
  BEGIN
    clk <= '0';
    WAIT FOR 50 ns;
    clk <= '1';
    WAIT FOR 50 ns;
  END PROCESS p1_clkgen;

  reset_process : PROCESS
  BEGIN

    WAIT UNTIL clk'event AND clk = '1';

    CtrCounter <= CtrCounter + 1;
    start      <= '0';
    reset      <= '1';

    IF CtrCounter = 0 THEN
      reset <= '0';
    END IF;

    IF CtrCounter = 2 THEN
      start   <= '1';
      size    <= std_logic_vector(to_unsigned(2, size'length));
      command <= '0';
    END IF;




  END PROCESS;

END ARCHITECTURE;
