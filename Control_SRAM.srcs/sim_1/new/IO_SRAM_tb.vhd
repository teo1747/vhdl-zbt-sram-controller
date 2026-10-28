library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_ctrl is
end entity;

architecture sim of tb_sram_ctrl is

    ------------------------------------------------------------------
    -- Clock
    ------------------------------------------------------------------
    constant Tclk : time := 30 ns;
    signal clk    : std_logic := '0';
    signal reset  : std_logic := '1';

    ------------------------------------------------------------------
    -- Manual command interface
    ------------------------------------------------------------------
    signal wr_en   : std_logic := '0';
    signal rd_en   : std_logic := '0';
    signal addr_i : std_logic_vector(18 downto 0);
    signal wdata  : std_logic_vector(35 downto 0);
    signal rdata  : std_logic_vector(35 downto 0);

    ------------------------------------------------------------------
    -- SRAM interface
    ------------------------------------------------------------------
    signal DQ     : std_logic_vector(35 downto 0);
    signal Addr   : std_logic_vector(18 downto 0);
    signal nCKE   : std_logic;
    signal nADVLD : std_logic;
    signal nRW    : std_logic;
    signal nOE    : std_logic;
    signal nCE    : std_logic;
    signal nCE2   : std_logic;
    signal CE2    : std_logic;

    ------------------------------------------------------------------
    -- SRAM model
    ------------------------------------------------------------------
    component mt55l512y36f
        generic (
            addr_bits : integer := 19;
            data_bits : integer := 36
        );
        port (
            Dq    : inout std_logic_vector (data_bits-1 downto 0);
            Addr  : in    std_logic_vector (addr_bits-1 downto 0);
            Lbo_n : in    std_logic;
            Clk   : in    std_logic;
            Cke_n : in    std_logic;
            Ld_n  : in    std_logic;
            Bwa_n : in    std_logic;
            Bwb_n : in    std_logic;
            Bwc_n : in    std_logic;
            Bwd_n : in    std_logic;
            Rw_n  : in    std_logic;
            Oe_n  : in    std_logic;
            Ce_n  : in    std_logic;
            Ce2_n : in    std_logic;
            Ce2   : in    std_logic;
            Zz    : in    std_logic
        );
    end component;

begin

    ------------------------------------------------------------------
    -- Clock generation
    ------------------------------------------------------------------
    clk <= not clk after Tclk/2;

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    dut : entity work.sram_ctrl2
        port map (
            clk     => clk,
            reset   => reset,
            wr_en   => wr_en,
            rd_en   => rd_en,
            addr_i  => addr_i,
            wdata_i => wdata,
            rdata_o => rdata,
            DQ      => DQ,
            Addr    => Addr,
            nCKE    => nCKE,
            nADVLD  => nADVLD,
            nRW     => nRW,
            nOE     => nOE,
            nCE     => nCE,
            nCE2    => nCE2,
            CE2     => CE2
        );

    ------------------------------------------------------------------
    -- SRAM model instantiation
    ------------------------------------------------------------------
    sram : mt55l512y36f
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
    -- Test sequence
    ------------------------------------------------------------------
    stim : process
    begin
        ------------------------------------------------------------------
        -- Reset
        ------------------------------------------------------------------
        reset <= '1';
        wait for 2*Tclk;
        reset <= '0';
        wait for Tclk;

        ------------------------------------------------------------------
        -- WRITE 4 words (back-to-back, 1 per cycle)
        ------------------------------------------------------------------
        wr_en  <= '1';
        addr_i <= "000"&x"0001";
        wdata  <= x"AAAAAAAAA";
        wait for Tclk;

        addr_i <= "000"&x"0002";
        wdata  <= x"BBBBBBBBB";
        wait for Tclk;

        addr_i <= "000"&x"0003";
        wdata  <= x"CCCCCCCCC";
        wait for Tclk;

        addr_i <= "000"&x"0004";
        wdata  <= x"DDDDDDDDD";
        wait for Tclk;

        wr_en <= '0';

        ------------------------------------------------------------------
        -- READ 4 words
        ------------------------------------------------------------------
        wait for Tclk;

        rd_en  <= '1';
        addr_i <= "000"&x"0001";
        wait for Tclk;

        addr_i <= "000"&x"0002";
        wait for Tclk;

        addr_i <= "000"&x"0003";
        wait for Tclk;

        addr_i <= "000"&x"0004";
        wait for Tclk;

        rd_en <= '0';

        ------------------------------------------------------------------
        -- End simulation
        ------------------------------------------------------------------
        wait for 5*Tclk;
        assert false report "Simulation finished successfully" severity failure;
    end process;

end architecture;
