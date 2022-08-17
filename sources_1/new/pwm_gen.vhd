----------------------------------------------------------------------------------
-- Thuong Nguyen
-- PWM GENERATOR
-- Take the input form the volume level shifter. 
-- the output is used to drive the mono audio-ouput
-- The pwm_gen component has a counter which would count from 0 to 1023 and  
-- set pwm_out to '1' when the counter is less than the duty_cycle value and set it to '0' when greater than or equal to the duty_cycle.
-------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity pwm_gen is
  Generic (pwm_resolution: integer := 10  );
  Port (clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        duty_cycle: in STD_LOGIC_VECTOR(pwm_resolution -1 downto 0);        -- input from Volume Level Shifter
        pwm_out: out STD_LOGIC
         );
end pwm_gen;

architecture Behavioral of pwm_gen is
    signal pwm_cnt: unsigned(pwm_resolution-1 downto 0) := to_unsigned(0,pwm_resolution);
    signal maxVal: unsigned(pwm_resolution -1 downto 0) := to_unsigned(1023,pwm_resolution); -- max val is 1023 of 10bits
    signal pwmOut: std_logic;
   
begin

   pwm_proc: process(clk, reset)
   begin
         if(reset = '1') then
            pwm_cnt <= (others => '0');
        elsif(rising_edge(clk)) then
            if(pwm_cnt = maxVal) then
                pwm_out <= '0';                             -- pwm_out gets set to '0' at least for one clock cycle during each period; 
                pwm_cnt <= (others => '0'); 
            else
                pwm_cnt <= pwm_cnt+1;    
            end if;
            if (pwm_cnt < unsigned(duty_cycle)) then        -- set pwm_out to '1' when the counter is less than the duty_cycle value 
                pwm_out <= '1';
            else
                pwm_out <= '0';                             --  set it to '0' when greater than or equal to the duty_cycle.
            end if;
            
        end if;
   end process;
  
end Behavioral;
