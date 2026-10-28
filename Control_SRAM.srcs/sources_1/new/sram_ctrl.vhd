library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_ctrl1 is
    port(
        Clk      : in  std_logic;
        Reset    : in  std_logic;

        -- SRAM interface
        DQ       : inout std_logic_vector(35 downto 0);
        Addr     : out std_logic_vector(18 downto 0);
        nCKE     : out std_logic;
        nADVLD   : out std_logic;
        nRW      : out std_logic;
        nOE      : out std_logic;
        nCE      : out std_logic;
        nCE2     : out std_logic;
        CE2      : out std_logic
    );
end sram_ctrl1;

architecture rtl of sram_ctrl1 is

    type state_type is (
        IDLE,
        W1_SETUP, W1_EXEC,
        W2_SETUP, W2_EXEC,
        W3_SETUP, W3_EXEC,
        W4_SETUP, W4_EXEC,
        R1_SETUP, R1_EXEC,
        R2_SETUP, R2_EXEC,
        R3_SETUP, R3_EXEC,
        R4_SETUP, R4_EXEC,
        DONE
    );

    signal state : state_type := IDLE;

    signal DQ_out : std_logic_vector(35 downto 0) := (others => '0');
    signal DQ_oe  : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Bidirectional DQ control
    --------------------------------------------------------------------
    DQ <= DQ_out when DQ_oe = '1' else (others => 'Z');

    --------------------------------------------------------------------
    -- Main FSM
    --------------------------------------------------------------------
    process(Clk, Reset)
    begin
        if Reset = '1' then
            state  <= IDLE;
            Addr   <= (others => '0');
            DQ_out <= (others => '0');
            DQ_oe  <= '0';

            nRW    <= '1';
            nCKE   <= '0';
            nADVLD <= '0';
            nOE    <= '0';
            nCE    <= '0';
            nCE2   <= '0';
            CE2    <= '1';

        elsif rising_edge(Clk) then
            case state is

                ----------------------------------------------------------------
                -- IDLE
                ----------------------------------------------------------------
                when IDLE =>
                    state <= W1_SETUP;

                ----------------------------------------------------------------
                -- WRITE 1
                ----------------------------------------------------------------
                when W1_SETUP =>
                    Addr   <= "000"&x"0001";
                    DQ_out <= x"AAAAAAAAA";
                    DQ_oe  <= '1';
                    nRW    <= '0';
                    state  <= W1_EXEC;

                when W1_EXEC =>
                    state <= W2_SETUP;

                ----------------------------------------------------------------
                -- WRITE 2
                ----------------------------------------------------------------
                when W2_SETUP =>
                    Addr   <= "000"&x"0002";
                    DQ_out <= x"BBBBBBBBB";
                    state  <= W2_EXEC;

                when W2_EXEC =>
                    state <= W3_SETUP;

                ----------------------------------------------------------------
                -- WRITE 3
                ----------------------------------------------------------------
                when W3_SETUP =>
                    Addr   <= "000"&x"0003";
                    DQ_out <= x"CCCCCCCCC";
                    state  <= W3_EXEC;

                when W3_EXEC =>
                    state <= W4_SETUP;

                ----------------------------------------------------------------
                -- WRITE 4
                ----------------------------------------------------------------
                when W4_SETUP =>
                    Addr   <= "000"&x"0004";
                    DQ_out <= x"DDDDDDDDD";
                    state  <= W4_EXEC;

                when W4_EXEC =>
                    -- last write happens HERE
                    DQ_oe <= '0';
                    nRW   <= '1';
                    state <= R1_SETUP;

                ----------------------------------------------------------------
                -- READ 1
                ----------------------------------------------------------------
                when R1_SETUP =>
                    Addr  <= "000"&x"0001";
                    state <= R1_EXEC;

                when R1_EXEC =>
                    state <= R2_SETUP;

                ----------------------------------------------------------------
                -- READ 2
                ----------------------------------------------------------------
                when R2_SETUP =>
                    Addr  <= "000"&x"0002";
                    state <= R2_EXEC;

                when R2_EXEC =>
                    state <= R3_SETUP;

                ----------------------------------------------------------------
                -- READ 3
                ----------------------------------------------------------------
                when R3_SETUP =>
                    Addr  <= "000"&x"0003";
                    state <= R3_EXEC;

                when R3_EXEC =>
                    state <= R4_SETUP;

                ----------------------------------------------------------------
                -- READ 4
                ----------------------------------------------------------------
                when R4_SETUP =>
                    Addr  <= "000"&x"0004";
                    state <= R4_EXEC;

                when R4_EXEC =>
                    state <= DONE;

                ----------------------------------------------------------------
                -- DONE
                ----------------------------------------------------------------
                when DONE =>
                    null;

            end case;
        end if;
    end process;

end rtl;
