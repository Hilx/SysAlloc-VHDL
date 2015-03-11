LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

PACKAGE tb_data IS

  TYPE data_t_rec IS
  RECORD
    req_index : integer;
    command   : std_logic;              -- 0 = allocation, 1 = free
    size      : integer;
    address   : integer;
  END RECORD;

  TYPE data_t IS ARRAY (natural RANGE <>) OF data_t_rec;



  CONSTANT data : data_t := (
    (1, '0', 262145, 0),
    (2, '0', 524289, 0),
    (3, '0', 786433, 0),
    (4, '0', 524289, 0)
    );
END PACKAGE tb_data;
