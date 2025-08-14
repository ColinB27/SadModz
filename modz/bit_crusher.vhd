-----------------------------
--  bitcrusher.vhd
-----------------------------
--  Bitcrusher effect module with sample rate reduction.
--  Reduces bit depth by masking out lower bits.
--  Also lowers effective sample rate by only updating
--  the output every (rate_divider) clock cycles.
--  If disabled, output is zero.
-------------------------------------------------------
--  Author: Colin Boule
--  Updated: August 2025
-----------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bitcrusher is
    port (
        clk           : in  std_logic;                     -- System clock
        enable        : in  std_logic;                     -- Effect enable
        sample_in     : in  std_logic_vector(15 downto 0); -- Input audio sample (signed)
        sample_out    : out std_logic_vector(15 downto 0); -- Output audio sample (processed)
        crush_bits    : in  integer range 1 to 16;         -- Bits to keep
        rate_divider  : in  integer range 1 to 65535       -- Sample rate reduction factor
    );
end entity bitcrusher;

architecture behavioral of bitcrusher is

    -- Internal signals
    signal mask           : signed(15 downto 0); -- Bitmask for keeping upper bits
    signal crushed_sample : signed(15 downto 0); -- Bit-crushed value
    signal held_sample    : signed(15 downto 0); -- Last output value (for rate reduction)
    signal counter        : unsigned(15 downto 0) := (others => '0'); -- Rate divider counter

begin

    -- ========== Mask Generation ==========
    process(crush_bits)
        variable temp_mask : signed(15 downto 0);
    begin
        if crush_bits = 16 then
            temp_mask := (others => '1');
        else
            temp_mask := shift_left(to_signed(-1, 16), 16 - crush_bits);
        end if;
        mask <= temp_mask;
    end process;

    -- ========== Main Processing ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                -- Increment counter for sample rate reduction
                if counter = to_unsigned(rate_divider - 1, counter'length) then
                    counter <= (others => '0');

                    -- Apply bit depth reduction when updating
                    crushed_sample <= signed(sample_in) and mask;

                    -- Store as the held output value
                    held_sample <= crushed_sample;
                else
                    -- Hold the last output value until next update
                    counter <= counter + 1;
                end if;
            else
                -- Effect disabled: reset everything
                counter       <= (others => '0');
                crushed_sample <= (others => '0');
                held_sample    <= (others => '0');
            end if;
        end if;
    end process;

    -- ========== Output Logic ==========
    sample_out <= std_logic_vector(held_sample) when enable = '1' else (others => '0');

end architecture behavioral;
