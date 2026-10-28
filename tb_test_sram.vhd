
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:30:51 02/21/2007
-- Design Name:   test_io
-- Module Name:   D:/users/infotronique/jd/test/tb_test_io.vhd
-- Project Name:  test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: test_io
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY tb_test_sram IS
END tb_test_sram ;

ARCHITECTURE behavior OF tb_test_sram IS 

	-- Component Declaration for the Unit Under Test (UUT)
  component mt55l512y36f is
    generic (
      -- Constant parameters
      addr_bits : integer := 19;
      data_bits : integer := 36;

      -- Timing parameters for -10 (100 Mhz)
      tKHKH : time := 10.0 ns;
      tKHKL : time := 2.5 ns;
      tKLKH : time := 2.5 ns;
      tKHQV : time := 5.0 ns;
      tAVKH : time := 2.0 ns;
      tEVKH : time := 2.0 ns;
      tCVKH : time := 2.0 ns;
      tDVKH : time := 2.0 ns;
      tKHAX : time := 0.5 ns;
      tKHEX : time := 0.5 ns;
      tKHCX : time := 0.5 ns;
      tKHDX : time := 0.5 ns
      );

    -- Port Declarations
    port (
      Dq    : inout std_logic_vector (data_bits - 1 downto 0);  -- Data I/O
      Addr  : in    std_logic_vector (addr_bits - 1 downto 0);  -- Address
      Lbo_n : in    std_logic;                                  -- Burst Mode
      Clk   : in    std_logic;                                  -- Clk
      Cke_n : in    std_logic;                                  -- Cke#
      Ld_n  : in    std_logic;                                  -- Adv/Ld#
      Bwa_n : in    std_logic;                                  -- Bwa#
      Bwb_n : in    std_logic;                                  -- BWb#
      Bwc_n : in    std_logic;                                  -- Bwc#
      Bwd_n : in    std_logic;                                  -- BWd#
      Rw_n  : in    std_logic;                                  -- RW#
      Oe_n  : in    std_logic;                                  -- OE#
      Ce_n  : in    std_logic;                                  -- CE#
      Ce2_n : in    std_logic;                                  -- CE2#
      Ce2   : in    std_logic;                                  -- CE2
      Zz    : in    std_logic                                   -- Snooze Mode
      );
  end component;

	--constants
  	constant TCLKH    : time := 15 ns;
  	constant TCLKL    : time := 15 ns;

	--Inputs
	SIGNAL CLKO_SRAM :  std_logic := '0';
	SIGNAL nCKE :  std_logic := '0';
	SIGNAL nADVLD :  std_logic := '0';
	SIGNAL nRW:  std_logic := '0';
	SIGNAL nOE:  std_logic := '0';
	SIGNAL nCE:  std_logic := '0';
	SIGNAL nCE2:  std_logic := '0';
	SIGNAL CE2:  std_logic := '0';
	SIGNAL SA :  std_logic_vector(18 downto 0);

	--BiDirs
	SIGNAL DQ :  std_logic_vector(35 downto 0);


	

BEGIN
  process
  begin
    CLKO_SRAM <= '0';
    wait for TCLKL;
    CLKO_SRAM <= '1';
    wait for TCLKH;
  end process;

	-- Instantiate the Unit Under Test (UUT)
  SRAM1 : mt55l512y36f port map
    (DQ, SA, '0', CLKO_SRAM, nCKE, nADVLD, '0',
     '0', '0', '0', nRW, nOE, nCE, nCE2, CE2, '0');

	tb : PROCESS
BEGIN
    -- Initialize signals
    SA      <= (others => '0');
    nCKE    <= '0';
    nADVLD  <= '0';
    nRW     <= '1';  -- Read by default
    nOE     <= '0';
    nCE     <= '0';
    nCE2    <= '0';
    CE2     <= '1';
    DQ      <= (others => 'Z'); -- tri-state when not writing

    wait for 1*(TCLKL+TCLKH);

    ----------------------------------------------------------------
    -- WRITE 4 DATA WORDS
    ----------------------------------------------------------------
    -- Write 1
    SA      <= "000"&x"0001";
    DQ      <= x"AAAAAAAAA";  -- example data, 36-bit, adjust if needed
    nRW     <= '0';          -- write mode
    nCKE    <= '0';
    wait for 1*(TCLKL+TCLKH);

    -- Write 2
    SA      <= "000"&x"0002";
    DQ      <= x"BBBBBBBBB";
    wait for 1*(TCLKL+TCLKH);

    -- Write 3
    SA      <= "000"&x"0003";
    DQ      <= x"CCCCCCCCC";
    wait for 1*(TCLKL+TCLKH);

    -- Write 4
    SA      <= "000"&x"0004";
    DQ      <= x"DDDDDDDDD";
    wait for 1*(TCLKL+TCLKH);

    ----------------------------------------------------------------
    -- READ 4 DATA WORDS
    ----------------------------------------------------------------
    DQ      <= (others => 'Z'); -- tri-state for read
    nRW     <= '1';             -- read mode

    -- Read 1
    SA      <= "000"&x"0001";
    nCKE    <= '0';
    wait for 1*(TCLKL+TCLKH);

    -- Read 2
    SA      <= "000"&x"0002";
    wait for 1*(TCLKL+TCLKH);

    -- Read 3
    SA      <= "000"&x"0003";
    wait for 1*(TCLKL+TCLKH);

    -- Read 4
    SA      <= "000"&x"0004";
    wait for 1*(TCLKL+TCLKH);

    wait; -- end simulation
END PROCESS;

	
	

END;
