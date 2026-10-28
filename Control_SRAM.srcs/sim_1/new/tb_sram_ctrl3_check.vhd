-- Self-checking testbench for sram_ctrl3 with the Micron MT55L512Y36F model:
-- single writes and reads with idle clocks between them, then a burst of
-- four words, then the single words again. Reports each check and the
-- number of errors at the end.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_sram_ctrl3_check is
end entity;

architecture sim of tb_sram_ctrl3_check is

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal done     : boolean := false;

    signal wr_en    : std_logic := '0';
    signal rd_en    : std_logic := '0';
    signal burst_en : std_logic := '0';

    signal addr_i      : std_logic_vector(18 downto 0) := (others => '0');
    signal wdata       : std_logic_vector(35 downto 0) := (others => '0');
    signal wdata_burst : std_logic_vector(143 downto 0) := (others => '0');

    signal rdata       : std_logic_vector(35 downto 0);
    signal rdata_burst : std_logic_vector(143 downto 0);

    signal DQ       : std_logic_vector(35 downto 0);
    signal Addr     : std_logic_vector(18 downto 0);
    signal nCKE, nADVLD, nRW, nOE, nCE, nCE2, CE2 : std_logic;

    -- The controller's outputs 1 ns after the clock, as on the board
    signal Addr_d   : std_logic_vector(18 downto 0);
    signal nCKE_d, nADVLD_d, nRW_d, nOE_d, nCE_d, nCE2_d, CE2_d : std_logic;

    function to_hex(v : std_logic_vector) return string is
        constant digits : string(1 to 16) := "0123456789ABCDEF";
        alias    w      : std_logic_vector(v'length - 1 downto 0) is v;
        variable s      : string(1 to v'length / 4);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in s'range loop
            nibble := w(w'left - (i - 1) * 4 downto w'left - (i - 1) * 4 - 3);
            if is_x(nibble) then
                s(i) := 'X';
            else
                s(i) := digits(to_integer(unsigned(nibble)) + 1);
            end if;
        end loop;
        return s;
    end function;

begin

    clk <= not clk after 5 ns when not done;

    dut : entity work.sram_ctrl3
        port map (
            clk           => clk,
            reset         => reset,
            wr_en         => wr_en,
            rd_en         => rd_en,
            burst_en      => burst_en,
            addr_i        => addr_i,
            wdata_i       => wdata,
            wdata_burst_i => wdata_burst,
            rdata_o       => rdata,
            rdata_burst_o => rdata_burst,
            DQ            => DQ,
            Addr          => Addr,
            nCKE          => nCKE,
            nADVLD        => nADVLD,
            nRW           => nRW,
            nOE           => nOE,
            nCE           => nCE,
            nCE2          => nCE2,
            CE2           => CE2
        );

    Addr_d   <= Addr   after 1 ns;
    nCKE_d   <= nCKE   after 1 ns;
    nADVLD_d <= nADVLD after 1 ns;
    nRW_d    <= nRW    after 1 ns;
    nOE_d    <= nOE    after 1 ns;
    nCE_d    <= nCE    after 1 ns;
    nCE2_d   <= nCE2   after 1 ns;
    CE2_d    <= CE2    after 1 ns;

    sram : entity work.mt55l512y36f
        port map (
            Dq    => DQ,
            Addr  => Addr_d,
            Lbo_n => '0',
            Clk   => clk,
            Cke_n => nCKE_d,
            Ld_n  => nADVLD_d,
            Bwa_n => '0',
            Bwb_n => '0',
            Bwc_n => '0',
            Bwd_n => '0',
            Rw_n  => nRW_d,
            Oe_n  => nOE_d,
            Ce_n  => nCE_d,
            Ce2_n => nCE2_d,
            Ce2   => CE2_d,
            Zz    => '0'
        );

    process
        variable errors : natural := 0;

        procedure tick(n : natural := 1) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 2 ns;
        end procedure;

        procedure check(name : string; got, want : std_logic_vector) is
        begin
            if got /= want then
                report name & ": got " & to_hex(got) & ", expected " & to_hex(want)
                    severity error;
                errors := errors + 1;
            else
                report name & ": " & to_hex(got) & " ok";
            end if;
        end procedure;

        procedure write_word(a : natural; d : std_logic_vector(35 downto 0)) is
        begin
            addr_i   <= std_logic_vector(to_unsigned(a, 19));
            wdata    <= d;
            burst_en <= '0';
            wr_en    <= '1';
            tick;
            wr_en    <= '0';
            tick(6);
        end procedure;

        procedure read_word(a : natural) is
        begin
            addr_i   <= std_logic_vector(to_unsigned(a, 19));
            burst_en <= '0';
            rd_en    <= '1';
            tick;
            rd_en    <= '0';
            tick(6);
        end procedure;

    begin
        tick(3);
        reset <= '0';
        tick(2);

        -- Single words, with idle clocks between them
        write_word(16#10#, x"111111111");
        write_word(16#21#, x"222222222");
        write_word(16#32#, x"333333333");
        tick(20);
        read_word(16#10#);  check("read 0x10", rdata, x"111111111");
        read_word(16#21#);  check("read 0x21", rdata, x"222222222");
        read_word(16#32#);  check("read 0x32", rdata, x"333333333");

        -- Burst of four words at 0x40
        wdata_burst <= x"000000004" & x"000000003" & x"000000002" & x"000000001";
        addr_i      <= std_logic_vector(to_unsigned(16#40#, 19));
        burst_en    <= '1';
        wr_en       <= '1';
        tick;
        wr_en       <= '0';
        tick(20);
        rd_en       <= '1';
        tick;
        rd_en       <= '0';
        tick(10);
        check("burst word 0", rdata_burst(35 downto 0),    x"000000001");
        check("burst word 1", rdata_burst(71 downto 36),   x"000000002");
        check("burst word 2", rdata_burst(107 downto 72),  x"000000003");
        check("burst word 3", rdata_burst(143 downto 108), x"000000004");

        -- The single words must still be there
        read_word(16#10#);  check("read 0x10 again", rdata, x"111111111");
        read_word(16#21#);  check("read 0x21 again", rdata, x"222222222");
        read_word(16#32#);  check("read 0x32 again", rdata, x"333333333");

        report "end of test, " & integer'image(errors) & " error(s)";
        done <= true;
        wait;
    end process;

end architecture;
