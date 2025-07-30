-----------------------------
--  distortion.vhd
-----------------------------
--  Distortion effect module.
--  Hard-clips the input signal using user-defined 
--  positive and negative thresholds.
--  Then amplifies the clipped signal using a gain factor.
--  Output is normalized by discarding 9 LSBs after multiplication.
--  If disabled, output is zero.
-------------------------------------------------------
--  Author: Colin Boule inspired by Jose Angel Gumiel
--  Updated: July 2025
-----------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity distortion is
	port (
		enable      : in  std_logic;                     -- Effect enable
		sample_in   : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
		sample_out  : out std_logic_vector(15 downto 0); -- Output audio sample (processed)
		gain        : in  std_logic_vector(15 downto 0); -- Amplification factor
		dist_pos    : in  std_logic_vector(15 downto 0)  -- Clipping threshold (positive)
	);
end entity distortion;

architecture behavioral of distortion is

	-- Internal signals
	signal dist_neg       : std_logic_vector(15 downto 0); -- Negative clipping threshold
	signal clipped_sample : std_logic_vector(15 downto 0); -- Signal after clipping
	signal amplified      : std_logic_vector(31 downto 0); -- Result of gain multiplication

begin

	-- Compute negative threshold as two's complement of dist_pos
	dist_neg <= std_logic_vector(-signed(dist_pos));

	-- ========== Clipping Logic ==========
	process (sample_in, dist_pos, dist_neg)
	begin
        if enable = '1' then
            if sample_in(15) = '1' then -- Negative sample
                if signed(sample_in) < signed(dist_neg) then
                    clipped_sample <= dist_neg;
                else
                    clipped_sample <= sample_in;
                end if;
            else -- Positive sample
                if signed(sample_in) > signed(dist_pos) then
                    clipped_sample <= dist_pos;
                else
                    clipped_sample <= sample_in;
                end if;
            end if;
        end if;
	end process;

	-- ========== Amplification Logic (Inline Booster) ==========
	amplified <= (others => '0') when enable = '0' else std_logic_vector(signed(clipped_sample) * signed(gain));

	-- ========== Output Logic ==========
	sample_out <= (others => '0') when enable = '0' else amplified(31) & amplified(22 downto 8); -- clipping by removing high bits

end architecture behavioral;
