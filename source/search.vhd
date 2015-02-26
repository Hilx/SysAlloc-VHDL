LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
USE work.budpack.ALL;

ENTITY locator IS
  PORT(
    clk          : IN  std_logic;
    reset        : IN  std_logic;
    start        : IN  std_logic;
    probe_in     : IN  tree_probe;
    size_in      : IN  std_logic_vector(31 DOWNTO 0);
    direction_in : IN  std_logic;       -- DOWN = 0, UP = 1
    probe_out    : OUT tree_probe;
    done_bit     : OUT std_logic;
    ram_addr     : OUT std_logic_vector(31 DOWNTO 0);
    ram_data_out : IN  std_logic_vector(31 DOWNTO 0);
	flag_failed : out std_logic
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
  SIGNAL flag_found : std_logic;

  SIGNAL cur : tree_probe;
  SIGNAL gen : tree_probe;

  SIGNAL size_i, size : std_logic_vector(31 DOWNTO 0);

  SIGNAL direction_i, direction : std_logic;  -- DOWN = 0, UP = 1
  CONSTANT two                  : std_logic_vector(1 DOWNTO 0) := "10";
  

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
    VARIABLE rowbase_var    : slv(31 DOWNTO 0);
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
	  search_status <= '0';

        flag_failed    <= '0';
	
	size        <= size_in;
 	cur <= probe_in;
        direction   <= direction_in;
      END IF;

      IF state = s0 THEN
	          flag_found     <= '0';
        flag_found_var := '0';
		gen.alvec <= '0';
	  
        top_node_size     <= slv(usgn(TOTAL_MEM_BLOCKS) SRL (to_integer(3*(usgn(cur.verti)))));
        log2top_node_size <= slv(resize(usgn(LOG2TMB) - 3* (usgn(cur.verti)), log2top_node_size'length));

        IF direction = '0' THEN         -- DOWN
          gen.rowbase <= slv(usgn(cur.rowbase) + (usgn(two) SLL (to_integer(3*(usgn(cur.verti)-1)))));
          rowbase_var := slv(usgn(cur.rowbase) + (usgn(two) SLL (to_integer(3*(usgn(cur.verti)-1)))));
        ELSE                            -- UP        
          gen.rowbase <= slv(usgn(cur.rowbase) - (usgn(two) SLL (to_integer(3*(usgn(cur.verti))))));
          rowbase_var := slv(usgn(cur.rowbase) - (usgn(two) SLL (to_integer(3*(usgn(cur.verti))))));
        END IF;

        IF cur.alvec = '0' THEN
          group_addr_i   <= slv(usgn(rowbase_var) + usgn(cur.horiz));
          group_addr_var := slv(usgn(rowbase_var) + usgn(cur.horiz));
        ELSE                            -- in allocation vector
          group_addr_i   <= slv(usgn(ALVEC_SHIFT) +(usgn(cur.horiz) SRL 4));
          group_addr_var := slv(usgn(rowbase_var) + usgn(cur.horiz));
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
		
		  flag_found_var := '0';
          IF(mtree(14) AND mtree(16)
             AND mtree(18) AND mtree(20)
             AND mtree(22) AND mtree(24)
             AND mtree(26) AND mtree(28)) = '0' THEN
			flag_found_var := '1';         
          END IF;
		  flag_found     <= flag_found_var;

          IF flag_found_var = '1'THEN
            gen.nodesel(2) <= mtree(3);
            nodesel_var(2) := mtree(3);
            gen.nodesel(1) <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
            nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
            gen.nodesel(0) <= mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));
            nodesel_var(0) := mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));

            gen.nodesel <= nodesel_var;

            -- flag_found = 1
            gen.verti <= slv(usgn(cur.verti) + 1);
            gen.horiz <= slv((usgn(cur.horiz) SLL 3) + usgn(nodesel_var));
            gen.saddr <= slv(usgn(cur.saddr) + usgn(cur.nodesel) SLL to_integer(usgn(log2top_node_size) - 3));

            IF to_integer(usgn(top_node_size) SRL 4) = 1 THEN
              probe_out.alvec <= '1';
            END IF;
          ELSE

            IF to_integer(usgn(cur.verti)) = 0 THEN
              flag_failed <= '1';
            ELSE
              gen.verti   <= slv(usgn(cur.verti) - 1);
              gen.horiz   <= slv(usgn(cur.horiz) SRL 3);
              gen_direction<= '1';
              gen.nodesel <= slv(resize(usgn(cur.horiz(2 DOWNTO 0)), gen.nodesel'length));
              gen.saddr   <= slv(usgn(cur.saddr) - usgn(cur.nodesel) SLL to_integer(usgn(log2top_node_size)));
            END IF;

          END IF;

        ELSE
          IF cur.alvec = '1' THEN       -- using allocation vector
            cur.alvec <= '1';

            flag_found <= '1';
            IF mtree(to_integer(usgn(cur.horiz(4 DOWNTO 0)) SLL 1)) = '0' THEN
              gen.nodesel <= (OTHERS => '0');
            ELSIF mtree(to_integer(usgn(cur.horiz(4 DOWNTO 0)) SLL 1+ 1)) = '0' THEN
              gen.nodesel <= "001";
            ELSE
              flag_found <= '0';
            END IF;
            
          ELSE  -- cur.alvec= 0, not using allocation vector
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
                gen.nodesel(2) <= mtree(3);
                nodesel_var(2) := mtree(3);
                gen.nodesel(1) <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                gen.nodesel(0) <= mtree(to_integer(15 + 4 * usgn(nodesel_var(2 DOWNTO 1))));
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

                gen.nodesel(2) <= mtree(3);
                nodesel_var(2) := mtree(3);
                gen.nodesel(1) <= mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                nodesel_var(1) := mtree(to_integer(7 + 4 * usgn(nodesel_var(2 DOWNTO 2))));
                gen.nodesel(0) <= '0';
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
                gen.nodesel(2) <= mtree(3);
                nodesel_var(2) := mtree(3);
                gen.nodesel(1) <= '0';
                nodesel_var(1) := '0';
                gen.nodesel(0) <= '0';
                nodesel_var(0) := '0';
              END IF;
              
            ELSE                        -- final else
                                        -- 
              flag_found     <= NOT mtree(0);
              flag_found_var := NOT mtree(0);
              
            END IF;

            IF flag_found_var = '1' THEN
              search_status <= '1';

              gen.verti <= cur.verti;
              gen.horiz <= cur.horiz;

              IF cur.alvec = '0' THEN

                IF to_integer(usgn(top_node_size)) = 4 THEN
                  gen.saddr <= slv(usgn(cur.saddr) + (usgn(gen.nodesel) SRL 1));
                ELSE
                  gen.saddr <= slv(usgn(cur.saddr) + (usgn(gen.nodesel) SRL 3));
                END IF;

              ELSE
                
                gen.saddr <= slv(usgn(cur.saddr) + usgn(gen.nodesel));
                
              END IF;

            ELSE                        -- not found

              IF to_integer(usgn(cur.verti)) = 0 THEN
                flag_failed <= '1';
              ELSE                      -- GO UP
                gen.verti   <= slv(usgn(cur.verti) - 1);
                gen.horiz   <= slv(usgn(cur.horiz) SRL 3);
                gen_direction<= '0';     -- UP = 0
                gen.nodesel <= slv(resize(usgn(cur.horiz(2 DOWNTO 0)), gen.nodesel'length));
                gen.saddr   <= slv(usgn(cur.saddr) - usgn(cur.nodesel) SLL to_integer(usgn(log2top_node_size)));

              END IF;

            END IF;

          END IF;

        END IF;

      END IF;

      IF state = s3 THEN

        IF search_status = '0' THEN     -- continue the search          
		  cur <= gen;
         
          direction   <= direction_i;
        END IF;
        
      END IF;

    END IF;
  END PROCESS;

  P2 : PROCESS(mtree, cur.nodesel)
    VARIABLE mtree_var : slv(31 DOWNTO 0);
  BEGIN

    -- update mtree based on depth 3
    -- 0, 1, 2,3
    
    FOR i IN 15 TO 29 LOOP
      IF i = to_integer(15 + (usgn(cur.nodesel) SLL 2)) THEN
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

  probe_out <= gen;


END ARCHITECTURE;


