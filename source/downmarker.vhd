LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
USE work.budpack.ALL;

ENTITY down_marker IS
  PORT(
    clk          : IN  std_logic;
    reset        : IN  std_logic;
    start        : IN  std_logic;
    probe_in     : IN  tree_probe;
    reqsize      : IN  std_logic_vector(31 DOWNTO 0);
    probe_out    : OUT tree_probe;
    done_bit     : OUT std_logic;
    ram_we       : OUT std_logic;
    ram_addr     : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_in  : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_out : IN  std_logic_vector(31 DOWNTO 0)
    );
END ENTITY down_marker;

ARCHITECTURE synth_dmark OF down_marker IS

  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;

  TYPE StateType IS (idle, prep, computing, reading, marking, writing, done);
  SIGNAL state, nstate : StateType;

  SIGNAL top_node_size     : std_logic_vector(31 DOWNTO 0);
  SIGNAL log2top_node_size : std_logic_vector(6 DOWNTO 0);
  SIGNAL group_addr        : std_logic_vector(31 DOWNTO 0);
  SIGNAL mtree             : std_logic_vector(31 DOWNTO 0);
  SIGNAL cur               : tree_probe;
  SIGNAL gen               : tree_probe;
  SIGNAL gen_direction     : std_logic;
  SIGNAL direction         : std_logic;  -- DOWN = 0, UP = 1 
  SIGNAL size_left         : std_logic_vector(31 DOWNTO 0);
BEGIN

  p0 : PROCESS(state, start, size_left)
  BEGIN

    nstate   <= idle;
    done_bit <= '0';

    CASE state IS
      WHEN idle =>
        nstate <= idle;
        IF start = '1' THEN
          nstate <= prep;
        END IF;
      WHEN computing => nstate <= reading;
      WHEN reading   => nstate <= marking;
      WHEN marking   => nstate <= writing;
      WHEN writing =>
        nstate <= computing;
        IF to_integer(usgn(size_left)) = 0 THEN
          nstate <= done;
        END IF;
      WHEN done =>
        nstate   <= idle;
        done_bit <= '1';
      WHEN OTHERS => NULL;
    END CASE;
    
  END PROCESS;

  p1 : PROCESS
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;
    END IF;  -- not resetting

  END PROCESS;


END ARCHITECTURE;