library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_ctrl_with_model is
end tb_sram_ctrl_with_model;

architecture behavior of tb_sram_ctrl_with_model is

    -- Clock period
    constant TCLK : time := 20 ns;

    -- Signals
    signal Clk   : std_logic := '0';
    signal Reset : std_logic := '1';

    -- SRAM interface signals
    signal DQ        : std_logic_vector(35 downto 0);
    signal Addr      : std_logic_vector(18 downto 0);
    signal nCKE      : std_logic;
    signal nADVLD    : std_logic;
    signal nRW       : std_logic;
    signal nOE       : std_logic;
    signal nCE       : std_logic;
    signal nCE2      : std_logic;
    signal CE2       : std_logic;
    signal Lbo_n     : std_logic := '1';
    signal Bwa_n     : std_logic := '0';
    signal Bwb_n     : std_logic := '0';
    signal Bwc_n     : std_logic := '0';
    signal Bwd_n     : std_logic := '0';
    signal Zz        : std_logic := '0';

    -- Internal signal to monitor read data
    signal DQ_read   : std_logic_vector(35 downto 0);

begin

    --------------------------------------------------------------------
    -- Instantiate the SRAM controller
    --------------------------------------------------------------------
    UUT: entity work.sram_ctrl1
        port map(
            Clk     => Clk,
            Reset   => Reset,
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

    --------------------------------------------------------------------
    -- Instantiate the actual SRAM model
    --------------------------------------------------------------------
    SRAM_INST: entity work.mt55l512y36f
        generic map(
            addr_bits => 19,
            data_bits => 36
        )
        port map(
            Dq    => DQ,
            Addr  => Addr,
            Lbo_n => Lbo_n,
            Clk   => Clk,
            Cke_n => nCKE,
            Ld_n  => nADVLD,
            Bwa_n => Bwa_n,
            Bwb_n => Bwb_n,
            Bwc_n => Bwc_n,
            Bwd_n => Bwd_n,
            Rw_n  => nRW,
            Oe_n  => nOE,
            Ce_n  => nCE,
            Ce2_n => nCE2,
            Ce2   => CE2,
            Zz    => Zz
        );

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            Clk <= '0';
            wait for TCLK/2;
            Clk <= '1';
            wait for TCLK/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Reset sequence
    --------------------------------------------------------------------
    reset_process : process
    begin
        Reset <= '1';
        wait for 50 ns;
        Reset <= '0';
        wait;
    end process;

    --------------------------------------------------------------------
    -- Monitor read data from SRAM
    --------------------------------------------------------------------
    

end behavior;
