LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY locator IS
  PORT(
    clk              : IN    std_logic;
    reset            : IN    std_logic;
    start            : IN    std_logic;
    search_status    : INOUT std_logic;  -- found = 1
    alvec            : INOUT std_logic;  -- allocation vector usage flag
    size             : IN    std_logic_vector(31 DOWNTO 0);
    verti            : INOUT std_logic_vector(31 DOWNTO 0);  -- vertical index of group
    horiz            : INOUT std_logic_vector(31 DOWNTO 0);  -- horizontal index of group                                               
    node_sel         : INOUT std_logic_vector(2 DOWNTO 0);  --  node select (0 to 7)
    node_sel_phy     : INOUT std_logic_vector(2 DOWNTO 0);  --  physical version
    saddr            : INOUT std_logic_vector(31 DOWNTO 0);  -- starting address of the malloc
    row_base         : INOUT std_logic_vector(31 DOWNTO 0);
    direction        : INOUT std_logic_vector(31 DOWNTO 0);  -- DOWN = 0, UP = 1
    group_addr       : INOUT std_logic_vector(31 DOWNTO 0);
    total_mem_blocks : IN    std_logic_vector(31 DOWNTO 0)
    );
END ENTITY locator;

ARCHITECTURE synth_locator OF locator IS
  SIGNAL top_node_size : std_logic_vector(31 DOWNTO 0);
BEGIN

END ARCHITECTURE;


