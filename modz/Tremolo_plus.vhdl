--  ============================================================================================================
--  Tremolo_plus.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Tremolo effect module.
--              Multiplies the input signal by a parameterized gain (amplitude)
--              and applies periodic amplitude modulation based on a selectable
--              waveform and adjustable rate.
--              Discards 9 LSBs after the sign bit to control gain.
--              Waveforms  "011", "100" and "101" untested
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation + Custom Waveforms Added
--  ============================================================================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tremolo is
    port(
        -- CONTROL SIGNALS
        clk           : in  std_logic;                     -- System clock
        reset         : in  std_logic;                     -- Active-high reset
        enable        : in  std_logic;                     -- Enable tremolo effect
        load_sample   : in  std_logic;                     -- Sample clock strobe (advances effect state)
        
        -- DATA I/O
        sample_in     : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
        sample_out    : out std_logic_vector(15 downto 0); -- Output audio sample after modulation
        
        -- PARAMETERS
        rate          : in  std_logic_vector(15 downto 0); -- Tremolo rate (controls waveform period)
        atack         : in  std_logic_vector(15 downto 0); -- Minimum gain (modulation depth)
        wave          : in  std_logic_vector(2 downto 0)   -- Waveform shape:
                                                           -- 000 = Square
                                                           -- 001 = Sawtooth
                                                           -- 010 = Triangle
                                                           -- 011 = Half-sine approx
                                                           -- 100 = Exponential ramp
                                                           -- 101 = Random step
    );
end entity tremolo;

architecture behavioral of tremolo is

    -- Constants for clamping rate
    constant MAX_FREQ       : std_logic_vector(15 downto 0) := x"0960"; 
    constant MIN_FREQ       : std_logic_vector(15 downto 0) := x"4650"; 
    constant ZERO_16        : std_logic_vector(15 downto 0) := (others => '0');
    constant ZERO_19        : std_logic_vector(18 downto 0) := (others => '0');
    constant MAX_GAIN       : std_logic_vector(15 downto 0) := "0000001111111111";

    -- Internal tremolo signals
    signal modulated_gain   : std_logic_vector(15 downto 0) := (others => '0');
    signal tremolo_counter  : std_logic_vector(18 downto 0) := (others => '0');
    signal double_rate      : std_logic_vector(18 downto 0) := (others => '0');
    signal amplified_sample : std_logic_vector(31 downto 0) := (others => '0');
    signal clamped_rate     : std_logic_vector(15 downto 0) := (others => '0');
    signal depth            : std_logic_vector(15 downto 0) := (others => '0');
    signal update_waveform  : std_logic := '0';

    -- Internal waveform/gain generation
    signal min_gain         : std_logic_vector(15 downto 0) := "0000000010000001";
    signal dir              : signed(15 downto 0);
    signal gain_step        : std_logic_vector(15 downto 0);
    signal gain_cl_counter  : unsigned(7 downto 0) := (others => '0');
    signal waveform_gain    : std_logic_vector(15 downto 0) := (others => '0');
    signal difference       : unsigned(15 downto 0);
    signal division_result  : unsigned(15 downto 0);

    -- Custom waveforms
    signal half_sine_gain   : unsigned(15 downto 0);
    signal exp_gain         : unsigned(15 downto 0);
    signal rand_gain        : unsigned(15 downto 0);
    signal lfsr             : unsigned(7 downto 0) := "10101101"; -- Simple LFSR seed

begin

    -------------------------------------------------------------------------
    -- Clamp rate within bounds on reset of modulation cycle
    -------------------------------------------------------------------------
    clamped_rate <= MAX_FREQ when (rate < MAX_FREQ and tremolo_counter = ZERO_19) else
                    MIN_FREQ when (rate > MIN_FREQ and tremolo_counter = ZERO_19) else
                    rate     when (tremolo_counter = ZERO_19) else
                    clamped_rate;

    -- Update depth on cycle reset
    depth <= atack when (tremolo_counter = ZERO_19) else depth;

    -------------------------------------------------------------------------
    -- Tremolo phase counter process
    -------------------------------------------------------------------------
    tremolo_process: process(clk, enable, reset)
    begin
        if reset = '1' then
            tremolo_counter <= (others => '0');
            update_waveform <= '0';
        elsif enable = '1' then
            if (rising_edge(clk) and (wave = "010" or wave = "010")) then
                if load_sample = '1' then
                    double_rate <= std_logic_vector(shift_left(resize(unsigned(clamped_rate), 19), 1)); -- Multiply by 2
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

    -------------------------------------------------------------------------
    -- Waveform / gain generator process (sawtooth & triangle)
    -------------------------------------------------------------------------
    difference <= unsigned(MAX_GAIN) - unsigned(min_gain);

    dir <= to_signed(1, 16) when (wave = "001" or (wave = "010" and unsigned(tremolo_counter(15 downto 0)) < unsigned(rate))) else
           to_signed(-1, 16);

    waveform_process: process(clk, reset, wave, enable)
    begin
        if reset = '1' then
            gain_step       <= (others => '0');
            gain_cl_counter <= (others => '0');
        elsif (rising_edge(clk) and enable = '1') then
            if (wave = "001" or wave = "010") then -- Sawtooth & Triangle
                if load_sample = '1' then
                    gain_step       <= std_logic_vector(division_result);
                    division_result <= unsigned(rate) / difference;
                    min_gain        <= std_logic_vector(unsigned(depth) / 33);

                    if tremolo_counter(15 downto 0) = ZERO_16 then
                        waveform_gain <= min_gain;
                    elsif (gain_cl_counter < unsigned(gain_step(7 downto 0))) then
                        gain_cl_counter <= gain_cl_counter + 1;
                    else
                        waveform_gain    <= std_logic_vector(signed(waveform_gain) + dir);
                        gain_cl_counter <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Custom waveforms
    -------------------------------------------------------------------------
    -- Half-sine approx (parabolic arc)
    half_sine_gain <=   resize((unsigned(tremolo_counter(15 downto 0)) * (unsigned(rate) - unsigned(tremolo_counter(15 downto 0)))), 16) when (wave = "011" and enable = '1') else 
                        (others => '0');
                        

    -- Exponential ramp (square of counter)
    exp_gain <=         resize((unsigned(tremolo_counter(15 downto 0)) * unsigned(tremolo_counter(15 downto 0))) / unsigned(rate), 16) when (wave = "100" and enable = '1') else 
                        (others => '0');

    -- Random step tremolo (8-bit LFSR expanded to 16-bit)
    lfsr_process: process(clk, reset, wave, enable)
    begin
        if reset = '1' then
            lfsr <= "10101101";
        elsif (rising_edge(clk) and wave = "101" and enable = '1') then
            if tremolo_counter = ZERO_19 then
                lfsr <= lfsr(6 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3));
            end if;
        end if;
    end process;

    rand_gain <= resize(lfsr & "0000", 16);

    -------------------------------------------------------------------------
    -- Gain multiplexer: select waveform
    -------------------------------------------------------------------------
    modulated_gain <= std_logic_vector(min_gain)         when (wave = "000" and unsigned(tremolo_counter) < unsigned(rate)) else
                      std_logic_vector(MAX_GAIN)         when (wave = "000") else
                      waveform_gain                      when (wave = "001" or wave = "010") else
                      std_logic_vector(half_sine_gain)   when (wave = "011") else
                      std_logic_vector(exp_gain)         when (wave = "100") else
                      std_logic_vector(rand_gain)        when (wave = "101") else
                      (others => '0');

    -------------------------------------------------------------------------
    -- Modulate and output
    -------------------------------------------------------------------------
    amplified_sample <= (others => '0') when enable = '0' else 
                        std_logic_vector(signed(sample_in) * signed(modulated_gain));

    sample_out <= (others => '0') when enable = '0' else 
                  amplified_sample(31) & amplified_sample(22 downto 8); -- Truncate + keep sign

end architecture behavioral;
