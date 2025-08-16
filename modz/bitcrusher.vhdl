--  ============================================================================================================
--  bitcrusher.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Bitcrusher effect module with sample rate reduction and gain.
--              Reduces the bit depth of the input signal using a user-provided mask.
--              Optionally lowers the effective sample rate via a rate divider.
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bitcrusher is
    port (
        clk             : in  std_logic;                      -- System clock
        enable          : in  std_logic;                      -- Effect enable
        sample_in       : in  std_logic_vector(15 downto 0);  -- Input audio sample (signed)
        sample_out      : out std_logic_vector(15 downto 0);  -- Output audio sample (processed)
        rate_divider    : in  unsigned(15 downto 0);          -- Sample rate reduction factor (1-65535)
        gain            : in  std_logic_vector(15 downto 0);  -- Amplification factor
        mask            : in  std_logic_vector(15 downto 0)   -- Bitmask applied to input
    );
end entity bitcrusher;

architecture behavioral of bitcrusher is

    signal crushed_sample : std_logic_vector(15 downto 0) := (others => '0');  -- Bit-crushed sample
    signal counter        : unsigned(15 downto 0) := (others => '0');          -- Rate divider counter
    signal unnormalized   : std_logic_vector(31 downto 0) := (others => '0');  -- Amplified intermediate value

begin

    -- ================================================== Main Processing 
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                if counter = rate_divider - 1 then
                    counter <= (others => '0');
                    crushed_sample <= sample_in and mask;  
                else
                    counter <= counter + 1;
                end if;
            else
                counter        <= (others => '0');
                crushed_sample <= (others => '0');
            end if;
        end if;
    end process;

    -- Amplification Logic 
    unnormalized <= (others => '0') when enable = '0' else std_logic_vector(signed(crushed_sample) * signed(gain));

    -- Output Logic 
    sample_out <= (others => '0') when enable = '0' else unnormalized(31) & unnormalized(22 downto 8);

end architecture behavioral;
