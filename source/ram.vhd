LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
use work.budpack.all;

ENTITY ram IS
  PORT(
    clk      : IN  std_logic;
    we       : IN  std_logic;
    address  : IN  std_logic_vector(31 DOWNTO 0);
    data_in  : IN  std_logic_vector(31 DOWNTO 0);
    data_out : OUT std_logic_vector(31 DOWNTO 0)
    );
END ENTITY ram;

ARCHITECTURE ram0 OF ram IS
  TYPE memory IS ARRAY(0 TO BRAM_SIZE) OF std_logic_vector(31 DOWNTO 0);
  SIGNAL myram                     : memory;
  ATTRIBUTE ram_init_file          : string;
  ATTRIBUTE ram_init_file OF myram : SIGNAL IS "ram_data.hex";
BEGIN
  PROCESS(clk)
  BEGIN
    IF (clk'event AND clk = '1') THEN
      IF (we = '1') THEN
        myram(to_integer(unsigned(address))) <= data_in;
      END IF;
    END IF;
  END PROCESS;
  data_out <= myram(to_integer(unsigned(address)));
END ARCHITECTURE ram0;
