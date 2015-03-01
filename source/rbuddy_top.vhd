-- RAM-based Buddy Allocator
-- Created by Hilda Xue, 24 Feb 2015
-- This file contains the top level of the buddy allocator

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;
USE work.budpack.ALL;

ENTITY rbuddy_top IS
  PORT(
    clk         : IN  std_logic;
    reset       : IN  std_logic;
    start       : IN  std_logic;
    cmd         : IN  std_logic;  -- 0 = alloc, 1 = free; Differ from  marking process 
    size        : IN  std_logic_vector(31 DOWNTO 0);
    free_addr   : IN  std_logic_vector(31 DOWNTO 0);
    done        : OUT std_logic;
    malloc_addr : OUT std_logic_vector(31 DOWNTO 0)
    );
END ENTITY rbuddy_top;

ARCHITECTURE synth OF rbuddy_top IS
  TYPE StateType IS (idle,
                     malloc,            -- preprocess info for search in malloc
                     free,              -- preprocess info for free
                     search,            -- search for malloc deciding group
                     track,             -- update tracker
                     downmark,          -- downward marking
                     upmark,            -- upward marking
                     done_state);
  SIGNAL state, nstate : StateType;

  -- ram0
  SIGNAL ram0_we       : std_logic;
  SIGNAL ram0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL ram0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL ram0_data_out : std_logic_vector(31 DOWNTO 0);

  -- wires connecting ram0 from each modules
  SIGNAL malloc0_we       : std_logic;
  SIGNAL malloc0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL malloc0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL malloc0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL search0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL search0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL down0_we       : std_logic;
  SIGNAL down0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL down0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL down0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL up0_we       : std_logic;
  SIGNAL up0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL up0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL up0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL search_start_probe : tree_probe;
  SIGNAL search_done_probe  : tree_probe;
  SIGNAL search_done_bit    : std_logic;
  SIGNAL flag_malloc_failed : std_logic;
  SIGNAL start_search       : std_logic;

  SIGNAL start_dmark        : std_logic;
  SIGNAL flag_alloc         : std_logic;
  SIGNAL dmark_start_probe  : tree_probe;
  SIGNAL dmark_done_bit     : std_logic;
  SIGNAL down_node_out      : std_logic_vector(1 DOWNTO 0);
  SIGNAL up_done_bit        : std_logic;
  SIGNAL start_upmark       : std_logic;
  SIGNAL upmark_start_probe : tree_probe;
  SIGNAL flag_markup        : std_logic;

  SIGNAL start_top_node_size     : std_logic_vector(31 DOWNTO 0);
  SIGNAL start_log2top_node_size : std_logic_vector(6 DOWNTO 0);

  SIGNAL start_free_info     : std_logic;
  SIGNAL free_info_probe_out : tree_probe;
  SIGNAL free_info_done_bit  : std_logic;
  SIGNAL free_tns            : std_logic_vector(31 DOWNTO 0);
  SIGNAL free_log2tns        : std_logic_vector(6 DOWNTO 0);
  SIGNAL free_group_addr     : std_logic_vector(31 DOWNTO 0);

  -- tracker ram
  SIGNAL tracker_we       : std_logic;
  SIGNAL tracker_addr     : integer RANGE 0 TO 31;
  SIGNAL tracker_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL tracker_data_out : std_logic_vector(31 DOWNTO 0);
BEGIN

  RAM0 : ENTITY ram
    PORT MAP(
      clk      => clk,
      we       => ram0_we,
      address  => ram0_addr,
      data_in  => ram0_data_in,
      data_out => ram0_data_out
      );
  LOCATOR0 : ENTITY locator
    PORT MAP(
      clk          => clk,
      reset        => reset,
      start        => start_search,
      probe_in     => search_start_probe,
      size         => size,
      direction_in => '0',              -- start direction is always DOWN
      probe_out    => search_done_probe,
      done_bit     => search_done_bit,
      ram_addr     => search0_addr,
      ram_data_out => search0_data_out,
      flag_failed  => flag_malloc_failed
      );

  dmark : ENTITY down_marker
    PORT MAP(
      clk                  => clk,
      reset                => reset,
      start                => start_dmark,
      flag_alloc           => flag_alloc,
      probe_in             => dmark_start_probe,
      reqsize              => size,
      done_bit             => dmark_done_bit,
      ram_we               => down0_we,
      ram_addr             => down0_addr,
      ram_data_in          => down0_data_in,
      ram_data_out         => down0_data_out,
      node_out             => down_node_out,
      flag_markup          => flag_markup,
      top_node_size_in     => start_top_node_size,
      log2top_node_size_in => start_log2top_node_size
      );

  upmarker : ENTITY up_marker
    PORT MAP(
      clk          => clk,
      reset        => reset,
      start        => start_upmark,
      probe_in     => upmark_start_probe,
      node_in      => down_node_out,
      done_bit     => up_done_bit,
      ram_we       => up0_we,
      ram_addr     => up0_addr,
      ram_data_in  => up0_data_in,
      ram_data_out => up0_data_out
      );

  free_info_calc : ENTITY free_info
    PORT MAP(
      clk                   => clk,
      reset                 => reset,
      start                 => start_free_info,
      address               => free_addr,
      size                  => size,
      probe_out             => free_info_probe_out,
      done_bit              => free_info_done_bit,
      top_node_size_out     => free_tns,
      log2top_node_size_out => free_log2tns,
      group_addr_out        => free_group_addr
      );

  tracker : ENTITY tracker_ram
    PORT MAP (
      clk     => clk,
      we      => tracker_we,
      address => tracker_addr,
      data_in => tracker_data_in,
      data_out = > tracker_data_out
      );

  P0 : PROCESS(state, start, cmd, search_done_bit, search_done_probe,
               dmark_done_bit, up_done_bit, free_info_done_bit, free_info_probe_out,
               free_tns, free_log2tns, flag_markup, flag_alloc)  -- controls FSM, only writes nstate!

  BEGIN

    nstate          <= idle;            -- default value
    start_search    <= '0';
    start_dmark     <= '0';
    start_upmark    <= '0';
    start_free_info <= '0';

    IF state = idle THEN
      nstate <= idle;
      IF start = '1' THEN
        nstate <= malloc;               -- cmd = 0 malloc
        IF cmd = '1' THEN               -- cmd = 1 free
          nstate <= free;

          start_free_info <= '1';
          
        END IF;
      END IF;
    END IF;

    IF state = malloc THEN
      --  nstate <= malloc;
      nstate <= search;  --for developing search block first, skip malloc state

      start_search               <= '1';
      search_start_probe.alvec   <= '0';  -- needs extra to check, but set to 0 for first simulation
      search_start_probe.verti   <= (OTHERS => '0');
      search_start_probe.horiz   <= (OTHERS => '0');
      search_start_probe.rowbase <= (OTHERS => '0');
      search_start_probe.saddr   <= (OTHERS => '0');
      search_start_probe.nodesel <= (OTHERS => '0');
      
    END IF;

    IF state = free THEN
      nstate <= free;
      IF free_info_done_bit = '1' THEN
	  nstate <= track;
        --nstate                  <= downmark;
        --start_dmark             <= '1';
        dmark_start_probe       <= free_info_probe_out;
        start_top_node_size     <= free_tns;
        start_log2top_node_size <= free_log2tns;
      END IF;
    END IF;

    IF state = search THEN
      nstate <= search;
      IF search_done_bit = '1' THEN
	  if flag_malloc_failed = '0' then 
	  nstate <= track;
        nstate                  <= downmark;
        --start_dmark             <= '1';
		-- pass the information for downward marking
        dmark_start_probe       <= search_done_probe;
        start_top_node_size     <= TOTAL_MEM_BLOCKS;
        start_log2top_node_size <= LOG2TMB;
		
		else
		nstate <= done;
		end if;
      END IF;
    END IF;

    IF state = track THEN
		nstate <= downmark;
		start_dmark <= '1';
    END IF;

    IF state = downmark THEN
      nstate <= downmark;
      IF dmark_done_bit = '1' THEN
        
        nstate <= idle;
        IF flag_markup = '1' THEN
          nstate       <= upmark;
          start_upmark <= '1';


          upmark_start_probe <= search_done_probe;  -- malloc
          IF flag_alloc = '0' THEN                  -- free
            upmark_start_probe <= free_info_probe_out;
          END IF;
          
        END IF;

      END IF;
    END IF;

    IF state = upmark THEN
      
      nstate <= upmark;
      IF up_done_bit = '1' THEN
        nstate <= idle;
      END IF;
    END IF;

    IF state = done_state THEN
      nstate <= idle;                   -- done -> idle
    END IF;
    
  END PROCESS;

  P1 : PROCESS

  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;                  -- default
	  
	  if state = track then 
	  
		if flag_alloc = '0' then -- free 
		   
		else -- malloc
		
		end if;
	  
	  end if;
	  
    END IF;
    
  END PROCESS;

  p2 : PROCESS(state,
               malloc0_we, malloc0_addr, malloc0_data_in,
               search0_addr,
               down0_we, down0_addr, down0_data_in,
               up0_we, up0_addr, up0_data_in,
               ram0_data_out)           -- select ram signals
  BEGIN

    -- state = malloc (default)
    ram0_we          <= malloc0_we;
    ram0_addr        <= malloc0_addr;
    ram0_data_in     <= malloc0_data_in;
    malloc0_data_out <= ram0_data_out;

    IF state = search THEN
      --    ram0_we       <= search0_we; --doesn't need
      ram0_addr        <= search0_addr;
      --    ram0_data_in  <= search0_data_in; --doesn't need
      search0_data_out <= ram0_data_out;
    END IF;

    IF state = downmark THEN
      ram0_we        <= down0_we;
      ram0_addr      <= down0_addr;
      ram0_data_in   <= down0_data_in;
      down0_data_out <= ram0_data_out;
    END IF;

    IF state = upmark THEN
      ram0_we      <= up0_we;
      ram0_addr    <= up0_addr;
      ram0_data_in <= up0_data_in;
      up0_data_out <= ram0_data_out;
    END IF;
    
  END PROCESS;

  malloc_addr <= search_done_probe.saddr;
  flag_alloc  <= NOT cmd;
  

END ARCHITECTURE synth;



