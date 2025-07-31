------------------------------------------------------------------------------------------------
--  wave_setup.vhd
------------------------------------------------------------------------------------------------
-- Waveform Selector
-- Configures the shape of the tremolo amplitude waveform.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  04/03/2017
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity wave_setup is
    port (
        -- DATA INPUTS
        rate        : in std_logic_vector(15 downto 0); -- Duration of one waveform cycle (affects frequency)
        waveform    : in std_logic_vector(1 downto 0);  -- Waveform type selector: 00 = Square, 01 = Sawtooth, 10 = Triangle
        attack      : in std_logic_vector(15 downto 0); -- Controls minimum gain level (influences amplitude floor)

        -- DATA OUTPUT
        gain        : out std_logic_vector(15 downto 0); -- Output gain level to apply to the signal (modulated over time)

        -- CONTROL INPUTS
        counter     : in std_logic_vector(18 downto 0); -- Global counter from tremolo clock domain, tracks waveform phase
        load_div    : in std_logic;                     -- Unused in this module (placeholder for divider load)
        clk_sample  : in std_logic;                     -- Sample clock strobe signal, determines when gain is updated
        clk         : in std_logic;                     -- System clock for synchronous logic
        rst         : in std_logic                      -- Active-high reset signal for reinitializing internal state
    );
end entity wave_setup;


architecture Behavioral of wave_setup is

    -- Constants and defaults
    constant ZERO_16      : std_logic_vector(15 downto 0) := (others => '0');
    constant MAX_GAIN     : std_logic_vector(15 downto 0) := "0000001111111111";
    signal min_gain       : std_logic_vector(15 downto 0) := "0000000010000001";

    -- Counters
    signal gain_step      : std_logic_vector(15 downto 0);  -- Number of steps between gain updates
    signal gain_cl_counter: std_logic_vector(7 downto 0) := (others => '0');

    -- Internals
    signal current_gain   : std_logic_vector(15 downto 0) := (others => '0');
    signal difference     : unsigned(15 downto 0);
    signal division_result: unsigned(15 downto 0);

begin

    process(rate, waveform, counter, clk, rst)
    begin
        if (rst = '1') then
            gain_step       <= ZERO_16;
            gain_cl_counter <= (others => '0');
        elsif rising_edge(clk) then
            -- Configure attack value
            -- Approx. attack / 33
            min_gain <= std_logic_vector(unsigned(attack) / 33);

            case waveform is
                when "00" =>  -- Square wave
                    if (counter(15 downto 0) < rate) then
                        gain <= min_gain;
                    else
                        gain <= MAX_GAIN;
                    end if;

                when "01" =>  -- Sawtooth wave
                    if (clk_sample = '1') then
                        difference      <= unsigned(MAX_GAIN) - unsigned(min_gain);
                        division_result <= unsigned(rate) / difference;
                        gain_step       <= std_logic_vector(division_result);

                        if (counter(15 downto 0) = ZERO_16) then
                            current_gain <= min_gain;
                        else
                            if (gain_cl_counter < gain_step(7 downto 0)) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain     <= current_gain + 1;
                                gain_cl_counter  <= (others => '0');
                            end if;
                        end if;
                        gain <= current_gain;
                    end if;

                when "10" =>  -- Triangle wave
                    if (clk_sample = '1') then
                        difference      <= unsigned(MAX_GAIN) - unsigned(min_gain);
                        division_result <= unsigned(rate) / difference;
                        gain_step       <= std_logic_vector(division_result);

                        if (counter(15 downto 0) = ZERO_16) then
                            current_gain <= min_gain;
                        elsif (counter(15 downto 0) < rate) then
                            if (gain_cl_counter < gain_step(7 downto 0)) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain    <= current_gain + 1;
                                gain_cl_counter <= (others => '0');
                            end if;
                        else
                            if (gain_cl_counter < gain_step(7 downto 0)) then
                                gain_cl_counter <= gain_cl_counter + 1;
                            else
                                current_gain    <= current_gain - 1;
                                gain_cl_counter <= (others => '0');
                            end if;
                        end if;
                        gain <= current_gain;
                    end if;

                when others =>
                    gain <= (others => '0');
            end case;
        end if;
    end process;

end architecture Behavioral;
