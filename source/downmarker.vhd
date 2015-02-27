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
    flag_alloc   : IN  std_logic;       -- 1 = alloc, 0 = free
    probe_in     : IN  tree_probe;
    reqsize      : IN  std_logic_vector(31 DOWNTO 0);
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

  TYPE StateType IS (idle, prep, s0, s_read, s_mark, s_w0, s_w1, done);
  SIGNAL state, nstate : StateType;

  SIGNAL top_node_size     : std_logic_vector(31 DOWNTO 0);
  SIGNAL log2top_node_size : std_logic_vector(6 DOWNTO 0);
  SIGNAL group_addr        : std_logic_vector(31 DOWNTO 0);
  SIGNAL mtree             : std_logic_vector(31 DOWNTO 0);
  SIGNAL cur               : tree_probe;
  SIGNAL gen               : tree_probe;
  SIGNAL size_left         : std_logic_vector(31 DOWNTO 0);
  SIGNAL flag_first        : std_logic;
  SIGNAL original_top_node : std_logic_vector(1 DOWNTO 0);
  SIGNAL alvec_sel         : integer RANGE 0 TO 31;
  SIGNAL shift             : std_logic_vector(5 DOWNTO 0);  -- double the first cur.nodesel
  SIGNAL utree             : std_logic_vector(31 DOWNTO 0);
     signal offset_debug        : std_logic_vector(2 DOWNTO 0);
	     signal step_debug          : std_logic_vector(2 DOWNTO 0);  -- 8 possible nodes to mark
    signal  size_left_debug : slv(31 DOWNTO 0);
	 
	 signal FLAG_HERE :std_logic;
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
      WHEN prep      => nstate <= s0;
      WHEN s0 => nstate <= s_read;
      WHEN s_read   => nstate <= s_mark;
      WHEN s_mark   => nstate <= s_w0;
      WHEN s_w0  => nstate <= s_w1;
      WHEN s_w1 =>
        nstate <= s0;
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
    VARIABLE rowbase_var   : slv(31 DOWNTO 0);
    VARIABLE step          : std_logic_vector(2 DOWNTO 0);  -- 8 possible nodes to mark
    VARIABLE size_left_var : slv(31 DOWNTO 0);
    VARIABLE offset        : std_logic_vector(2 DOWNTO 0);

  BEGIN
    WAIT UNTIL clk'event AND clk = '1';
FLAG_HERE <= '0';
    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;

      IF state = prep THEN
        cur        <= probe_in;
        size_left  <= reqsize;
        flag_first <= '1';
      END IF;

      IF state = s0 THEN
        gen.alvec <= '0';

        top_node_size     <= slv(usgn(TOTAL_MEM_BLOCKS) SRL (to_integer(3*(usgn(cur.verti)))));
        log2top_node_size <= slv(resize(usgn(LOG2TMB) - 3* (usgn(cur.verti)), log2top_node_size'length));

        rowbase_var := slv(usgn(cur.rowbase) + (to_unsigned(1, rowbase_var'length) SLL (to_integer(3*(usgn(cur.verti)-1)))));

        gen.rowbase <= rowbase_var;

        IF cur.alvec = '0' THEN
          group_addr <= slv(usgn(rowbase_var) + usgn(cur.horiz));
        ELSE                            -- in allocation vector
          group_addr <= slv(usgn(ALVEC_SHIFT) +(usgn(cur.horiz) SRL 4));
        END IF;

        -- ( horiz % 16 ) * 2
        alvec_sel <= to_integer(resize(usgn(cur.horiz(3 DOWNTO 0)), 5) SLL 1);

        offset := (others => '0');

      END IF;  -- finished case of s0

      IF state = s_read THEN
        mtree <= ram_data_out;

        shift <= (others =>'0');
        IF flag_first = '1' THEN  -- keep a copy of the top node of chosen group
			flag_first <= '0';
		shift <= slv(resize(usgn(cur.nodesel),shift'length) sll 1);   -- set shift value = nodesel * 2
		
          IF cur.alvec = '0' THEN
            original_top_node <= ram_data_out(1 DOWNTO 0);
          ELSE                          -- in allocation vector            
            original_top_node <= ram_data_out(alvec_sel + 1 DOWNTO alvec_sel);
          END IF;
        END IF;
        
      END IF;  -- finished case of s_read

      IF state = s_mark THEN

        IF cur.alvec = '1' THEN
          IF to_integer(usgn(reqsize)) = 1 AND probe_in.saddr(1) = '1' THEN
            mtree(alvec_sel + 1) <= flag_alloc;
          ELSE
            mtree(alvec_sel) <= flag_alloc;
          END IF;

          size_left_var := (OTHERS => '0');
		  size_left <= size_left_var;
          
        ELSIF size_left < slv(usgn(top_node_size) SRL 3) THEN  -- reqsize < topsize/8
          
          mtree(14) <= flag_alloc;
		  
	--	  if to_integer(usgn(top_node_size)) = 16 then 
	--	  gen.alvec <= '1';
	--	  end if;
          
        ELSIF to_integer(usgn(top_node_size)) = 4 THEN  -- topsize = 4

          step := slv(resize(usgn(size_left), step'length));  -- step = size_left

          FOR i IN 0 TO 15 LOOP
            -- if shift =< i < shift +step
            IF i >= to_integer(usgn(shift)) AND i < to_integer(usgn(shift) + usgn(step) SLL 2) THEN
              mtree(i + 14) <= flag_alloc;
            END IF;
          END LOOP;

          size_left_var := (OTHERS => '0');
		   size_left <= size_left_var;

        ELSE                            -- other topsize          
          
           step := slv(resize(usgn(size_left) SRL to_integer(usgn(log2top_node_size) - 3),step'length));
          FOR i IN 0 TO 15 LOOP
            -- if shift =< i < shift +step
            IF i >= to_integer(usgn(shift)) AND i < to_integer(usgn(shift) + usgn(step) SLL 1) THEN
              mtree(i + 14) <= flag_alloc;
            END IF;
          END LOOP;

          -- size left = size left - step * base node size
          size_left_var := slv(usgn(size_left) -(resize(usgn(step),size_left'length) SLL to_integer(usgn(log2top_node_size) - 3)));
			 size_left <= size_left_var;
			 
			 step_debug <= step;
			 size_left_debug <= size_left_var;
			 
			 FLAG_HERE <= '1';

          IF to_integer(usgn(size_left_var)) /= 0 THEN
            -- mtree(14 + shift + 2 * step) <= 1
            mtree(14 + to_integer(usgn(shift)) + to_integer(usgn(step) SLL 1)) <= flag_alloc;
          END IF;
          -- offset = shift/2 + step
          offset := slv(resize((usgn(shift) SRL 1) + usgn(step), offset'length));
          
        END IF;  -- finished discussing 4 cases

        IF to_integer(usgn(size_left_var)) > 0 THEN
          gen.saddr   <= cur.saddr;
          gen.nodesel <= offset;
          gen.verti   <= slv(usgn(cur.verti) + 1);
          gen.horiz   <= slv((usgn(cur.horiz) SLL 3) + usgn(offset));
          gen.alvec   <= '0';
          IF to_integer(usgn(top_node_size)) = 16 THEN
            gen.alvec <= '1';
          END IF;
          
        END IF;
        
		
		
		offset_debug <= offset;
		
      END IF;  -- finished case of s_mark

      IF state = s_w0 THEN
        ram_data_in <= utree;
      END IF;  -- finished case of s_w0
ram_we <= '0';

      IF state = s_w1 THEN
        ram_we <= '1';

        cur <= gen;
      END IF;  -- finish case of s_w1
      
    END IF;  -- not resetting

  END PROCESS;


  p3 : PROCESS(mtree)                   --comb process, updates the tree
    VARIABLE vartree : std_logic_vector(31 DOWNTO 0);
  BEGIN

    FOR i IN 0 TO 3 LOOP
      vartree(6 + 2*i) := mtree(14 + 4*i) OR mtree(16 + 4*i);   -- or tree
      vartree(7 + 2*i) := mtree(15 + 4*i) AND mtree(17 + 4*i);  -- and tree`
    END LOOP;

    FOR i IN 0 TO 1 LOOP
      vartree(2 + 2*i) := vartree(6 + 4*i) OR vartree(8 + 4*i);
      vartree(3 + 2*i) := vartree(7 + 4*i) AND vartree(9 + 4*i);
    END LOOP;

    vartree(0) := vartree(2) OR vartree(4);
    vartree(1) := vartree(3) AND vartree(5);

    FOR i IN 14 TO 31 LOOP
      vartree(i) := mtree(i);
    END LOOP;

    utree <= vartree;
    
  END PROCESS;


  ram_addr <= group_addr;

END ARCHITECTURE;
