LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

PACKAGE tb_data IS
    TYPE cyc IS (   reset,  -- reset = '1'
                    start,  -- draw = '1', xin,yin are driven from xin,yin
                    done,   -- done output = 1
                    drawing -- reset,start,done = '0', xin, yin are undefined
                );

    TYPE data_t_rec IS
    RECORD
		req_index : integer;
       command : std_logic; -- 0 = allocation, 1 = free
	   size : integer;
	   address : integer;   	   
    END RECORD;
	
    TYPE data_t IS ARRAY (natural RANGE <>) OF data_t_rec;
	
	constant malloc : std_logic := '0';
	constant free : std_logic := '1';

    CONSTANT data: data_t :=(
		(1, malloc, 400, 0 ),
		(2, malloc, 32, 0),
		(3, free, 400, 0),
		(4, malloc, 188, 0),
		(5, malloc, 1, 0),
		(6, malloc, 1, 128),
		(7, free, 1, 189),
		(8, malloc, 2, 0)
	);
END PACKAGE tb_data;
