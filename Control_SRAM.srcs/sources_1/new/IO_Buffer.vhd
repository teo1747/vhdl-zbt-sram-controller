----------------------------------------------------------------------------------

-- Company: 

-- Engineer: 

-- 

-- Create Date: 01.11.2025 21:23:33

-- Design Name: 

-- Module Name: IO_Buffer - Architectural Behaviour
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
---------------------------------------------------------------------------------- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library unisim;
use unisim.VComponents.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
 
entity IO_SRAM is

    Port ( Data_In   : in     STD_LOGIC_VECTOR(35 DOWNTO 0);
           Data_Out  : out    STD_LOGIC_VECTOR(35 DOWNTO 0);
           Addrs     : in     STD_LOGIC_VECTOR(18 DOWNTO 0);
           RW        : in     STD_LOGIC;
           CLK       : in     STD_LOGIC;
           Rst       : IN     STD_LOGIC;
           Dq        : INOUT  STD_LOGIC_VECTOR (35 DOWNTO 0);   -- Data I/O
           Addr      : OUT    STD_LOGIC_VECTOR (18 DOWNTO 0);   -- Address
           Lbo_n     : OUT    STD_LOGIC;                                   -- Burst Mode
           Cke_n     : OUT    STD_LOGIC;                                   -- Cke#
           Ld_n      : OUT    STD_LOGIC;                                   -- Adv/Ld#
           Bwa_n     : OUT    STD_LOGIC;                                   -- Bwa#
           Bwb_n     : OUT    STD_LOGIC;                                   -- BWb#
           Bwc_n     : OUT    STD_LOGIC;                                   -- Bwc#
           Bwd_n     : OUT    STD_LOGIC;                                   -- BWd#
           Rw_n      : OUT    STD_LOGIC;                                   -- RW#
           Oe_n      : OUT    STD_LOGIC;                                   -- OE#
           Ce_n      : OUT    STD_LOGIC;                                   -- CE#
           Ce2_n     : OUT    STD_LOGIC;                                   -- CE2#
           Ce2       : OUT    STD_LOGIC;                                   -- CE2
           Zz        : OUT    STD_LOGIC;                                  -- Snooze Mode
           --Burst Mode
           B_Start   : IN     STD_LOGIC
           );

end IO_SRAM;
 
architecture Behaviour of IO_SRAM is
 
component IOBUF_F_16

  port(
        O  : out   std_logic;
        IO : inout std_logic;
        I  : in    std_logic;
        T  : in    std_logic

    );

end component;

component BasculeFF
    generic (
    bus_width : integer := 35
    ); 
    Port ( D     : in  STD_LOGIC_VECTOR (bus_width downto 0);
           Q     : out STD_LOGIC_VECTOR (bus_width downto 0);
           enable: in  std_logic ;
           clk   : in  STD_LOGIC;
           reset : in  STD_LOGIC);
end component;
  
 
SIGNAL  Trig  : std_logic_vector(35 downto 0) := (others => '1');
SIGNAL  DataO : std_logic_vector(35 downto 0);
SIGNAL  DataI : std_logic_vector(35 downto 0);

SIGNAL  DataOut_reg: std_logic_vector(35 downto 0):= (others => '0');
SIGNAL  write_flag : std_logic;
SIGNAL  read_flag  : std_logic;
 
Type Machine_State is ( IDLE, CONFIG, READ, WRITE, Burst_WRITE, Burst_READ, BUSRT_MODE); 
SIGNAL STATE : Machine_State;

SIGNAL  Burst_Count : Integer range 0 to 3 := 0;

 
SIGNAL  reset                 :  std_logic; 
SIGNAL  enable                :  std_logic; 
SIGNAL  D, D_temp             :  std_logic_vector(35 downto 0);  
SIGNAL  Q , DataI_temp        :  std_logic_vector(35 downto 0);
  

 
begin

    Clocking: BasculeFF 
        port map ( 
                    D => D,
                    Q => Q,
                    clk     => clk,
                    reset   =>  reset,   
                    enable  =>  enable      
                );
        
        

    Loop_gen: for i in 0 to 35 generate

        Buffer_generate: IOBUF_F_16

            port map(
                        O  => DataO(i),
                        IO => Dq(i),
                        I  => DataI(i),
                        T  => Trig(i)
            );       

    end generate;
    
                Ce_n     <= '0';
                Ce2_n    <= '0';
                Ce2      <= '1';
               
                Lbo_n    <= '0';  
                
                Bwa_n    <= '0';
                Bwb_n    <= '0';
                Bwc_n    <= '0';
                Bwd_n    <= '0';
                Zz       <= '0';

 
Steps: Process(clk,rst) 

    begin 
        if(rst = '1')then
            STATE <= IDLE;
    
        elsif  rising_edge(clk) then
           case STATE is
            when CONFIG =>
            when IDLE  =>
                if (RW = '0') then --moi je veut lire
                   STATE <= READ;
                elsif (RW = '1') then
                   STATE <= WRITE;
                else
                   STATE <= IDLE;  
                end if;

            when WRITE =>
                if (RW = '1') then -- ont veut ecrire
                   STATE <= WRITE;
                else
                   STATE <= READ;
                end if;

            when READ =>
                if (Rw = '1') then 
                    STATE <= WRITE;
                else
                    STATE <= READ; 
                end if;
           when Burst_WRITE =>
            if B_start = '1' then 
                if RW = '1' then 
                    StATE <= Burst_WRITE;
                else
                    STATE <= Burst_READ;
                end if;
            end if;    
            when Burst_READ =>
            if B_start = '1' then 
                if RW = '0' then 
                    StATE <= Burst_READ;
                else
                    STATE <= Burst_WRITE;
                end if;
            end if;
            if Burst_Count = 3 then 
                STATE <= IDLE;
            else 
                Burst_count <= Burst_Count + 1;
            end if;
        
            when others =>
                STATE <= IDLE;
            end case; 
              
        end if ;  
    end process;


Triggering_steps:Process(STATE,CLK)
    begin
        if falling_edge(clk) then 
            Case STATE is 
                when WRITE => 
                    Oe_n <= '1';
                    Trig <= (others => '0'); 
                    DataI_temp <= Data_In; 
                    DataI <=DataI_temp; 
                    
                when READ =>
                    Trig <= (others => '1'); 
                    Oe_n <= '0';-- active la sortie de la sram
                    
--                Ld_n     <= '1';
                
--                when BURST_READ =>
--                when BURST_READ =>

            when others =>
--                Trig <= (others => '1');
            end case;
         end if;
    end process;


Output: Process(CLK)
    begin
        if rising_edge(clk) then
            Case STATE is 
                when WRITE => 
                    Rw_n <= '0';
                    Cke_n    <= '0';
--                    Trig <= (others => '0');
                    
                    
                when READ =>
                    RW_n <= '1'; 
                    Cke_n    <= '0';
--                    Trig <= (others => '1');
--                Ld_n     <= '1';
                
--                when BURST_READ =>
--                when BURST_READ =>

            when others => 
            RW_n <= '1';
            Cke_n    <= '1';
               
            end case;
         
     
            if RW = '0' then
                enable <= '1';
                 D <= DataO;           
            else
                enable <= '0';              
            end if;                  
        end if;       
    end process;
    Addr <= Addrs;
   Data_Out <= Q;
end behaviour;
 