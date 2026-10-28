library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_ctrl2 is
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;

        -- Manual command interface
        wr_en   : in  std_logic;
        rd_en   : in  std_logic;
        addr_i  : in  std_logic_vector(18 downto 0);
        wdata_i : in  std_logic_vector(35 downto 0);
        rdata_o : out std_logic_vector(35 downto 0);
        ready   : out std_logic;

        -- SRAM interface
        DQ      : inout std_logic_vector(35 downto 0);
        Addr    : out std_logic_vector(18 downto 0);
        nCKE    : out std_logic;
        nADVLD  : out std_logic;
        nRW     : out std_logic;
        nOE     : out std_logic;
        nCE     : out std_logic;
        nCE2    : out std_logic;
        CE2     : out std_logic
  );
end entity;

architecture rtl of sram_ctrl2 is

    type state_t is (IDLE, WRITE, READ);
    signal state : state_t := IDLE;

    signal dq_out : std_logic_vector(35 downto 0) := (others => '0');
    signal dq_oe  : std_logic := '0';  -- '1' when writing

begin

    DQ <= dq_out when dq_oe = '1' else (others => 'Z');

    process(clk, reset)
    begin
        if reset = '1' then
            state   <= IDLE;
            Addr    <= (others => '0');
            dq_out  <= (others => '0');
            dq_oe   <= '0';
            rdata_o <= (others => '0');
            ready   <= '1';

            nCKE   <= '0';
            nADVLD <= '0';
            nRW    <= '1';
            nOE    <= '1';
            nCE    <= '0';
            nCE2   <= '0';
            CE2    <= '1';

        elsif rising_edge(clk) then
            ready <= '0';

            case state is
                when IDLE =>
                    ready <= '1';
                    dq_oe <= '0';
                    nRW   <= '1';
                    nOE   <= '1';

                    if wr_en = '1' then
                        Addr    <= addr_i;
                        dq_out  <= wdata_i;
                        dq_oe   <= '1';
                        nRW     <= '0';
                        state   <= WRITE;
                    elsif rd_en = '1' then
                        Addr  <= addr_i;
                        dq_oe <= '0';
                        nRW   <= '1';
                        nOE   <= '0';
                        state <= READ;
                    end if;

                when WRITE =>
                    dq_oe <= '0';
                    nRW   <= '1';
                    if wr_en = '1' then
                        Addr    <= addr_i;
                        dq_out  <= wdata_i;
                        dq_oe   <= '1';
                        nRW     <= '0';
                        state   <= WRITE; -- stay in write if wr_en still high
                    else
                        state <= IDLE;
                    end if;

                when READ =>
                    rdata_o <= DQ;
                    nOE     <= '1';
                    if rd_en = '1' then
                        Addr    <= addr_i;
                        dq_oe   <= '0';
                        nRW     <= '1';
                        nOE     <= '0';
                        state   <= READ; -- stay in read if rd_en still high
                    else
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end rtl;
