----------------------------------------------------------------------------------
-- Thuong Nguyen
-- Sin LUT DDS
-- SW(15) will be used to turn on and off the amplifier network for the audio output, setting SW(15) to '1' will cause the audio output to turn-on. 
-- BTNC is the overall reset for all sequential logic 
-- SW(5:3) will be used to set the volume level of the output 
--  o '111' will be 100% volume 
--  o '000' will be 0% volume 
--  o All the values in between will be scaled equally 
-- The volume level of the sine output will be displayed on the upper four 7-segment displays. 
--SW(2:0) will be used to set the output frequency of the sine wave 
--  o '000' will be 0Hz or DC **special case for counter! 
--  o '001' will be 500Hz 
--  o '010' will be 1000Hz 
--  o '011' will be 1500Hz 
--  o '100' will be 2000Hz 
--  o '101' will be 2500Hz 
--  o '110' will be 3000Hz 
--  o '111' will be 3500Hz 
-- The frequency value of the sine output will be displayed on the lower four 7-segment displays.
--The output for this lab can be heard by plugging in a set of stereo headphones to the mono-audio output jack.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;
entity SinLUT_top is
Port ( 
           -- Clock
           CLK100MHZ : in STD_LOGIC;
          -- SW(5:3) will be used to set the volume level of the output
          -- SW(2:0) will be used to set the output frequency of the sine wave
          -- SW(15) will be used to turn on and off the amplifier network for the audio output
           SW: in STD_LOGIC_VECTOR(15 downto 0);           
           -- Button C is the overall reset for all sequential logic.
           BTNC : in STD_LOGIC;
                    
           --Seg7 Display Signals
           SEG7_CATH : out STD_LOGIC_VECTOR (7 downto 0);
           AN : out STD_LOGIC_VECTOR (7 downto 0);
           LED: out STD_LOGIC_VECTOR(15 downto 0);
           AUD_PWM: out STD_LOGIC;
           AUD_SD: out STD_LOGIC

           );
end SinLUT_top;

architecture Behavioral of SinLUT_top is
 -- reset signal
    signal reset : std_logic;
    signal sample_rate: std_logic;                          -- output of Sample Rate Generator , input of Phase Accumulator
    signal phase_counter: std_logic_vector(7 downto 0);     -- output of Phase Accumulator, input of Sin LUT DDS
    signal sin_lut: std_logic_vector (15 downto 0);         -- output of Sin LUT DDS, input of Volume Level Shifter
    signal sine_shifted: std_logic_vector (9 downto 0);     -- output of Volume Level Shifter, input of PWM Generator
    
     -- 7 segments display
    signal char0: std_logic_vector(31 downto 28);
    signal char1: std_logic_vector(27 downto 24);
    signal char2: std_logic_vector(23 downto 20);
    signal char3: std_logic_vector(19 downto 16);
    signal char4: std_logic_vector(15 downto 12);
    signal char5: std_logic_vector(11 downto 8);
    signal char6: std_logic_vector(7 downto 4);
    signal char7: std_logic_vector(3 downto 0);
    
    -- BTNC
    signal btnC_bd: std_logic; --button center debounce output
    signal btnC_db_prev: std_logic; -- button center debounce is one clock cycle delayed
    signal btnC_press_event: std_logic; 
   
    component sin_lut_dds 
    port ( 
            aclk : IN STD_LOGIC;
            s_axis_phase_tvalid : IN STD_LOGIC;
            s_axis_phase_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            m_axis_data_tvalid : OUT STD_LOGIC;
            m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)      
        );
end component;
    
begin
    LED <= SW;
    AUD_SD <= SW(15);       -- SW(15) will be used to turn on and off the amplifier network for the audio output, setting SW(15) to '1' will cause the audio output to turn-on. 
    
    --------BUTTON CENTER -------------
     -- button center debounce port map
     btnUpDebounce: entity btn_debounce port map
     (
        clk => CLK100MHZ,
        reset => reset,
        pb0 => BTNC,
        pb0db => btnC_bd
     );
     -- process to assign the button center debounce output one clock cycle delayed
     btnC_enable: process(CLK100MHZ, reset)
     begin
        if (reset = '1') then
            btnC_db_prev <= '0';
        elsif (rising_edge(CLK100MHZ)) then
            btnC_db_prev <= btnC_bd;      -- previous value of button pushed
        end if;    
     end process btnC_enable;
     
     btnC_press_event <= '1' when btnC_bd = '1' and btnC_db_prev = '0' else '0';
    reset <= '1' when btnC_press_event = '1' else '0';  --BTNC is the overall reset for all sequential logic 
    
    --------------------------------------------------------------------------------------
    ------------------------------ Sample Rate Generator ---------------------------------
    --------------------------------------------------------------------------------------
    srgen: entity sampleRateGenerator port map (
                                            clk => CLK100MHZ,
                                            reset => reset,
                                            sw => SW(2 downto 0),
                                            sampleRate => sample_rate
                                            );
    --------------------------------------------------------------------------------------
    ------------------------------Phase Accumulator --------------------------------------
    --------------------------------------------------------------------------------------
    phase: entity phaseAccumulator port map(
                                        clk => CLK100MHZ,
                                        reset => reset,
                                        sampleRate => sample_rate,
                                        phaseCounter => phase_counter               -- phase counter as output
                                         );
    --------------------------------------------------------------------------------------
    ------------------------------ IP Sin LUT DDS -----------------------------------------
    --------------------------------------------------------------------------------------
     dds: sin_lut_dds port map (
                                aclk => CLK100MHZ,
                                s_axis_phase_tvalid => '1',
                                s_axis_phase_tdata => phase_counter,        --8bits phase input
                                m_axis_data_tdata => sin_lut                -- output 16-bit sine value at the current position in the sine look-up table 
                            );
    
    --------------------------------------------------------------------------------------
    ----------------------------- Volume Level Shifte-------------------------------------
    --------------------------------------------------------------------------------------
    volume: entity volumeLevelShifter port map (
                                            sw => sw(5 downto 3),
                                            sineOutput => sin_lut,
                                            sineShift => sine_shifted
                                        );
    --------------------------------------------------------------------------------------
    ------------------------------ PWM Generator -----------------------------------------
    --------------------------------------------------------------------------------------
    pwm: entity pwm_gen  generic map(pwm_resolution => 10)
                            port map(
                                clk => CLK100MHZ,
                                reset => reset,
                                duty_cycle => sine_shifted,                 -- sine output is input to PWM
                                pwm_out => AUD_PWM
                            );
    
    
     -- 7 segments controller port map     
   seg7Controller: entity seg7_controller port map 
    (
        clk => CLK100MHZ, 
        reset =>  reset,
        character0 => char0, 
        character1 => char1,  
        character2  => char2, 
        character3  => char3, 
        character4  => char4,
        character5  => char5, 
        character6  => char6,
        character7 => char7, 
        encode_character => SEG7_CATH, -- cathodes
        AN => AN                       -- anodes
    );
    
  
    -- SW(5:3) will be used to set the volume level of the output 
    --  o '111' will be 100% volume 
    --  o '000' will be 0% volume 
    --  o All the values in between will be scaled equally 
    -- The volume level of the sine output will be displayed on the upper four 7-segment displays. 
   process (SW(5 downto 3))
   begin
    if(SW(5 downto 3) = "000") then -- 0%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= (others => '0');
        char4 <= (others => '0');
    elsif (SW(5 downto 3) = "001") then -- 13%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"1";
        char4 <= x"3";
    elsif (SW(5 downto 3) = "010") then     -- 25%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"2";
        char4 <= x"5";
    elsif (SW(5 downto 3) = "011") then     -- 38%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"3";
        char4 <= x"8";
    elsif (SW(5 downto 3) = "100") then     -- 50%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"5";
        char4 <= x"0";
    elsif (SW(5 downto 3) = "101") then     -- 63%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"6";
        char4 <= x"3";
    elsif (SW(5 downto 3) = "110") then     -- 75%
        char7 <= (others => '0');
        char6 <= (others => '0');
        char5 <= x"7";
        char4 <= x"5";
    else     
        char7 <= (others => '0');                              
        char6 <= x"1";
        char5 <= x"0";
        char4 <= x"0";
    end if;
   end process;
   
   -- The frequency value of the sine output will be displayed on the lower four 7-segment displays. 
   process (SW(2 downto 0))
   begin
        if(SW(2 downto 0) = "000") then -- 0
        char3 <= (others => '0');
        char2 <= (others => '0');
        char1 <= (others => '0');
        char0 <= (others => '0');
    elsif (SW(2 downto 0) = "001") then -- 500Hz
        char3 <= (others => '0');
        char2 <= x"5";
        char1 <= x"0";
        char0 <= x"0";
    elsif (SW(2 downto 0) = "010") then     -- 1000Hz
        char3 <= x"1";
        char2 <= x"0";
        char1 <= x"0";
        char0 <= x"0";
    elsif (SW(2 downto 0) = "011") then     -- 1500Hz
        char3 <= x"1";
        char2 <= x"5";
        char1 <= x"0";
        char0 <= x"0";
    elsif (SW(2 downto 0) = "100") then     -- 2000Hz
        char3 <= x"2";
        char2 <= x"0";
        char1 <= x"0";
        char0 <= x"0";
    elsif (SW(2 downto 0) = "101") then     -- 2500Hz
        char3 <= x"2";
        char2 <= x"5";
        char1 <= x"0";
        char0 <= x"0";
    elsif (SW(2 downto 0) = "110") then     -- 3000Hz
       char3 <= x"3";
        char2 <= x"0";
        char1 <= x"0";
        char0 <= x"0";
    else                                    -- 3500Hz
        char3 <= x"3";
        char2 <= x"5";
        char1 <= x"0";
        char0 <= x"0";
    end if;
   end process;

end Behavioral;
