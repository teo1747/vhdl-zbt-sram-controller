library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

entity tb_iobuf_f_16 is
end entity;

architecture sim of tb_iobuf_f_16 is

    -- Clock
    signal clk    : std_logic := '0';
    constant Tclk : time := 10 ns;

    -- DUT signals
    signal O_tb  : std_logic;
    signal IO_tb : std_logic := 'Z';
    signal I_tb  : std_logic := '0';
    signal T_tb  : std_logic := '1';

begin

    --------------------------------------------------
    -- Clock generation
    --------------------------------------------------
    clk <= not clk after Tclk/2;

    --------------------------------------------------
    -- DUT
    --------------------------------------------------
    DUT : IOBUF_F_16
        port map (
            O  => O_tb,
            IO => IO_tb,
            I  => I_tb,
            T  => T_tb
        );

    --------------------------------------------------
    -- Stimulus (simple, explicit)
    --------------------------------------------------
    stim_proc : process
    begin

        -- INIT
        T_tb  <= '1';      -- Read mode
        I_tb  <= '1';
        IO_tb <= 'Z';
        wait for 30 ns;

        -- WRITE MODE : drive 1
        wait until rising_edge(clk);
        T_tb <= '0';
        I_tb <= '1';
        --IO_tb <= '1';
        wait for 40 ns;

        -- WRITE MODE : drive 0
        wait until rising_edge(clk);
        I_tb <= '1';
        --IO_tb <= '1';
        wait for 40 ns;

        -- SWITCH TO READ MODE
        wait until rising_edge(clk);
        T_tb <= '1';
         I_tb <= '1';
         --IO_tb <= '1';
        
        wait for 40 ns;

        -- READ MODE : external 0
        wait until rising_edge(clk);
        T_tb <= '0';
         I_tb <= '1';
         IO_tb <= 'Z';
        wait for 40 ns;

        -- FLOATING IO
        wait until rising_edge(clk);
        IO_tb <= 'Z';
        wait for 40 ns;

        -- END
        wait;
    end process;

end architecture;
