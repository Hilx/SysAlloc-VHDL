LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY locator IS
  PORT(
    clk                  : IN  std_logic;
    reset                : IN  std_logic;
    start                : IN  std_logic;
    -- inputs
    alvec_in             : IN  std_logic;  -- allocation vector usage flag
    size_in              : IN  std_logic_vector(31 DOWNTO 0);
    verti_in             : IN  std_logic_vector(31 DOWNTO 0);  -- vertical index of group
    horiz_in             : IN  std_logic_vector(31 DOWNTO 0);  -- horizontal index of group
    nodesel_in           : IN  std_logic_vector(2 DOWNTO 0);  --  physical version
    saddr_in             : IN  std_logic_vector(31 DOWNTO 0);  -- starting address of the malloc
    row_base_in          : IN  std_logic_vector(31 DOWNTO 0);
    direction_in         : IN  std_logic;  -- DOWN = 0, UP = 1
    total_mem_blocks     : IN  std_logic_vector(31 DOWNTO 0);
    log2total_mem_blocks : IN  std_logic_vector(6 DOWNTO 0);
    ALVEC_SHIFT          : IN  std_logic_vector(31 DOWNTO 0);
    -- outputs 
    verti_out            : OUT std_logic_vector(31 DOWNTO 0);  -- vertical index of group
    horiz_out            : OUT std_logic_vector(31 DOWNTO 0);  -- horizontal index of group
    alvec_out            : OUT std_logic;  -- allocation vector usage flag
    nodesel_out          : OUT std_logic_vector(2 DOWNTO 0);  --  physical version
    saddr_out            : OUT std_logic_vector(31 DOWNTO 0);  -- starting address of the malloc
    row_base_out         : OUT std_logic_vector(31 DOWNTO 0);
    done_bit             : OUT std_logic;
    -- group_addr           : OUT std_logic_vector(31 DOWNTO 0);
    -- ram interface
    ram_addr             : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_out         : IN  std_logic_vector(31 DOWNTO 0)
    );
END ENTITY locator;

ARCHITECTURE synth_locator OF locator IS
  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;
  TYPE StateType IS (idle, prep, s0, s1, s2, s3, done);
  SIGNAL state, nstate           : StateType;
  SIGNAL search_status           : std_logic;
  SIGNAL top_node_size           : std_logic_vector(31 DOWNTO 0);
  SIGNAL log2top_node_size       : std_logic_vector(6 DOWNTO 0);  -- range > 32
  SIGNAL group_addr_i            : std_logic_vector(31 DOWNTO 0);
  SIGNAL mtree, utree            : std_logic_vector(31 DOWNTO 0);
  SIGNAL flag_found, flag_failed : std_logic;
  SIGNAL alvec_i, alvec          : std_logic;  -- allocation vector usage flag
  SIGNAL size_i, size            : std_logic_vector(31 DOWNTO 0);
  SIGNAL verti_i, verti          : std_logic_vector(31 DOWNTO 0);  -- vertical  dex of group
  SIGNAL horiz_i, horiz          : std_logic_vector(31 DOWNTO 0);  -- horizontal  dex of group
  SIGNAL nodesel_i, nodesel      : std_logic_vector(2 DOWNTO 0);  --  physical version
  SIGNAL saddr_i, saddr          : std_logic_vector(31 DOWNTO 0);  -- start g address of the malloc
  SIGNAL row_base_i, row_base    : std_logic_vector(31 DOWNTO 0);
  SIGNAL direction_i, direction  : std_logic;  -- DOWN = 0, UP = 1
  CONSTANT two                   : std_logic_vector(1 DOWNTO 0) := "10";
  

BEGIN

  P0 : PROCESS(state, start, search_status)
  BEGIN
    
    nstate   <= idle;
    done_bit <= '0';
    CASE state IS
      WHEN idle =>

        nstate <= idle;
        IF start = '1' THEN
          nstate <= prep;
        END IF;
      WHEN prep => nstate <= s0;
      WHEN s0   => nstate <= s1;
      WHEN s1   => nstate <= s2;
      WHEN s2   => nstate <= s3;
      WHEN s3 =>
        
        nstate <= s0;
        IF search_status = '1' THEN
          nstate   <= done;
          done_bit <= '1';
        END IF;
        
      WHEN done =>
        nstate   <= idle;
        done_bit <= '1';
      WHEN OTHERS => NULL;
    END CASE;

  END PROCESS;

  P1 : PROCESS
    VARIABLE row_base_var   : slv(31 DOWNTO 0);
    VARIABLE mtree_var      : slv(31 DOWNTO 0);
    VARIABLE group_addr_var : slv(31 DOWNTO 0);
    VARIABLE flag_found_var : std_logic;
    VARIABLE nodesel_var    : slv(2 DOWNTO 0);
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';
    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;

      IF state = prep THEN
        flag_found     <= '0';
        flag_found_var := '0';
        flag_failed    <= '0';

        alvec     <= alvec_in;
        size      <= size_in;
        verti     <= verti_in;
        horiz     <= horiz_in;
        nodesel   <= nodesel_in;
        saddr     <= saddr_in;
        row_base  <= row_base_in;
        direction <= direction_in;
      END IF;

      IF state = s0 THEN
        top_node_size     <= slv(usgn(total_mem_blocks) SRL (to_integer(3*(usgn(verti)))));
        log2top_node_size <= slv(resize(usgn(log2total_mem_blocks) - 3* (usgn(verti)), log2top_node_size'length));

        IF direction = '0' THEN         -- DOWN
          row_base_i   <= slv(usgn(row_base) + (usgn(two) SLL (to_integer(3*(usgn(verti)-1)))));
          row_base_var := slv(usgn(row_base) + (usgn(two) SLL (to_integer(3*(usgn(verti)-1)))));
        ELSE                            -- UP        
          row_base_i   <= slv(usgn(row_base) - (usgn(two) SLL (to_integer(3*(usgn(verti))))));
          row_base_var := slv(usgn(row_base) - (usgn(two) SLL (to_integer(3*(usgn(verti))))));
        END IF;

        IF alvec = '0' THEN
          group_addr_i   <= slv(usgn(row_base_var) + usgn(horiz));
          group_addr_var := slv(usgn(row_base_var) + usgn(horiz));
        ELSE                            -- in allocation vector
          group_addr_i   <= slv(usgn(ALVEC_SHIFT) +(usgn(horiz) SRL 4));
          group_addr_var := slv(usgn(row_base_var) + usgn(horiz));
        END IF;

        mtree <= ram_data_out;

      END IF;

      --    IF state = s1 THEN
      --READ -- wait to make sure it's ready

      --    END IF;

      IF state = s2 THEN

        IF size <= slv(usgn(top_node_size) SRL 4) THEN  --topsize/16
          -- allocation won't be decided based on the current group
          -- needs to find the next one to go down to
          -- use the approach "finding starting address" in previous buddy allocator
          -- address tree in mtree
          -- 3
          -- 7 11
          -- 15 19 23 27
          

          IF direction = '1' THEN       -- UP
            -- mark the previously checked node
            -- separate combinational process to update the tree
            mtree_var := utree;
          ELSE                          -- DOWN
            mtree_var := mtree;
          END IF;

          flag_found     <= '0';
          flag_found_var := '0';
          IF(mtree(14) AND mtree(16)
             AND mtree(18) AND mtree(20)
             AND mtree(22) AND mtree(24)
             AND mtree(26) AND mtree(28)) = '0' THEN
            flag_found     <= '1';
            flag_found_var := '1';
          END IF;

          IF flag_found_var = '1'THEN
            nodesel_i(2)   <= mtree(3);
            nodesel_var(2) := mtree(3);
            nodesel_i(1)   <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
            nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
            nodesel_i(0)   <= mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));
            nodesel_var(0) := mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));

            nodesel_i <= nodesel_var;

            -- flag_found = 1
            verti_i <= slv(usgn(verti) + 1);
            horiz_i <= slv((usgn(horiz) SLL 3) + usgn(nodesel_var));
            saddr_i <= slv(usgn(saddr) + usgn(nodesel) SLL to_integer(usgn(log2top_node_size) - 3));

            IF to_integer(usgn(top_node_size) SRL 4) = 1 THEN
              alvec_out <= '1';
            END IF;
          ELSE

            IF to_integer(usgn(verti)) = 0 THEN
              flag_failed <= '1';
            ELSE
              verti_i     <= slv(usgn(verti) - 1);
              horiz_i     <= slv(usgn(horiz) SRL 3);
              direction_i <= '1';
              nodesel_i   <= slv(resize(usgn(horiz(2 DOWNTO 0)), nodesel_i'length));
              saddr_i     <= slv(usgn(saddr) - usgn(nodesel) SLL to_integer(usgn(log2top_node_size)));
            END IF;

          END IF;

        ELSE
          IF alvec = '1' THEN           -- using allocation vector
            alvec <= '1';

            flag_found <= '1';
            IF mtree(to_integer(usgn(horiz(4 DOWNTO 0)) SLL 1)) = '0' THEN
              nodesel_i <= (OTHERS => '0');
            ELSIF mtree(to_integer(usgn(horiz(4 DOWNTO 0)) SLL 1+ 1)) = '0' THEN
              nodesel_i <= "001";
            ELSE
              flag_found <= '0';
            END IF;
            
          ELSE  -- alvec = 0, not using allocation vector
            -- allocation be decided in this level
            -- can only go up if no available node
            IF size <= slv(usgn(top_node_size) SRL 3) THEN  -- topsize/8

              flag_found     <= '0';
              flag_found_var := '0';
              IF(mtree(14) AND mtree(16) AND mtree(18) AND mtree(20)
                 AND mtree(22) AND mtree(24) AND mtree(26) AND mtree(28)) = '0' THEN
                flag_found     <= '1';
                flag_found_var := '1';
              END IF;

              IF flag_found_var = '1' THEN
                nodesel_i(2)   <= mtree(3);
                nodesel_var(2) := mtree(3);
                nodesel_i(1)   <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_i(0)   <= mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));
                nodesel_var(0) := mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));
              END IF;
              
            ELSIF size <= slv(usgn(top_node_size) SRL 2) THEN  -- topsize /4              

              flag_found     <= '0';
              flag_found_var := '0';
              IF(mtree_var(6) AND mtree_var(8) AND mtree_var(10) AND mtree_var(12)) = '0' THEN
                flag_found     <= '1';
                flag_found_var := '1';
              END IF;

              IF flag_found_var = '1' THEN

                nodesel_i(2)   <= mtree(3);
                nodesel_var(2) := mtree(3);
                nodesel_i(1)   <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_i(0)   <= '0';
                nodesel_var(0) := '0';
              END IF;
              
            ELSIF size <= slv(usgn(top_node_size) SRL 1) THEN  -- topsize/2
              
              flag_found     <= '0';
              flag_found_var := '0';
              IF(mtree(2) AND mtree(4)) = '0' THEN
                flag_found     <= '1';
                flag_found_var := '1';
              END IF;

              IF flag_found_var = '1' THEN
                nodesel_i(2)   <= mtree(3);
                nodesel_var(2) := mtree(3);
                nodesel_i(1)   <= '0';
                nodesel_var(1) := '0';
                nodesel_i(0)   <= '0';
                nodesel_var(0) := '0';
              END IF;
              
            ELSE                        -- final else
                                        -- 
              flag_found     <= NOT mtree(0);
              flag_found_var := NOT mtree(0);
              
            END IF;

            IF flag_found_var = '1' THEN
              search_status <= '1';

              verti_i <= verti;
              horiz_i <= horiz;

              IF alvec = '0' THEN

                IF to_integer(usgn(top_node_size)) = 4 THEN
                  saddr_i <= slv(usgn(saddr) + (usgn(nodesel_i) SRL 1));
                ELSE
                  saddr_i <= slv(usgn(saddr) + (usgn(nodesel_i) SRL 3));
                END IF;

              ELSE
                
                saddr_i <= slv(usgn(saddr) + usgn(nodesel_i));
                
              END IF;

            ELSE                        -- not found

              IF to_integer(usgn(verti)) = 0 THEN
                flag_failed <= '1';
              ELSE                      -- GO UP
                verti_i     <= slv(usgn(verti) - 1);
                horiz_i     <= slv(usgn(horiz) SRL 3);
                direction_i <= '0';     -- UP = 0
                nodesel_i   <= slv(resize(usgn(horiz(2 DOWNTO 0)), nodesel_i'length));
                saddr_i     <= slv(usgn(saddr) - usgn(nodesel) SLL to_integer(usgn(log2top_node_size)));

              END IF;

            END IF;

          END IF;

        END IF;

      END IF;

      IF state = s3 THEN

        IF search_status = '0' THEN     -- continue the search
          
          alvec     <= alvec_i;
          size      <= size_i;
          verti     <= verti_i;
          horiz     <= horiz_i;
          nodesel   <= nodesel_i;
          saddr     <= saddr_i;
          row_base  <= row_base_i;
          direction <= direction_i;
        END IF;
        
      END IF;

    END IF;
  END PROCESS;

  P2 : PROCESS(mtree, nodesel)
    VARIABLE mtree_var : slv(31 DOWNTO 0);
  BEGIN

    -- update mtree based on depth 3
    -- 0, 1, 2,3
    
    FOR i IN 15 TO 29 LOOP
      IF i = to_integer(15 + (usgn(nodesel) SLL 2)) THEN
        mtree_var(i) := '1';
      ELSE
        mtree_var(i) := mtree(i);
      END IF;
    END LOOP;

    FOR i IN 0 TO 3 LOOP
      mtree_var(7 + 2*i) := mtree_var(15 + 4*i) AND mtree_var(17 + 4*i);
    END LOOP;

    FOR i IN 0 TO 1 LOOP
      mtree_var(3 + 2*i) := mtree_var(7 + 4*i) AND mtree_var(9 + 4*i);
    END LOOP;

    mtree_var(1) := mtree_var(3) AND mtree_var(5);

    utree <= mtree_var;
    
  END PROCESS;

  ram_addr <= group_addr_i;

  verti_out    <= verti_i;
  horiz_out    <= horiz_i;
  alvec_out    <= alvec_i;
  nodesel_out  <= nodesel_i;
  saddr_out    <= saddr_i;
  row_base_out <= row_base_i;

END ARCHITECTURE;


