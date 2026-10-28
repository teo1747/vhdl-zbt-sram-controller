library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IO_SRAM_T is
end IO_SRAM_T;

architecture TB of IO_SRAM_T is

    -----------------------------------------------------------------
    -- DUT: SRAM controller
    -----------------------------------------------------------------
    component IO_SRAM
        Port ( 
            Data_In   : in     STD_LOGIC_VECTOR(35 DOWNTO 0);
            Data_Out  : out    STD_LOGIC_VECTOR(35 DOWNTO 0);
            Addrs     : in     STD_LOGIC_VECTOR(18 DOWNTO 0);
            RW        : in     STD_LOGIC;
            CLK       : in     STD_LOGIC;
            Rst       : in     STD_LOGIC;
            Dq        : inout  STD_LOGIC_VECTOR (35 DOWNTO 0);
            Addr      : out    STD_LOGIC_VECTOR (18 DOWNTO 0);
            Lbo_n, Cke_n, Ld_n,
            Bwa_n, Bwb_n, Bwc_n, Bwd_n,
            Rw_n, Oe_n, Ce_n, Ce2_n, Ce2, Zz : out STD_LOGIC
        );
    end component;

    -----------------------------------------------------------------
    -- SRAM memory model
    -----------------------------------------------------------------
    component mt55l512y36f is
        generic (
            addr_bits : integer := 19;
            data_bits : integer := 36
        );
        port (
            Dq        : inout std_logic_vector (data_bits - 1 downto 0);
            Addr      : in    std_logic_vector (addr_bits - 1 downto 0);
            Lbo_n     : in    std_logic;
            Clk       : in    std_logic;
            Cke_n     : in    std_logic;
            Ld_n      : in    std_logic;
            Bwa_n     : in    std_logic;
            Bwb_n     : in    std_logic;
            Bwc_n     : in    std_logic;
            Bwd_n     : in    std_logic;
            Rw_n      : in    std_logic;
            Oe_n      : in    std_logic;
            Ce_n      : in    std_logic;
            Ce2_n     : in    std_logic;
            Ce2       : in    std_logic;
            Zz        : in    std_logic
        );
    end component;

    -----------------------------------------------------------------
    -- Internal signals
    -----------------------------------------------------------------
    signal CLK_tb     : std_logic := '0';
    signal RST_tb     : std_logic := '0';
    signal RW_tb      : std_logic := '1';  -- '1' = WRITE, '0' = READ
    signal Data_In_tb : std_logic_vector(35 downto 0) := (others => '0');
    signal Data_Out_tb: std_logic_vector(35 downto 0);
    signal Addrs_tb   : std_logic_vector(18 downto 0) := (others => '0');

    -- SRAM signals
    signal Dq, Addr  : std_logic_vector(35 downto 0);
    signal Addr_sram : std_logic_vector(18 downto 0);
    signal Lbo_n, Cke_n, Ld_n, Bwa_n, Bwb_n, Bwc_n, Bwd_n,
           Rw_n, Oe_n, Ce_n, Ce2_n, Ce2, Zz : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -----------------------------------------------------------------
    -- Clock generation
    -----------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            CLK_tb <= '0';
            wait for CLK_PERIOD/2;
            CLK_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -----------------------------------------------------------------
    -- SRAM instance
    -----------------------------------------------------------------
    SRAM1 : mt55l512y36f
        port map (
            Clk    => CLK_tb,
            Dq     => Dq,
            Addr   => Addr_sram,
            Lbo_n  => Lbo_n,
            Cke_n  => Cke_n,
            Ld_n   => Ld_n,
            Bwa_n  => Bwa_n,
            Bwb_n  => Bwb_n,
            Bwc_n  => Bwc_n,
            Bwd_n  => Bwd_n,
            Rw_n   => Rw_n,
            Oe_n   => Oe_n,
            Ce_n   => Ce_n,
            Ce2_n  => Ce2_n,
            Ce2    => Ce2,
            Zz     => Zz
        );

    -----------------------------------------------------------------
    -- DUT: SRAM Controller instance
    -----------------------------------------------------------------
    DUT : IO_SRAM
        port map (
            Data_In  => Data_In_tb,
            Data_Out => Data_Out_tb,
            Addrs    => Addrs_tb,
            RW       => RW_tb,
            CLK      => CLK_tb,
            Rst      => RST_tb,
            Dq       => Dq,
            Addr     => Addr_sram,
            Lbo_n    => Lbo_n,
            Cke_n    => Cke_n,
            Ld_n     => Ld_n,
            Bwa_n    => Bwa_n,
            Bwb_n    => Bwb_n,
            Bwc_n    => Bwc_n,
            Bwd_n    => Bwd_n,
            Rw_n     => Rw_n,
            Oe_n     => Oe_n,
            Ce_n     => Ce_n,
            Ce2_n    => Ce2_n,
            Ce2      => Ce2,
            Zz       => Zz
        );

    -----------------------------------------------------------------
    -- Stimulus process: WRITE 4 values, then READ 4 values
    -----------------------------------------------------------------
    stim_proc : process
    begin
        -- Reset
        RST_tb <= '1';
        wait for 20 ns;
        RST_tb <= '0';
        wait for CLK_PERIOD;

        -----------------------------------------------------------------
        -- WRITE PHASE
        -----------------------------------------------------------------
        RW_tb <= '1';  -- WRITE mode
        for i in 0 to 3 loop
            Addrs_tb <= std_logic_vector(to_unsigned(i, Addrs_tb'length));
            Data_In_tb <= std_logic_vector(to_unsigned(i*5 + 1, Data_In_tb'length));
            wait for CLK_PERIOD;
        end loop;

        wait for 50 ns;

        -----------------------------------------------------------------
        -- READ PHASE
        -----------------------------------------------------------------
        RW_tb <= '0';  -- READ mode
        for i in 0 to 3 loop
            Addrs_tb <= std_logic_vector(to_unsigned(i, Addrs_tb'length));
            wait for CLK_PERIOD;
        end loop;

        wait;
    end process;

end TB;
