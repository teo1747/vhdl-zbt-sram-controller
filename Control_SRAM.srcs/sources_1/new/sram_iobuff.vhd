library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity sram_ctrl3 is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;

        wr_en    : in  std_logic;
        rd_en    : in  std_logic;
        burst_en : in  std_logic;

        addr_i   : in  std_logic_vector(18 downto 0);
        wdata_i  : in  std_logic_vector(35 downto 0);
        wdata_burst_i : in std_logic_vector(143 downto 0); -- 4 x 36 bits

        rdata_o        : out std_logic_vector(35 downto 0);
        rdata_burst_o  : out std_logic_vector(143 downto 0);

        -- SRAM interface
        DQ       : inout std_logic_vector(35 downto 0);
        Addr     : out   std_logic_vector(18 downto 0);

        nCKE     : out std_logic;
        nADVLD   : out std_logic;
        nRW      : out std_logic;
        nOE      : out std_logic;
        nCE      : out std_logic;
        nCE2     : out std_logic;
        CE2      : out std_logic
    );
end entity;


architecture rtl of sram_ctrl3 is

    type state_t is (
        IDLE,
        READ_ADDR, READ_DATA,
        WRITE_ADDR, WRITE_DATA,
        BURST_RD,
        BURST_WR
    );

    signal state      : state_t;
    signal dq_out     : std_logic_vector(35 downto 0);
    signal dq_in      : std_logic_vector(35 downto 0);
    signal dq_t       : std_logic;
    signal burst_cnt  : unsigned(1 downto 0);
    signal burst      : std_logic;

begin

    ------------------------------------------------------------------
    -- Constant signals
    ------------------------------------------------------------------
    nCKE <= '0';
    nCE2 <= '0';
    CE2  <= '1';

    ------------------------------------------------------------------
    -- IOBUF
    ------------------------------------------------------------------
    gen_iobuf : for i in 0 to 35 generate
        IOBUF_inst : IOBUF_F_16
            port map (
                I  => dq_out(i),
                IO => DQ(i),
                T  => dq_t,
                O  => dq_in(i)
            );
    end generate;

    ------------------------------------------------------------------
    -- FSM
    --
    -- The SRAM samples the commands one clock after the FSM sets them.
    -- It takes write data one clock after the write command and gives
    -- read data one clock after the read command (flow-through).
    -- Between operations the FSM deselects the SRAM (nCE = 1 with
    -- nADVLD = 0): nADVLD = 1 would continue the last burst and, after
    -- a write, write the released bus into the next addresses.
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state           <= IDLE;
                dq_t            <= '1';
                nCE             <= '1';
                nADVLD          <= '0';
                nRW             <= '1';
                nOE             <= '1';
                burst           <= '0';
                burst_cnt       <= (others => '0');
                rdata_o         <= (others => '0');
                rdata_burst_o   <= (others => '0');

            else
                case state is

                    --------------------------------------------------
                    when IDLE =>
                        dq_t   <= '1';
                        nOE    <= '1';
                        nCE    <= '1';     -- deselect
                        nADVLD <= '0';
                        burst  <= burst_en;

                        if rd_en = '1' then
                            Addr   <= addr_i;
                            nCE    <= '0';
                            nRW    <= '1';
                            nOE    <= '0';
                            state  <= READ_ADDR;

                        elsif wr_en = '1' then
                            Addr   <= addr_i;
                            nCE    <= '0';
                            nRW    <= '0';
                            dq_out <= wdata_i;
                            state  <= WRITE_ADDR;
                        end if;

                    --------------------------------------------------
                    -- READ: the SRAM takes the address now
                    --------------------------------------------------
                    when READ_ADDR =>
                        burst_cnt <= "00";
                        if burst = '1' then
                            nADVLD <= '1';  -- continue: next 3 words
                            state  <= BURST_RD;
                        else
                            nCE    <= '1';  -- deselect
                            state  <= READ_DATA;
                        end if;

                    when READ_DATA =>
                        rdata_o <= dq_in;
                        nOE     <= '1';
                        state   <= IDLE;

                    --------------------------------------------------
                    -- WRITE: the SRAM takes the address now and the
                    -- data at the next clock
                    --------------------------------------------------
                    when WRITE_ADDR =>
                        dq_t <= '0';
                        if burst = '1' then
                            dq_out    <= wdata_burst_i(35 downto 0);
                            nADVLD    <= '1';
                            burst_cnt <= "01";
                            state     <= BURST_WR;
                        else
                            nCE       <= '1';
                            state     <= WRITE_DATA;
                        end if;

                    when WRITE_DATA =>
                        dq_t  <= '1';
                        state <= IDLE;

                    --------------------------------------------------
                    -- BURST READ (4 words), one word each clock
                    --------------------------------------------------
                    when BURST_RD =>
                        rdata_burst_o(
                            (to_integer(burst_cnt)+1)*36-1 downto
                            to_integer(burst_cnt)*36
                        ) <= dq_in;

                        if burst_cnt = "10" then
                            nCE    <= '1';  -- the 4th word is the last
                            nADVLD <= '0';
                        end if;

                        if burst_cnt = "11" then
                            nOE   <= '1';
                            state <= IDLE;
                        else
                            burst_cnt <= burst_cnt + 1;
                        end if;

                    --------------------------------------------------
                    -- BURST WRITE (4 different words)
                    --------------------------------------------------
                    when BURST_WR =>
                        dq_out <= wdata_burst_i(
                                      (to_integer(burst_cnt)+1)*36-1 downto
                                      to_integer(burst_cnt)*36
                                  );

                        if burst_cnt = "11" then
                            nCE    <= '1';  -- the 4th word is the last
                            nADVLD <= '0';
                            state  <= WRITE_DATA;
                        else
                            burst_cnt <= burst_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end architecture;
