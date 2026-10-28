
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2024 08:43:37
-- Design Name: 
-- Module Name: BasculeFF - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;


entity BasculeFF is
generic (
    bus_width : integer := 1
    ); 
    Port ( D : in STD_LOGIC_VECTOR (bus_width downto 0);
           Q : out STD_LOGIC_VECTOR (bus_width downto 0);
           enable: in std_logic ;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC);
end BasculeFF;

architecture Behavioral of BasculeFF is
begin 

Bascule: process( clk, reset)
    begin  
         if reset = '1' then 
          Q <= ( others => '0'); -- others sert a mettre tout les valuers de bits dans dans Q a zero peut importe la taille
         elsif (rising_edge( clk ) and enable = '1') then -- a chaque front montant de la clock Q prends la valeur de D ( fonctionnement d'une bascule)
          Q <= D ;  
         end if ;
  end process ;
end Behavioral;
