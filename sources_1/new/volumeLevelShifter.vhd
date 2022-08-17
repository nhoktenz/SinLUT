----------------------------------------------------------------------------------
-- Thuong Nguyen 
-- Volume level shifter
--The 16-bit output of the DDS is passed into the Volume level shifter, which is controlled by SW(5:3). 
----SW(5:3) = 000 -> output voulume is 0% -> right shift output sine value by 7-bits
----SW(5:3) = 001 -> output volume is 13% -> right shift output sine value by 6-bits
----SW(5:3) = 010 -> output volume is 25% -> right shift output sine value by 5-bits
----SW(5:3) = 011 -> output volume is 38% -> right shift output sine value by 4-bits
----SW(5:3) = 100 -> output volume is 50% -> right shift output sine value by 3-bits
----SW(5:3) = 101 -> output volume is 63% -> right shift output sine value by 2-bits
----SW(5:3) = 110 -> output volume is 75% -> right shift output sine value by 1-bits
----SW(5:3) = 111 -> output volume is 100% -> no shift the sine LUT output at all.

--Before setting up the volume, the m_axis_data_tdata output from the DDS need to be level shifted to adjusting the volume by inverting the MSB of the m_axis_data_tdata signal. 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;


entity volumeLevelShifter is
  Port (   sineOutput: in STD_LOGIC_VECTOR(15 downto 0);        --input 16 bits from DDS
           sw: in STD_LOGIC_VECTOR(5 downto 3);                 -- switch 5:3 to control the volume
           sineShift: out STD_LOGIC_VECTOR(9 downto 0)
         );
end volumeLevelShifter;

architecture Behavioral of volumeLevelShifter is
    signal invert_MSB: std_logic_vector(15 downto 0);
    signal phase_increment_delay: unsigned(7 downto 0);
    signal sine_shift_right: std_logic_vector(15 downto 0);
begin
    invert_MSB <= sineOutput xor x"8000";           -- level shifted the m_axis_date_tdata outout of the DDS 
                                                    -- by inverting the MSB

    sine_shift_right <= "0000000" & invert_MSB(15 downto 7) when sw = "000" else     -- 0%       right shift 7 bits
                        "000000" & invert_MSB(15 downto 6) when sw = "001" else      -- 13%      right shift 6 bits
                        "00000" & invert_MSB(15 downto 5) when sw = "010" else      -- 25%      right shift 5 bits
                        "0000" & invert_MSB(15 downto 4) when sw = "011" else       -- 50%      right shift 3 bits
                        "000" & invert_MSB(15 downto 3) when sw = "100" else        -- 63%      right shift 2 bits
                        "00" & invert_MSB(15 downto 2) when sw = "101" else         -- 75%     right shift 1 bit
                        "0" & invert_MSB(15 downto 1) when sw = "110" else          -- 100%    no shift
                       invert_MSB;
    
    sineShift <= sine_shift_right(15 downto 6);     -- chop the 6 LSB bits
end Behavioral;
