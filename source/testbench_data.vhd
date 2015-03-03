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
		(1, malloc, 67, 0 ),
		(2, malloc, 67, 0),
		(3, malloc, 67, 0),
		(4, malloc, 67, 0),
		(5, free, 67, 0),
		(6, free, 67, 128),
		(7, malloc, 256, 0),
		(8, malloc, 67, 0)
	);
END PACKAGE tb_data;
