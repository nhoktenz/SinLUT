----------------------------------------------------------------------------------
-- Thuong Nguyen
-- Sample Rate Generator 
-- SW(2:0) will be used to set the output frequency of the sine wave 
----- '000' will be 0Hz or DC **special case for counter! 
----- '001' will be 500Hz 
----- '010' will be 1000Hz 
----- '011' will be 1500Hz 
----- '100' will be 2000Hz 
----- '101' will be 2500Hz 
----- '110' will be 3000Hz 
----- '111' will be 3500Hz 
-- Max sample rate is calculated by the formula:
-- 1/ output frequency = 256 * 10ns * Max Sample Rate. 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity sampleRateGenerator is
 Port (
    clk: in STD_LOGIC;
    reset: in STD_LOGIC;
    sw: in STD_LOGIC_VECTOR(2 downto 0);
    sampleRate: out STD_LOGIC
     );
end sampleRateGenerator;

architecture Behavioral of sampleRateGenerator is
    signal max_sample_rate: unsigned(9 downto 0);
    signal sample_rate : std_logic;
    signal counter: unsigned(9 downto 0) := TO_UNSIGNED(0,10);
begin
    process(clk, reset)
    begin
        if(reset = '1') then
            counter <= (others => '0');
            sample_rate <= '0';
            max_sample_rate <= (others => '0');
        elsif (rising_edge(clk)) then
            if(sw = "001") then           -- 500Hz
                max_sample_rate <= "1100001101";    -- max sample rate = 781
            elsif (sw = "010") then     --1000Hz
                max_sample_rate <= "0110000111"; -- max sample rate = 391
            elsif (sw= "011") then      -- 1500Hz
                max_sample_rate <= "0100000100"; -- max sample rate = 260
            elsif (sw = "100") then     -- 2000Hz
                max_sample_rate <= "0011000011"; -- max sample rate = 195
            elsif (sw = "101") then     -- 2500Hz
                max_sample_rate <= "0010011100";  -- max sample rate = 156
            elsif (sw = "110") then     -- 3000Hz
                max_sample_rate <= "0010000010";   -- max sample rate = 130
            elsif (sw = "111") then     -- 3500Hz
                max_sample_rate <= "0001110000"; -- max sample rate = 112
            else
                max_sample_rate <= (others => '0');
            end if;
            
            if (counter = max_sample_rate) then     -- set the output to 1 when the counter reaches max sample rate value, otherwise the output is 0.
                counter <= (others => '0');         -- set counter to 0 when it reaches the max sample rate value
                sample_rate <= '1'; 
            else    
                counter <= counter + 1;
                sample_rate <= '0';
            end if;
        end if;
    end process;

sampleRate <= sample_rate;
end Behavioral;
