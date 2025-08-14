------------------------------------------------------------------------------------------------
--  tremolo.vhd   -- Integrated version (waveform logic included)
------------------------------------------------------------------------------------------------
-- Tremolo effect with selectable waveform (Square, Sawtooth, Triangle).
-- Applies amplitude modulation by multiplying audio samples with a variable gain.
------------------------------------------------------------------------------------------------
-- Original Author: Jose Angel Gumiel (11/02/2017)
-- Updated and integrated by ChatGPT - Aug 2025
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
        load_sample   : in  std_logic;                     -- Sample clock strobe
        clk           : in  std_logic;                     -- System clock
        reset         : in  std_logic;                     -- Active-high reset

        -- PARAMETERS
        rate          : in  std_logic_vector(15 downto 0); -- Tremolo rate
        atack         : in  std_logic_vector(15 downto 0); -- Minimum gain (depth)
        wave          : in  std_logic_vector(1 downto 0)   -- Waveform shape: 00=Square, 01=Sawtooth, 10=Triangle
    );
end entity tremolo;

architecture rtl of tremolo is

    -- Constants
    constant max_half_cycle : std_logic_vector(15 downto 0) := x"0960"; -- 2400
    constant min_half_cycle : std_logic_vector(15 downto 0) := x"4650"; -- 18000
    constant ZERO_16        : std_logic_vector(15 downto 0) := (others => '0');
    constant MAX_GAIN       : std_logic_vector(15 downto 0) := "0000001111111111"; -- 1023

    -- Internal signals
    signal half_cycle_length  : std_logic_vector(15 downto 0) := (others => '0'); -- Half of full waveform period
    signal full_cycle_length  : std_logic_vector(18 downto 0) := (others => '0'); -- Full waveform period
    signal tremolo_counter    : std_logic_vector(18 downto 0) := (others => '0');

    -- Gain modulation internals
    signal min_gain           : std_logic_vector(15 downto 0) := (others => '0');
    signal current_gain       : std_logic_vector(15 downto 0) := (others => '0');
    signal gain_step          : std_logic_vector(15 downto 0) := (others => '0');
    signal gain_cl_counter    : std_logic_vector(7 downto 0)  := (others => '0');
    signal difference         : unsigned(15 downto 0);
    signal division_result    : unsigned(15 downto 0);

    -- Audio processing
    signal amplified_sample   : std_logic_vector(31 downto 0) := (others => '0');

begin

    -----------------------------------------------------------------------------
    -- Clamp half-cycle length within bounds at the start of a new cycle
    -----------------------------------------------------------------------------
    half_cycle_length <= max_half_cycle when (rate < max_half_cycle and tremolo_counter = (others => '0')) else
                         min_half_cycle when (rate > min_half_cycle and tremolo_counter = (others => '0')) else
                         rate          when (tremolo_counter = (others => '0')) else
                         half_cycle_length;

    -----------------------------------------------------------------------------
    -- Tremolo phase counter logic
    -----------------------------------------------------------------------------
    tremolo_process: process(clk)
    begin
        if reset = '1' then
            tremolo_counter   <= (others => '0');
            full_cycle_length <= (others => '0');
        elsif enable = '1' then
            if rising_edge(clk) then
                if load_sample = '1' then
                    -- Full waveform period = 2 * half-cycle
                    full_cycle_length <= std_logic_vector(shift_left(unsigned(half_cycle_length), 1));

                    if tremolo_counter = full_cycle_length then
                        tremolo_counter <= (others => '0'); -- Reset at end of full cycle
                    else
                        tremolo_counter <= std_logic_vector(unsigned(tremolo_counter) + 1);
                    end if;
                end if;
            end if;
        end if;
    end process;

    -----------------------------------------------------------------------------
    -- Waveform generation logic
    -----------------------------------------------------------------------------
    waveform_process: process(clk)
    begin
        if reset = '1' then
            gain_step       <= ZERO_16;
            gain_cl_counter <= (others => '0');
            current_gain    <= ZERO_16;
        elsif rising_edge(clk) then
            -- Compute min gain once per cycle
            min_gain <= std_logic_vector(unsigned(atack) / 33);

            case wave is
                when "00" =>  -- Square wave
                    if (tremolo_counter(15 downto 0) < half_cycle_length) then
                        current_gain <= min_gain;
                    else
                        current_gain <= MAX_GAIN;
                    end if;

                when "01" =>  -- Sawtooth
                    if load_sample = '1' then
                        difference      <= unsigned(MAX_GAIN) - unsigned(min_gain);
                        division_result <= unsigned(half_cycle_length) / difference;
                        gain_step       <= std_logic_vector(division_result);

                        if tremolo_counter(15 downto 0) = ZERO_16 then
                            current_gain <= min_gain;
                        else
                            if gain_cl_counter < gain_step(7 downto 0) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain    <= std_logic_vector(unsigned(current_gain) + 1);
                                gain_cl_counter <= (others => '0');
                            end if;
                        end if;
                    end if;

                when "10" =>  -- Triangle
                    if load_sample = '1' then
                        difference      <= unsigned(MAX_GAIN) - unsigned(min_gain);
                        division_result <= unsigned(half_cycle_length) / difference;
                        gain_step       <= std_logic_vector(division_result);

                        if tremolo_counter(15 downto 0) = ZERO_16 then
                            current_gain <= min_gain;
                        elsif tremolo_counter(15 downto 0) < half_cycle_length then
                            if gain_cl_counter < gain_step(7 downto 0) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain    <= std_logic_vector(unsigned(current_gain) + 1);
                                gain_cl_counter <= (others => '0');
                            end if;
                        else
                            if gain_cl_counter < gain_step(7 downto 0) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain    <= std_logic_vector(unsigned(current_gain) - 1);
                                gain_cl_counter <= (others => '0');
                            end if;
                        end if;
                    end if;

                when others =>
                    current_gain <= ZERO_16;
            end case;
        end if;
    end process;

    -----------------------------------------------------------------------------
    -- Apply gain to audio signal
    -----------------------------------------------------------------------------
    amplified_sample <= (others => '0') when enable = '0' else
                        std_logic_vector(signed(audio_in) * signed(current_gain));

    -- Truncate to 16-bit and output
    audio_out <= (others => '0') when enable = '0' else
                 amplified_sample(31) & amplified_sample(22 downto 8);

end architecture rtl;
