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
        -- DATA I/O
        audio_in      : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
        audio_out     : out std_logic_vector(15 downto 0); -- Output audio sample after modulation
        enable        : in  std_logic;                     -- Enable tremolo effect

        -- CONTROL SIGNALS
        load_sample   : in  std_logic;                     -- Sample clock strobe (advances effect state)
        clk           : in  std_logic;                     -- System clock
        reset         : in  std_logic;                     -- Active-high reset

        -- PARAMETERS
        rate          : in  std_logic_vector(15 downto 0); -- Tremolo rate (controls waveform period)
        atack         : in  std_logic_vector(15 downto 0); -- Minimum gain (modulation depth)
        wave          : in  std_logic_vector(1 downto 0)   -- Waveform shape: 00 = Square, 01 = Sawtooth, 10 = Triangle
    );
end entity tremolo;

architecture rtl of tremolo is

    -- Updated waveform generator component declaration
    component wave_setup
        port(
            rate        : in  std_logic_vector(15 downto 0); -- Waveform cycle duration
            waveform    : in  std_logic_vector(1 downto 0);  -- Waveform type selector
            attack      : in  std_logic_vector(15 downto 0); -- Minimum gain value
            gain        : out std_logic_vector(15 downto 0); -- Output modulated gain
            counter     : in  std_logic_vector(18 downto 0); -- Global modulation phase counter
            load_div    : in  std_logic;                     -- Trigger to reload internal division step
            clk_sample  : in  std_logic;                     -- Sample strobe input
            clk         : in  std_logic;                     -- System clock
            rst         : in  std_logic                      -- Active-high reset
        );
    end component;

    -- Constants for clamping rate
    constant max_freq       : std_logic_vector(15 downto 0) := x"0960"; -- 2400
    constant min_freq       : std_logic_vector(15 downto 0) := x"4650"; -- 18000

    -- Internal signals
    signal modulated_gain   : std_logic_vector(15 downto 0) := (others => '0');
    signal tremolo_counter  : std_logic_vector(18 downto 0) := (others => '0');
    signal double_rate      : std_logic_vector(18 downto 0) := (others => '0');
    signal amplified_sample : std_logic_vector(31 downto 0) := (others => '0');
    signal clamped_rate     : std_logic_vector(15 downto 0) := (others => '0');
    signal depth            : std_logic_vector(15 downto 0) := (others => '0');
    signal update_waveform  : std_logic := '0';

begin

    -- Clamp rate within bounds on reset of modulation cycle
    clamped_rate <= max_freq when (rate < max_freq and tremolo_counter = (others => '0')) else
                    min_freq when (rate > min_freq and tremolo_counter = (others => '0')) else
                    rate     when (tremolo_counter = (others => '0')) else
                    clamped_rate;

    -- Update depth on cycle reset
    depth <= atack when (tremolo_counter = (others => '0')) else depth;

    -- Tremolo phase counter logic
    tremolo_process: process(clk)
    begin
        if reset = '1' then
            tremolo_counter <= (others => '0');
            update_waveform <= '0';
        elsif enable = '1' then
            if rising_edge(clk) then
                if load_sample = '1' then
                    double_rate <= std_logic_vector(shift_left(unsigned(clamped_rate), 1)); -- Multiply by 2 via shift
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

    -- Waveform generation instantiation
    wave_inst: wave_setup
        port map (
            rate        => clamped_rate,     -- Cycle duration of waveform
            waveform    => wave,             -- Selected waveform type
            attack      => depth,            -- Minimum amplitude level
            gain        => modulated_gain,   -- Output modulated gain
            counter     => tremolo_counter,  -- Phase of modulation cycle
            load_div    => update_waveform,  -- Trigger to recompute step size
            clk_sample  => load_sample,      -- Incoming audio sample strobe
            clk         => clk,              -- System clock
            rst         => reset             -- Reset signal
        );

    -- Modulate the input signal with gain
    amplified_sample <= (others => '0') when enable = '0' else std_logic_vector(signed(audio_in) * signed(modulated_gain));

    -- Truncate and output the final signal
    audio_out <= (others => '0') when enable = '0' else amplified_sample(31) & amplified_sample(22 downto 8); -- Discard LSBs and preserve sign

end architecture rtl;
