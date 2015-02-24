LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY locator IS
  PORT(
    clk              : IN  std_logic;
    reset            : IN  std_logic;
    start            : IN  std_logic;
    -- inputs
    alvec            : IN  std_logic;   -- allocation vector usage flag
    size             : IN  std_logic_vector(31 DOWNTO 0);
    verti            : IN  std_logic_vector(31 DOWNTO 0);  -- vertical index of group
    horiz            : IN  std_logic_vector(31 DOWNTO 0);  -- horizontal index of group
    node_sel         : IN  std_logic_vector(2 DOWNTO 0);  --  node select (0 to 7)
    node_sel_phy     : IN  std_logic_vector(2 DOWNTO 0);  --  physical version
    saddr            : IN  std_logic_vector(31 DOWNTO 0);  -- starting address of the malloc
    row_base         : IN  std_logic_vector(31 DOWNTO 0);
    direction        : IN  std_logic_vector(31 DOWNTO 0);  -- DOWN = 0, UP = 1
    total_mem_blocks : IN  std_logic_vector(31 DOWNTO 0);
    --outputs 
    verti_out        : OUT std_logic_vector(31 DOWNTO 0);  -- vertical index of group
    horiz_out        : OUT std_logic_vector(31 DOWNTO 0);  -- horizontal index of group
    alvec_out        : OUT std_logic;   -- allocation vector usage flag
    node_sel_out     : OUT std_logic_vector(2 DOWNTO 0);  --  node select (0 to 7)
    node_sel_phy_out : OUT std_logic_vector(2 DOWNTO 0);  --  physical version
    saddr_out        : OUT std_logic_vector(31 DOWNTO 0);  -- starting address of the malloc
    row_base_out     : OUT std_logic_vector(31 DOWNTO 0);
    group_addr       : OUT std_logic_vector(31 DOWNTO 0)

    );
END ENTITY locator;

ARCHITECTURE synth_locator OF locator IS
  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;
  TYPE StateType(idle, s0, s1, s2, done);
  SIGNAL state, nstate : StateType;

  SIGNAL search_status  : std_logic;
  SIGNAL top_node_size  : std_logic_vector(31 DOWNTO 0);
  SIGNAL row_base_out_i : std_logic_vector(31 DOWNTO 0);
  SIGNAL group_addr_i   : std_logic_vector(31 DOWNTO 0);
  SIGNAL mtree          : std_logic_vector(31 DOWNTO 0);
BEGIN

  p0 : PROCESS(state, start)
  BEGIN
    
    nstate <= idle;
    CASE state IS
      WHEN idle =>

        nstate <= idle;
        IF start = '1' THEN
          nstate <= s0;
        END IF;
        
      WHEN s0 => nstate <= s1;
      WHEN s1 => nstate <= s2;
      WHEN s2 =>
        
        nstate <= s0;
        IF search_status = '1' THEN
          nstate <= done;
        END IF;
        
      WHEN done   => nstate <= idle;
      WHEN OTHERS => NULL;
    END CASE;

  END PROCESS;

  p1 : PROCESS
    VARIABLE row_base_var : std_logic_vector(31 DOWNTO 0);
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';
    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;

      IF state = s0 THEN
        top_node_size <= usgn(total_mem_blocks) SRL (3* to_integer(usgn(verti)));

        IF direction = 0 THEN           -- DOWN
          row_base_out_i <= slv(usgn(row_base) + usgn(2 SLL (3*(to_integer(usgn(verti))-1))));
          row_base_var   := slv(usgn(row_base) + usgn(2 SLL (3*(to_integer(usgn(verti))-1))));
        ELSE                            -- UP        
          row_base_out_i <= slv(usgn(row_base) - usgn(2 SLL 3*(to_integer(usgn(verti)))));
          row_base_var   := slv(usgn(row_base) - usgn(2 SLL 3*(to_integer(usgn(verti)))));
        END IF;

        IF alvec = 0 THEN
          group_addr_i <= slv(usgn(row_base_var) + usgn(horiz));
        ELSE                            -- in allocation vector
          group_addr_i <= slv(usgn(ALVEC_SHIFT) +(usgn(horiz) SRL4));
        END IF;
        
      END IF;

      IF state = s1 THEN
        --READ
        mtree <= ram_data_out;
      END IF;

      IF state = s2 THEN

        IF size <= to_integer(usgn(top_node_size) SRL 4) THEN  --topsize/16
          -- allocation won't be decided based on the current group
          -- needs to find the next one to go down to
          -- use the approach "finding starting address" in previous buddy allocator
          -- address tree in mtree
          -- 3
          -- 7 11
          -- 15 19 23 27

          node_sel_i(2)   <= mtree(3);
          node_sel_var(2) := mtree(3);
          node_sel_i(1)   <= mtree(to_integer(7 + 4 * usgn(node_sel_var(2 DOWNTO 2))));
          node_sel_var(1) := mtree(to_integer(7 + 4 * usgn(node_sel_var(2 DOWNTO 2))));
          node_sel_i(0)   <= mtree(to_integer(15 + 4 * usgn(node_sel_var(2 DOWNTO 1))));
          node_sel_var(0) : = mtree(to_integer(15 + 4 * usgn(node_sel_var(2 DOWNTO 1))));

          node_sel_phy_i <= nodel_sel_i + nodel_l;
          

          flag_found <= '1';            -- is this necessary?

          -- flag_found = 1
          verti_i = slv(usgn(verti) + 1);
          horiz_i = slv((usgn(horiz) SLL 3) + usgn(node_sel_var));

          IF to_integer(usgn(top_node_size SRL 4)) = 1 THEN
            alvec_out <= 1;
          END IF;

        ELSE
          IF alvec = '1' THEN           -- using allocation vector
            alvec <= '1';

            flag_found <= '1';
            IF mtree(to_integer(usgn(horiz(4 DOWNTO 0) SLL 1))) = '0'THEN
              node_sel_i      <= usgn(0);
              node_sel__phy_i <= usgn(0);
            ELSIF mtree(to_integer(usgn(horiz(4 DOWNTO 0) SLL 1)+ 1)) = '0' THEN
              node_sel_i     <= usgn(1);
              node_sel_phy_i <= usgn(1);
            ELSE
              flag_found <= '0';
            END IF;
            
          ELSE  -- alvec = 0, not using allocation vector
            -- allocation be decided in this level
            -- can only go up if no available node
            IF size <= to_integer(usgn(top_node_size) SRL 3) THEN  -- topsize/8

            ELSIF size <= to_integer(usgn(top_node_size) SRL 2) THEN  -- topsize /4

            ELSIF size <= to_integer(usgn(top_node_size) SRL 1) THEN  -- topsize/2

            ELSE                        -- final else

            END IF;

          END IF;

        END IF;

      END IF;
    END PROCESS;

    ram_addr <= group_addr_i;

  END ARCHITECTURE;


