library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_sram_ctrl3 is
end entity;

architecture sim of tb_sram_ctrl3 is

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';

    signal wr_en    : std_logic := '0';
    signal rd_en    : std_logic := '0';
    signal burst_en : std_logic := '0';

    signal addr_i   : std_logic_vector(18 downto 0);
    signal wdata    : std_logic_vector(35 downto 0);
    signal wdata_burst : std_logic_vector(143 downto 0);

    signal rdata        : std_logic_vector(35 downto 0);
    signal rdata_burst  : std_logic_vector(143 downto 0);

    signal DQ       : std_logic_vector(35 downto 0);
    signal Addr     : std_logic_vector(18 downto 0);

    signal nCKE, nADVLD, nRW, nOE, nCE, nCE2, CE2 : std_logic;

begin

    clk <= not clk after 5 ns;

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    dut : entity work.sram_ctrl3
        port map (
            clk      => clk,
            reset    => reset,
            wr_en    => wr_en,
            rd_en    => rd_en,
            burst_en => burst_en,
            addr_i   => addr_i,
            wdata_i  => wdata,
            wdata_burst_i => wdata_burst,
            rdata_o        => rdata,
            rdata_burst_o  => rdata_burst,
            DQ       => DQ,
            Addr     => Addr,
            nCKE     => nCKE,
            nADVLD   => nADVLD,
            nRW      => nRW,
            nOE      => nOE,
            nCE      => nCE,
            nCE2     => nCE2,
            CE2      => CE2
        );

    ------------------------------------------------------------------
    -- SRAM MODEL (exact ports)
    ------------------------------------------------------------------
    sram : entity work.mt55l512y36f
        port map (
            Dq    => DQ,
            Addr  => Addr,
            Lbo_n => '0',
            Clk   => clk,
            Cke_n => nCKE,
            Ld_n  => nADVLD,
            Bwa_n => '0',
            Bwb_n => '0',
            Bwc_n => '0',
            Bwd_n => '0',
            Rw_n  => nRW,
            Oe_n  => nOE,
            Ce_n  => nCE,
            Ce2_n => nCE2,
            Ce2   => CE2,
            Zz    => '0'
        );

    ------------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------------
    process
    begin
        -- Reset
        wait for 20 ns;
        reset <= '0';

        -- SIMPLE WRITE
        addr_i <= std_logic_vector(to_unsigned(16#10#, 19));
        wdata  <= x"111111111";
        burst_en <= '0';
        wr_en <= '1';
        wait for 10 ns;
        wr_en <= '0';

        -- SIMPLE READ
        wait for 20 ns;
        rd_en <= '1';
        wait for 10 ns;
        rd_en <= '0';

        wait for 20 ns;
        

        -- BURST WRITE (4 different values)
        wdata_burst <=
            x"000000004" &
            x"000000003" &
            x"000000002" &
            x"000000001";

        addr_i   <= std_logic_vector(to_unsigned(16#40#, 19));
        burst_en <= '1';
        wr_en    <= '1';
        wait for 10 ns;
        wr_en    <= '0';

        -- BURST READ
        wait for 40 ns;
        rd_en <= '1';
        wait for 10 ns;
        rd_en <= '0';

        wait for 60 ns;

        
        wait;
    end process;

end architecture;
