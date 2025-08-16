--  ============================================================================================================
--  Asym_Overdrive.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Asymetrical Overdrive effect module.
--              Applies soft clipping to the input signal using user-defined 
--              positive and negative thresholds.
--              Then amplifies the clipped signal using a gain factor.
--              Output is normalized by discarding 9 LSBs after multiplication.
--              If disabled, output is zero.
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity asym_overdrive is
	port (
		enable      : in  std_logic;                     -- Effect enable
		sample_in   : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
		sample_out  : out std_logic_vector(15 downto 0); -- Output audio sample (processed)
		gain        : in  std_logic_vector(15 downto 0); -- Amplification factor
		clip_pos    : in  std_logic_vector(15 downto 0); -- Clipping threshold (positive)
		clip_neg    : in  std_logic_vector(15 downto 0)  -- Clipping threshold (megative)
	);
end entity asym_overdrive;

architecture behavioral of asym_overdrive is

	-- Internal signals
	signal clip_neg       : std_logic_vector(15 downto 0); -- Negative clipping threshold
	signal clipped_offset : std_logic_vector(15 downto 0); -- Offset for soft clipping
	signal clipped_sample : std_logic_vector(15 downto 0); -- Signal after clipping
	signal unnormalized   : std_logic_vector(31 downto 0); -- Result of gain multiplication

begin

	-- Compute negative clipping threshold as two's complement of clip_pos
	clip_neg <= std_logic_vector(-signed(clip_neg));
	clipped_offset <= std_logic_vector(shift_right(signed(sample_in), 3));
	
	clipped_sample <= 
		std_logic_vector(signed(clip_neg) + signed(clipped_offset)) when (enable = '1' and sample_in(15) = '1' and signed(sample_in) < signed(clip_neg)) else
		std_logic_vector(signed(clip_pos) + signed(clipped_offset)) when (enable = '1' and sample_in(15) = '0' and signed(sample_in) > signed(clip_pos)) else
		sample_in when (enable = '1') else
		(others => '0');

	-- ========== Amplification Logic ==========
	unnormalized <= (others => '0') when enable = '0' else std_logic_vector(signed(clipped_sample) * signed(gain));

	-- ========== Output gating ==========
	sample_out <= (others => '0') when enable = '0' else unnormalized(31) & unnormalized(22 downto 8);

end architecture behavioral;
