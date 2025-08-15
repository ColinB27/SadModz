--  ============================================================================================================
--  Tremolo.vhdl
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
--  ------------------------------------------------------------------------------------------------------------
--  CREDITS:    Jose Angel Gumiel (11/02/2017) 
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              July 2025 Creation
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
        sample_in      : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
        sample_out     : out std_logic_vector(15 downto 0); -- Output audio sample after modulation
        
        -- PARAMETERS
        rate          : in  std_logic_vector(15 downto 0); -- Tremolo rate (controls waveform period)
        atack         : in  std_logic_vector(15 downto 0); -- Minimum gain (modulation depth)
        wave          : in  std_logic_vector(1 downto 0)   -- Waveform shape: 00 = Square, 01 = Sawtooth, 10 = Triangle
    );
end entity tremolo;

architecture behavioral of tremolo is

    -- Constants for clamping rate
    constant max_freq       : std_logic_vector(15 downto 0) := x"0960"; 
    constant min_freq       : std_logic_vector(15 downto 0) := x"4650"; 
	constant zero			: std_logic_vector(18 downto 0) := (others => '0');

    -- Internal signals
    signal modulated_gain   : std_logic_vector(15 downto 0) := (others => '0');
    signal tremolo_counter  : std_logic_vector(18 downto 0) := (others => '0');
    signal double_rate      : std_logic_vector(18 downto 0) := (others => '0');
    signal amplified_sample : std_logic_vector(31 downto 0) := (others => '0');
    signal clamped_rate     : std_logic_vector(15 downto 0) := (others => '0');
    signal depth            : std_logic_vector(15 downto 0) := (others => '0');
    signal update_waveform  : std_logic := '0';
	 
begin

     -- Waveform generation instantiation would like to remove
    wave_inst: entity work.wave_setup
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

    -- Clamp rate within bounds on reset of modulation cycle
    clamped_rate <= max_freq when (rate < max_freq and tremolo_counter = zero) else
                    min_freq when (rate > min_freq and tremolo_counter = zero) else
                    rate     when (tremolo_counter = zero) else
                    clamped_rate;

    -- Update depth on cycle reset
    depth <= atack when (tremolo_counter = zero) else depth;

    -- Tremolo phase counter logic
    tremolo_process: process(clk, enable, reset)
    begin
        if reset = '1' then
            tremolo_counter <= (others => '0');
            update_waveform <= '0';
        elsif enable = '1' then
            if rising_edge(clk) then
                if load_sample = '1' then
                    double_rate <= std_logic_vector(shift_left(resize(unsigned(clamped_rate), 19), 1)); -- Multiply by 2 via shift
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

    -- Modulate the input signal with gain
    amplified_sample <= (others => '0') when enable = '0' else std_logic_vector(signed(sample_in) * signed(modulated_gain));

    -- Truncate and output the final signal
    sample_out <= (others => '0') when enable = '0' else amplified_sample(31) & amplified_sample(22 downto 8); -- Discard LSBs and preserve sign

end architecture behavioral;
