library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

entity SRAM_CTRL is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        RW      : in  std_logic; -- 1 = READ, 0 = WRITE
        burst   : in  std_logic;

        addr_in : in  std_logic_vector(18 downto 0);
        din     : in  std_logic_vector(35 downto 0);
        dout    : out std_logic_vector(35 downto 0);

        -- SRAM pins
        Dq      : inout std_logic_vector(35 downto 0);
        Addr    : out   std_logic_vector(18 downto 0);
        Rw_n    : out   std_logic;
        Ld_n    : out   std_logic;
        Oe_n    : out   std_logic;
        Ce_n    : out   std_logic;
        Ce2_n   : out   std_logic;
        Ce2     : out   std_logic;
        Cke_n   : out   std_logic;
        Bwa_n   : out   std_logic;
        Bwb_n   : out   std_logic;
        Bwc_n   : out   std_logic;
        Bwd_n   : out   std_logic
    );
end SRAM_CTRL;

architecture rtl of SRAM_CTRL is

    -- FSM states
    type state_t is (
        IDLE,
        READ_ADDR,
        READ_DATA,
        WRITE_ADDR,
        WRITE_DATA
    );

    signal state, next_state : state_t;

    -- Burst counter (4-beat burst)
    signal burst_cnt : unsigned(1 downto 0) := (others => '0');

    -- IOBUF signals
    signal dq_i : std_logic_vector(35 downto 0);
    signal dq_o : std_logic_vector(35 downto 0);
    signal dq_t : std_logic_vector(35 downto 0);

begin

    ------------------------------------------------------------------
    -- IOBUF GENERATION
    ------------------------------------------------------------------
    gen_iobuf : for i in 0 to 35 generate
        IOBUF_INST : IOBUF_F_16
            port map (
                I  => dq_i(i),
                O  => dq_o(i),
                IO => Dq(i),
                T  => dq_t(i)
            );
    end generate;

    ------------------------------------------------------------------
    -- FSM STATE REGISTER
    ------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            burst_cnt <= (others => '0');
        elsif rising_edge(clk) then
            state <= next_state;

            if burst = '1' then
                burst_cnt <= burst_cnt + 1;
            else
                burst_cnt <= (others => '0');
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- FSM NEXT STATE LOGIC
    ------------------------------------------------------------------
    process(state, RW, burst, burst_cnt)
    begin
        next_state <= state;

        case state is

            when IDLE =>
                if RW = '1' then
                    next_state <= READ_ADDR;
                else
                    next_state <= WRITE_ADDR;
                end if;

            when READ_ADDR =>
                next_state <= READ_DATA;

            when READ_DATA =>
                if burst = '1' and burst_cnt /= "11" then
                    next_state <= READ_ADDR;
                elsif RW = '0' then
                    next_state <= WRITE_ADDR;
                else
                    next_state <= READ_ADDR;
                end if;

            when WRITE_ADDR =>
                next_state <= WRITE_DATA;

            when WRITE_DATA =>
                if burst = '1' and burst_cnt /= "11" then
                    next_state <= WRITE_ADDR;
                elsif RW = '1' then
                    next_state <= READ_ADDR;
                else
                    next_state <= WRITE_ADDR;
                end if;

            when others =>
                next_state <= IDLE;

        end case;
    end process;

    ------------------------------------------------------------------
    -- FALLING EDGE: BUS DIRECTION + WRITE DATA
    ------------------------------------------------------------------
    process(clk)
    begin
        if falling_edge(clk) then
            case state is

                when WRITE_DATA =>
                    dq_t <= (others => '0'); -- drive bus
                    dq_i <= din;
                    Oe_n <= '1';

                when READ_ADDR | READ_DATA =>
                    dq_t <= (others => '1'); -- release bus
                    Oe_n <= '0';

                when others =>
                    dq_t <= (others => '1');
                    Oe_n <= '1';

            end case;
        end if;
    end process;

    ------------------------------------------------------------------
    -- RISING EDGE: SRAM CONTROL + READ DATA CAPTURE
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            -- defaults
            Ce_n  <= '0';
            Ce2_n <= '0';
            Ce2   <= '1';
            Cke_n <= '0';
            Bwa_n <= '0';
            Bwb_n <= '0';
            Bwc_n <= '0';
            Bwd_n <= '0';

            case state is

                when READ_ADDR =>
                    Rw_n <= '1';
                    Ld_n <= '0';

                when READ_DATA =>
                    Ld_n <= '1';
                    dout <= dq_o;

                when WRITE_ADDR =>
                    Rw_n <= '0';
                    Ld_n <= '0';

                when WRITE_DATA =>
                    Ld_n <= '1';

                when others =>
                    Rw_n <= '1';
                    Ld_n <= '1';

            end case;
        end if;
    end process;

    Addr <= addr_in;

end rtl;
