-- RAM-based Buddy Allocator
-- Created by Hilda Xue, 24 Feb 2015
-- This file contains the top level of the buddy allocator

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

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
END ENTITY buddy;

ARCHITECTURE synth OF rbuddy_top IS
  TYPE StateType IS (idle,
                     malloc,            -- preprocess info for search in malloc
                     free,              -- preprocess info for free
                     search,            -- search for malloc deciding group
                     track,             -- update tracker
                     downmark,          -- downward marking
                     upmark,            -- upward marking
                     done);
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

  SIGNAL search0_we       : std_logic;
  SIGNAL search0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL search0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL search0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL down0_we       : std_logic;
  SIGNAL down0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL donw0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL down0_data_out : std_logic_vector(31 DOWNTO 0);

  SIGNAL up0_we       : std_logic;
  SIGNAL up0_addr     : std_logic_vector(31 DOWNTO 0);
  SIGNAL up0_data_in  : std_logic_vector(31 DOWNTO 0);
  SIGNAL up0_data_out : std_logic_vector(31 DOWNTO 0);
  
BEGIN

  RAM0 : ENTITY ram
    PORT MAP(
      clk      => clk,
      we       => ram0_we,
      address  => ram0_addr,
      data_in  => ram0_data_in,
      data_out => ram0_data_out
      );

  P0 : PROCESS(state, start, cmd)       -- controls FSM, only writes nstate!

  BEGIN

    nstate <= idle;                     -- default value

    IF state = idle THEN
      nstate <= idle;
      IF start = '1' THEN
        nstate <= malloc;               -- cmd = 0 malloc
        IF cmd = '1' THEN               -- cmd = 1 free
          nstate <= free;
        END IF;
      END IF;
    END IF;

    IF state = malloc THEN
      --  nstate <= malloc;
      nstate <= search;  --for developing search block first, skip malloc state   
    END IF;

    IF state = free THEN
      nstate <= free;
    END IF;

    IF state = search THEN
      nstate <= search;
    END IF;

    IF state = track THEN
      nstate <= track;
    END IF;

    IF state = downmark THEN
      nstate <= downmark;
    END IF;

    IF state = upmark THEN
      nstate <= upmark;
    END IF;

    IF state = done THEN
      nstate <= idle;                   -- done -> idle
    END IF;
    
  END PROCESS;

  P1 : PROCESS

  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

    IF reset = '0' THEN                 -- active low
      state = idle;
    ELSE
      state = nstate;                   -- default
    END IF;
    
  END PROCESS;

  p2 : PROCESS(state,
               malloc0_we, malloc0_addr, malloc0_data_in, malloc0_data_out,
               search0_we, search0_addr, search0_data_in, search0_data_out,
               down0_we, down0_addr, donw0_data_in, down0_data_out,
               up0_we, up0_addr, up0_data_in, up0_data_out)  -- select ram signals
  BEGIN

    -- state = malloc (default)
    ram0_we       <= malloc0_we;
    ram0_addr     <= malloc0_addr;
    ram0_data_in  <= malloc0_data_in;
    ram0_data_out <= malloc0_data_out;

    IF state = search THEN
      ram0_we       <= search0_we;
      ram0_addr     <= search0_addr;
      ram0_data_in  <= search0_data_in;
      ram0_data_out <= search0_data_out;
    END IF;

    IF state = down THEN
      ram0_we       <= down0_we;
      ram0_addr     <= down0_addr;
      ram0_data_in  <= down0_data_in;
      ram0_data_out <= down0_data_out;
    END IF;

    IF state = up THEN
      ram0_we       <= up0_we;
      ram0_addr     <= up0_addr;
      ram0_data_in  <= up0_data_in;
      ram0_data_out <= up0_data_out;
    END IF;
    
  END PROCESS;

END ARCHITECTURE synth;



