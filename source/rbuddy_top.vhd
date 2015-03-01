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

  ALIAS slv IS std_logic_vector;
  ALIAS usgn IS unsigned;

  TYPE StateType IS (idle,
                     malloc0,malloc1,    -- preprocess info for search in malloc
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
  
  signal group_addr_to_tracker : std_logic_vector(31 downto 0);
  signal tracker_func_sel : std_logic; -- 0 = update, 1 = make probe_in
  signal tracker_done :std_logic;
  signal tracker_probe_out : tree_probe;
  
  signal start_check_blocking : std_logic;
  signal flag_blocking : std_logic;
  signal cblock_probe_in : tree_probe;
  signal cblock_probe_out : tree_probe;
  signal cblock_done : std_logic;
  signal cblock_ram_addr: std_logic_vector(31 downto 0);
signal cblock_ram_data_out : std_logic_vector(31 downto 0);

signal start_tracker :std_logic;


  
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
      flag_markup          => flag_markup
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

  tracker_ram0 : ENTITY tracker_ram
    PORT MAP (
      clk     => clk,
      we      => tracker_we,
      address => tracker_addr,
      data_in => tracker_data_in,
      data_out => tracker_data_out
      );
  
	  tracker0 : entity tracker
	  port map(
		clk => clk,
		reset => reset,
		start => start_tracker,
		group_addr_in => group_addr_to_tracker,
		size => size,
		flag_alloc => flag_alloc,
		func_sel => tracker_func_sel,
		done_bit => tracker_done,
		probe_out => tracker_probe_out,
		ram_we => tracker_we,
		ram_addr => tracker_addr,
		ram_data_in => tracker_data_in,
		ram_data_out => tracker_data_out	  
	  );
	  
	  cblock : entity check_blocking 
	  port map(
		clk => clk,
		reset => reset,
		start => start_check_blocking,
		flag_blocking_out => flag_blocking,
		probe_in => cblock_probe_in,
		probe_out => cblock_probe_out,
		done_bit => cblock_done,
		ram_addr => cblock_ram_addr,
		ram_data_out => cblock_ram_data_out
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
	start_tracker <= '0';
	start_search <= '0';
	start_check_blocking <= '0';

    IF state = idle THEN
      nstate <= idle;
      IF start = '1' THEN		
        IF cmd = '1' THEN               -- cmd = 1 free
          nstate <= free;
          start_free_info <= '1';  
		else -- cmd = 0 malloc
		  nstate <= malloc0;
		  start_tracker <= '1';
		  tracker_func_sel <= '1';
        END IF;
      END IF;
    END IF;

    IF state = malloc0 THEN
	  
	  nstate <= malloc0;
	  if tracker_done = '1' then 	  
		if to_integer(usgn(tracker_probe_out.verti)) = 0 then -- skip cblock
			nstate <= search;
			start_search <= '1';
			search_start_probe <= tracker_probe_out;				
		else -- cblock 
			nstate <= malloc1;
			start_check_blocking <= '1';
			search_start_probe <= tracker_probe_out;		
		end if;		
	  end if;
      
    END IF;

    if state = malloc1 then 
		
		nstate <= malloc1;
		
		if cblock_done = '1' then

			nstate <= search;
			start_search <= '1';
			
		if flag_blocking = '0' then -- no blocking, use the tracker_probe_out
			search_start_probe <= tracker_probe_out;
		else
			search_start_probe <= cblock_probe_out;
		end if;
		end if;		
	end if; -- end malloc1
		
	IF state = free THEN
      nstate <= free;
      IF free_info_done_bit = '1' THEN
		nstate <= track;
         start_tracker <= '1';
		  tracker_func_sel <= '0';
		  group_addr_to_tracker <= free_group_addr; -- group addr      
      END IF;
    END IF;

    IF state = search THEN
      nstate <= search;
      IF search_done_bit = '1' THEN
	  if flag_malloc_failed = '0' then 
		nstate <= track;		
		  start_tracker <= '1';
		  tracker_func_sel <= '0';
		  group_addr_to_tracker <= search0_addr; -- group addr 	  			
		else -- if search for allocation failed
		nstate <= done_state;
	   end if;
      END IF;
    END IF;

    IF state = track THEN
		nstate <= track;
		if tracker_done = '1' then 
			nstate <= downmark;
			start_dmark <= '1';
			if flag_alloc = '1' then -- malloc
			dmark_start_probe <= search_done_probe;
			else
			dmark_start_probe <= free_info_probe_out	;		
			end if;
		end if;
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
        nstate <= done_state;
      END IF;
    END IF;

    IF state = done_state THEN
      nstate <= idle;                   -- done -> idle
	  done <= '1';
    END IF;
    
  END PROCESS;

  P1 : PROCESS

  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    IF reset = '0' THEN                 -- active low
      state <= idle;
    ELSE
      state <= nstate;                  -- default
	  
    END IF;
    
  END PROCESS;

  p2 : PROCESS(state,
               search0_addr,
               down0_we, down0_addr, down0_data_in,
               up0_we, up0_addr, up0_data_in,
               ram0_data_out,
			   cblock_ram_addr,cblock_ram_data_out)           -- select ram signals
  BEGIN

		-- default
 --   IF state = downmark THEN
      ram0_we        <= down0_we;
      ram0_addr      <= down0_addr;
      ram0_data_in   <= down0_data_in;
      down0_data_out <= ram0_data_out;
 --   END IF;
	
	if state = malloc1 then 
    ram0_addr        <= cblock_ram_addr;
    cblock_ram_data_out <= ram0_data_out ;
	end if;

    IF state = search THEN
      ram0_addr        <= search0_addr;
      search0_data_out <= ram0_data_out;
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



