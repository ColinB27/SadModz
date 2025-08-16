--  ============================================================================================================
--  fuzz.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749]
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Fuzz effect module.
--              Applies aggressive soft-clipping to the input audio signal.
--              Produces a heavily distorted, fuzzy tone with adjustable
--              threshold and optional gain scaling.
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fuzz is
    port (
        enable      : in  std_logic;                      -- Effect enable
        sample_in   : in  std_logic_vector(15 downto 0);  -- Input audio sample (signed)  
        sample_out  : out std_logic_vector(15 downto 0);  -- Output audio sample (processed)
        gain        : in  std_logic_vector(15 downto 0);  -- Amplification factor
        fuzz_pos    : in  std_logic_vector(15 downto 0)   -- threshold for modulation
    );
end fuzz;

architecture behavioral of fuzz is

    signal sample_in_signed  : signed(15 downto 0) := (others => '0');     -- audio input
    signal sample_out_signed : signed(15 downto 0) := (others => '0');     -- audio modulated signal

    signal threshold         : signed(15 downto 0) := (others => '0');     -- threshold for modulation

    constant ONE             : signed(15 downto 0) := to_signed(600, 16);  -- positive saturation level
    constant NEG_ONE         : signed(15 downto 0) := to_signed(-700, 16); -- negative saturation level

begin
	sample_in_signed <= signed(sample_in);
   threshold <= signed(fuzz_pos); 
	
    -- ================================================== Clipping Logic 
    process(enable, sample_in, fuzz_pos, sample_in_signed,threshold)
    begin 
        if enable = '1' then
            if sample_in_signed > threshold then
                sample_out_signed <= ONE;
            elsif sample_in_signed < -threshold then
                sample_out_signed <= NEG_ONE;
            else
                sample_out_signed <= sample_in_signed sll 1; 
            end if;
        else
            sample_out_signed <= sample_in_signed; 
        end if;
    end process;
	 
	 sample_out <= std_logic_vector(sample_out_signed);

end behavioral;
