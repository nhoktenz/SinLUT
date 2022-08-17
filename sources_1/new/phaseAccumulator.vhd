----------------------------------------------------------------------------------
-- Thuong Nguyen
-- Phase Accumulator
-- Take the sample rate input from the Sample Rate Generator
-- Output 8-bits phase counter
--------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity phaseAccumulator is
  Port (clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        sampleRate : in STD_LOGIC;
        phaseCounter: out STD_LOGIC_VECTOR (7 downto 0)
   );
end phaseAccumulator;

architecture Behavioral of phaseAccumulator is
    signal phase_counter: unsigned (7 downto 0) := to_unsigned(0,8);
begin
     process(clk, reset)
    begin
        if(reset = '1') then
            phase_counter <= (others => '0');
        elsif (rising_edge(clk)) then
            if(sampleRate = '1') then                   -- if the input sample rate = 1, then counter up
                phase_counter <= phase_counter + 1;
            else 
                phase_counter <= phase_counter;         -- otherwise, counter does not change
            end if;
        end if;
     end process;
phaseCounter <= std_logic_vector(phase_counter);
end Behavioral;
