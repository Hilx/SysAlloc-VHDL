LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
USE work.budpack.ALL;

ENTITY up_marker IS
  PORT(
    clk          : IN  std_logic;
    reset        : IN  std_logic;
    start        : IN  std_logic;
    probe_in     : IN  tree_probe;
    node_in      : IN  std_logic_vector(1 DOWNTO 0);
    done_bit     : OUT std_logic;
    ram_we       : OUT std_logic;
    ram_addr     : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_in  : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_out : IN  std_logic_vector(31 DOWNTO 0)
    );
END ENTITY up_marker;

ARCHITECTURE synth_umark OF up_marker IS

  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;

  TYPE StateType IS (idle, prep, s0, s_read, s_compare, s_w0, s_w1, done);
  SIGNAL state, nstate : StateType;

  SIGNAL cur, gen   : tree_probe;
  SIGNAL group_addr : std_logic_vector(31 DOWNTO 0);
BEGIN

  p0 : PROCESS(state, start)
  BEGIN

    nstate <= idle;

    CASE state IS
      WHEN idle =>
        nstate <= idle;
        IF start = '1' THEN
          nstate <= prep;
        END IF;
      WHEN prep      => nstate <= s0;
      WHEN s0        => nstate <= s_read;
      WHEN s_read    => nstate <= s_compare;
      WHEN s_compare => nstate <= s_w0;
      WHEN s_w0      => nstate <= s_w1;
      WHEN s_w1      => nstate <= s0;
      WHEN done      => nstate <= idle;
      WHEN OTHERS    => NULL;
    END CASE;
    
  END PROCESS;

  p1 : PROCESS
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    state <= nstate;

    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE

      IF state = prep THEN

        cur <= probe_in;
      END IF;

      IF state = s0 THEN
        gen.verti   <= slv(usgn(cur.verti) - 1);
        gen.horiz   <= slv(usgn(cur.horiz) SRL 3);  -- input.horiz/8
        -- output row base = input row base - 2^(output row base - 1)
        -- output row base = input row base - 2^(input row base - 2)
        gen.rowbase <= slv(usgn(cur.rowbase) - (to_unsigned(1, gen.rowbase'length) SLL to_integer(3 * usgn(cur.verti - 2))));
        group_addr  <= slv(usgn(cur.rowbase)) + (usgn(cur.horiz)SRL 3));
      END IF;

    END IF;
    
  END IF;

END ARCHITECTURE;
