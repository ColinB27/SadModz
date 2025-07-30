------------------------------------------------------------------------------------------------
--  tremolo.vhd   -- WORK TO DO
------------------------------------------------------------------------------------------------
-- Clean amplification stage with tremolo effect.
-- Multiplies input signal by a parameterized gain (amplitude).
-- Discards 9 LSBs after the sign bit to control gain.
-- Tremolo rate and waveform shape control modulation.
------------------------------------------------------------------------------------------------
-- Original Author: Jose Angel Gumiel (11/02/2017)
-- Updated by ChatGPT - July 2025
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tremolo is
    port(
        -- Data I/O:
        audio_in    : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
        audio_out   : out std_logic_vector(15 downto 0); -- Output audio sample (processed)
        enable      : in  std_logic;                     -- Effect enable

        -- Control signals:
        load_sample : in  std_logic;                     -- Load sample pulse
        clk         : in  std_logic;                     -- System clock
        reset       : in  std_logic;                     -- Reset or clear signal

        -- Parameters:
        rate        : in  std_logic_vector(15 downto 0); -- Tremolo rate (speed)
        atack       : in  std_logic_vector(15 downto 0); -- Amplitude modulation depth
        wave        : in  std_logic_vector(1 downto 0)   -- Waveform shape
    );
end entity tremolo;

architecture rtl of tremolo is

    -- Waveform generator component
    component wave_setup
        port(
            rate     : in  std_logic_vector(15 downto 0);
            wave     : in  std_logic_vector(1 downto 0);
            atack    : in  std_logic_vector(15 downto 0);
            gain     : out std_logic_vector(15 downto 0);
            counter  : in  std_logic_vector(18 downto 0);
            LD_Div   : in  std_logic;
            clk_Samp : in  std_logic;
            clk      : in  std_logic;
            cl       : in  std_logic
        );
    end component;

    -- Constants for clamping rate
    constant max_freq       : std_logic_vector(15 downto 0) := x"0960"; -- 2400
    constant min_freq       : std_logic_vector(15 downto 0) := x"4650"; -- 18000
    constant multiply_by_2  : std_logic_vector(2 downto 0)  := "010";

    -- Internal signals
    signal modulated_gain   : std_logic_vector(15 downto 0) := (others => '0');
    signal tremolo_counter  : std_logic_vector(18 downto 0) := (others => '0');
    signal double_rate      : std_logic_vector(18 downto 0) := (others => '0');
    signal amplified_sample : std_logic_vector(31 downto 0) := (others => '0');
    signal clamped_rate     : std_logic_vector(15 downto 0) := (others => '0');
    signal depth            : std_logic_vector(15 downto 0) := (others => '0');
    signal update_waveform  : std_logic := '0';


begin

    -- Clamp rate within bounds, only when counter resets
    clamped_rate <= max_freq when (rate < max_freq and tremolo_counter = (others => '0')) else
                    min_freq when (rate > min_freq and tremolo_counter = (others => '0')) else
                    rate     when (tremolo_counter = (others => '0')) else
                    clamped_rate;

    -- Update modulation depth at cycle reset
    depth <= atack when (tremolo_counter = (others => '0')) else depth;

    -- Tremolo timing process
    tremolo_process: process(clk)
    begin
        if reset = '1' then
            tremolo_counter <= (others => '0');
            update_waveform <= '0';
        elsif enable = '1' then
            if rising_edge(clk) then
                if load_sample = '1' then
                    double_rate <= std_logic_vector(shift_left(unsigned(clamped_rate), 1)); -- shift left to replace *2
                    if tremolo_counter = double_rate then
                        tremolo_counter <= (others => '0');
                        update_waveform <= '1';
                    else
                        tremolo_counter <= std_logic_vector(unsigned(tremolo_counter) + 1);
                        update_waveform <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Waveform modulation block
    wave_inst: wave_setup
        port map (
            rate     => clamped_rate,
            wave     => wave,
            atack    => depth,
            gain     => modulated_gain,
            counter  => tremolo_counter,
            LD_Div   => update_waveform,
            clk_Samp => load_sample,
            clk      => clk,
            cl       => reset
        );

    -- Apply tremolo modulation
    amplified_sample <= (others => '0') when enable = '0'
                      else std_logic_vector(signed(audio_in) * signed(modulated_gain));

    -- Normalize and output processed sample
    audio_out <= (others => '0') when enable = '0'
               else amplified_sample(31) & amplified_sample(22 downto 8);

end architecture rtl;
