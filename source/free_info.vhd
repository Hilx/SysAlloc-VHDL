LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
USE work.budpack.ALL;

ENTITY free_info IS
  PORT(
    clk       : IN  std_logic;
    reset     : IN  std_logic;
    start     : IN  std_logic;
    probe_out : IN  tree_probe;
    done_bit  : OUT std_logic;
    );
END ENTITY free_info;

ARCHITECTURE synth_free_info OF free_info IS

  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;

  TYPE StateType IS (idle, prep, s0, s_read, s_w0, s_w1, done);
  SIGNAL state, nstate : StateType;

BEGIN

  p0 : PROCESS(state, start)
  BEGIN

    nstate   <= idle;
    done_bit <= '0';

    CASE state IS
      WHEN idle =>
        nstate <= idle;
        IF start = '1' THEN
          nstate <= prep;
        END IF;
      WHEN prep   => nstate <= s0;
      WHEN s0     => nstate <= s_read;
      WHEN s_read => nstate <= s_w0;
      WHEN s_w0   => nstate <= s_w1;
      WHEN s_w1   => nstate <= s0;
      WHEN done   => nstate <= idle;
                     done_bit <= '1';
      WHEN OTHERS => NULL;
    END CASE;
    
  END PROCESS;

  p1 : PROCESS

  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    state <= nstate;

    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE


    END IF;
    
  END PROCESS;



END ARCHITECTURE;
