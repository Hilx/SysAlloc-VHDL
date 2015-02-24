LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY buddy IS
  PORT(
    clk     : IN  std_logic;
    reset   : IN  std_logic;
    start   : IN  std_logic;
    command : IN  std_logic_vector(1 DOWNTO 0);
    done    : OUT std_logic;    
    size    : IN  std_logic_vector(2 DOWNTO 0);
    address : IN  std_logic_vector(2 DOWNTO 0);
    result  : OUT std_logic_vector(3 DOWNTO 0)
    );
END ENTITY buddy;


ARCHITECTURE synth OF buddy IS  
  TYPE stateType IS (s_ready, s_alloc1, s_alloc2, s_alloc3, s_flip, s_free, s_done);
  SIGNAL state       : stateType := s_ready;
  SIGNAL AllocStatus : std_logic := '0';
  --flipper signals
  SIGNAL fstart      : std_logic;
  SIGNAL freset      : std_logic;
  SIGNAL fdone       : std_logic;
  SIGNAL faddress    : std_logic_vector(2 DOWNTO 0);
  SIGNAL FlipVec     : std_logic_vector(7 DOWNTO 0);
  SIGNAL MemStatus   : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL address_i   : std_logic_vector(2 DOWNTO 0)  := (OTHERS => '0');  --internal
  SIGNAL SizeVec     : std_logic_vector(3 DOWNTO 0)        := (OTHERS => '0');
BEGIN
  flipper_block : ENTITY flipper PORT MAP (
    clk      => clk,
    reset    => reset,
    fstart   => fstart,
    freset   => freset,
    size     => size,
    faddress => faddress,
    fdone    => fdone,
    flipout  => FlipVec);
  REG_P0 : PROCESS
    VARIABLE address_v : std_logic_vector(2 DOWNTO 0);
    VARIABLE AvaCheck : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');

    VARIABLE OrTreeL0 : std_logic                    := '0';
    VARIABLE OrTreeL1 : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
    VARIABLE OrTreeL2 : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');

    VARIABLE AndTreeL0 : std_logic                    := '0';
    VARIABLE AndTreeL1 : std_logic_vector(1 DOWNTO 0) := (OTHERS => '1');
    VARIABLE AndTreeL2 : std_logic_vector(3 DOWNTO 0) := (OTHERS => '1');
    VARIABLE AndTreeL3 : std_logic_vector(7 DOWNTO 0) := (OTHERS => '1');

    VARIABLE AddrTreeL0 : std_logic                    := '0';
    VARIABLE AddrTreeL1 : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
    VARIABLE AddrTreeL2 : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';

 IF reset = '0' THEN 
      state     <= s_ready;
      AvaCheck  := (OTHERS => '0');
      MemStatus <= (OTHERS => '0');

 ELSE 
      IF state = s_ready THEN
        done        <= '0';
        AllocStatus <= '0';
        SizeVec     <= (OTHERS => '0');
        CASE start IS
          WHEN '0' => state <= s_ready;
          WHEN '1' =>
            CASE command IS
              WHEN "00"    => state <= s_alloc1;
              WHEN "01"    => state <= s_free;
              WHEN OTHERS => NULL;
            END CASE;
          WHEN OTHERS => NULL;
        END CASE;
        AndTreeL1 := (OTHERS => '1');
        AndTreeL2 := (OTHERS => '1');
        AndTreeL3 := (OTHERS => '1');
      END IF;

      IF state = s_alloc1 THEN          -- check allocation availability

        FOR i IN 0 TO 3 LOOP
          OrTreeL2(i) := MemStatus(i*2) OR MemStatus(i*2+1);
        END LOOP;
        FOR i IN 0 TO 1 LOOP
          OrTreeL1(i) := OrTreeL2(i*2) OR OrTreeL2(i*2+1);
        END LOOP;
        OrTreeL0 := OrTreeL1(0) OR OrTreeL1(1);

        AvaCheck(3) := OrTreeL0;
        AvaCheck(2) := OrTreeL1(0) AND OrTreeL1(1);
        AvaCheck(1) := OrTreeL2(0) AND OrTreeL2(1) AND OrTreeL2(2) AND OrTreeL2(3);
        AvaCheck(0) := MemStatus(0) AND MemStatus(1) AND MemStatus(2) AND MemStatus(3) AND MemStatus(4) AND MemStatus(5) AND MemStatus(6) AND MemStatus(7);

        state <= s_done;
        IF size(2) = '0' THEN
          IF size(1) = '0' THEN
            IF size(0) = '0' THEN
              IF AvaCheck(0) = '0' THEN
                state      <= s_alloc2;
                SizeVec(0) <= '1';
              END IF;
            ELSIF AvaCheck(1) = '0' THEN
              state      <= s_alloc2;
              SizeVec(1) <= '1';
            END IF;
          ELSIF AvaCheck(2) = '0' THEN
            state      <= s_alloc2;
            SizeVec(2) <= '1';
          END IF;
        ELSIF AvaCheck(3) = '0' THEN
          state      <= s_alloc2;
          SizeVec(3) <= '1';
        END IF;
      END IF;

      IF state = s_alloc2 THEN
        state       <= s_alloc3;
        AllocStatus <= '1';
        CASE to_integer(unsigned(SizeVec)) IS
          WHEN 1 => AndTreeL3 := MemStatus;
          WHEN 2 =>
            FOR i IN 0 TO 3 LOOP
              AndTreeL3(i*2) := OrTreeL2(i);
            END LOOP;
          WHEN 4 =>
            FOR i IN 0 TO 1 LOOP
              AndTreeL3(i*4) := OrTreeL1(i);
            END LOOP;
          WHEN 8 =>
              AndTreeL3(0) := OrTreeL0;
          WHEN OTHERS => NULL;
        END CASE;

        FOR i IN 0 TO 3 LOOP
          AndTreeL2(i)  := AndTreeL3(i*2) AND AndTreeL3(i*2+1);
          AddrTreeL2(i) := AndTreeL3(i*2);
        END LOOP;
        FOR i IN 0 TO 1 LOOP
          AndTreeL1(i)  := AndTreeL2(i*2) AND AndTreeL2(i*2+1);
          AddrTreeL1(i) := AndTreeL2(i*2);
        END LOOP;
        AndTreeL0  := AndTreeL1(0) AND AndTreeL1(1);
        AddrTreeL0 := AndTreeL1(0);
 
        address_i(2) <= AddrTreeL0;
        address_v(2) := AddrTreeL0;
        address_i(1) <= AddrTreeL1(to_integer(unsigned(address_v(2 DOWNTO 2))));
        address_v(1) := AddrTreeL1(to_integer(unsigned(address_v(2 DOWNTO 2))));
        address_i(0) <= AddrTreeL2(to_integer(unsigned(address_v(2 DOWNTO 1))));
      END IF;
      IF state = s_alloc3 THEN
        --start flipper
        fstart   <= '1';
        faddress <= address_i;

        state <= s_flip;
      END IF;

      IF state = s_flip THEN
        fstart <= '0';
        IF fdone = '1' THEN
          state  <= s_done;
          freset <= '1';         
          FOR i IN 0 TO 7 LOOP
            IF FlipVec(i) = '1' THEN
              MemStatus(i) <= NOT MemStatus(i);
            END IF;
          END LOOP;
        END IF;
      END IF;

      IF state = s_done THEN
        freset <= '0';
        done   <= '1';

        state <= s_ready;
      END IF;

      IF state = s_free THEN
        fstart   <= '1';
        faddress <= address;
        state    <= s_flip;
      END IF;

    END IF;
  END PROCESS;
  result <= AllocStatus & address_i(2 DOWNTO 0);
END ARCHITECTURE synth;