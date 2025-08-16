--  ============================================================================================================
--  distortion.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
-- 				Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--  			Distortion effect module.
--  			Hard-clips the input signal using user-defined 
--  			positive and negative thresholds.
--  			Then amplifies the clipped signal using a gain factor.
--  			Output is normalized by discarding 9 LSBs after multiplication.
--  			If disabled, output is zero.
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--				August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity distortion is
	port (
		enable      : in  std_logic;                     -- Effect enable
		sample_in   : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
		sample_out  : out std_logic_vector(15 downto 0); -- Output audio sample (processed)
		gain        : in  std_logic_vector(15 downto 0); -- Amplification factor
		clip_pos    : in  std_logic_vector(15 downto 0)  -- Clipping threshold (positive)
	);
end entity distortion;

architecture behavioral of distortion is

	-- Internal signals
	signal clip_neg       : std_logic_vector(15 downto 0); -- Negative clipping threshold
	signal output_sample  : std_logic_vector(15 downto 0); -- Signal after clipping
	signal clipped_sample : std_logic_vector(15 downto 0); -- Signal after clipping
	signal amplified      : std_logic_vector(31 downto 0); -- Result of gain multiplication

begin

	-- Compute negative threshold as two's complement of dist_pos
	clip_neg <= std_logic_vector(-signed(clip_pos));
	
	output_sample <= clip_pos  when (enable = '1' and sample_in(15) = '0' and signed(sample_in) > signed(clip_pos)) else
                    clip_neg  when (enable = '1' and sample_in(15) = '1' and signed(sample_in) < signed(clip_neg)) else
                    sample_in when (enable = '1') else
						  (others => '0');


	-- Amplification Logic 
	amplified <= (others => '0') when enable = '0' else std_logic_vector(signed(output_sample) * signed(gain));

	-- Output Logic 
	sample_out <= (others => '0') when enable = '0' else amplified(31) & amplified(22 downto 8); -- clipping by removing high bits

end architecture behavioral;





	
