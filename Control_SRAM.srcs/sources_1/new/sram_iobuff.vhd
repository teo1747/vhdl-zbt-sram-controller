library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

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

begin

    ------------------------------------------------------------------
    -- Constant signals
    ------------------------------------------------------------------
    nCKE <= '0';
    nCE  <= '0';
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
    ------------------------------------------------------------------
    process(clk)
        variable burst_data : std_logic_vector(35 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state           <= IDLE;
                dq_t            <= '1';
                nADVLD          <= '1';
                nRW             <= '1';
                nOE             <= '1';
                burst_cnt       <= (others => '0');
                rdata_o         <= (others => '0');
                rdata_burst_o   <= (others => '0');

            else
                case state is

                    --------------------------------------------------
                    when IDLE =>
                        dq_t   <= '1';
                        nOE    <= '1';
                        nADVLD <= '1';

                        if rd_en = '1' then
                            Addr   <= addr_i;
                            nRW    <= '1';
                            nOE    <= '0';
                            nADVLD <= '0';

                            if burst_en = '1' then
                                burst_cnt <= "00";
                                state <= BURST_RD;
                            else
                                state <= READ_ADDR;
                            end if;

                        elsif wr_en = '1' then
                            Addr   <= addr_i;
                            nRW    <= '0';
                            nADVLD <= '0';

                            if burst_en = '1' then
                                dq_t      <= '0';
                                burst_cnt <= "00";
                                state <= BURST_WR;
                            else
                                dq_out <= wdata_i;
                                state  <= WRITE_ADDR;
                            end if;
                        end if;

                    --------------------------------------------------
                    -- SIMPLE READ
                    --------------------------------------------------
                    when READ_ADDR =>
                        nADVLD <= '1';
                        state  <= READ_DATA;

                    when READ_DATA =>
                        rdata_o <= dq_in;
                        nOE     <= '1';
                        state   <= IDLE;

                    --------------------------------------------------
                    -- SIMPLE WRITE
                    --------------------------------------------------
                    when WRITE_ADDR =>
                        nADVLD <= '1';
                        dq_t   <= '0';
                        state  <= WRITE_DATA;

                    when WRITE_DATA =>
                        dq_t  <= '1';
                        state <= IDLE;

                    --------------------------------------------------
                    -- BURST READ (4 words)
                    --------------------------------------------------
                    when BURST_RD =>
                        nADVLD <= '1';

                        rdata_burst_o(
                            (to_integer(burst_cnt)+1)*36-1 downto
                            to_integer(burst_cnt)*36
                        ) <= dq_in;

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
                        nADVLD <= '1';
                        dq_t   <= '0';

                        burst_data :=
                            wdata_burst_i(
                                (to_integer(burst_cnt)+1)*36-1 downto
                                to_integer(burst_cnt)*36
                            );

                        dq_out <= burst_data;

                        if burst_cnt = "11" then
                            dq_t  <= '1';
                            state <= IDLE;
                        else
                            burst_cnt <= burst_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end architecture;
