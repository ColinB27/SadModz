--  ============================================================================================================
--  audio_out.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--              Adapted and translated from original work by Andoni Arruti
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Sends a 16-bit audio sample to the WM8731 codec via the serial line.  
--              The codec is assumed to be configured in master mode and in  
--              "left-justified" format.  
--              The same audio sample is transmitted to both channels.  
--              While updated and reformatted, the underlying structure  
--              remains hardware-driven and is therefore essentially the same.  
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              July 2025
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;

entity audio_out is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        daclrc        : in  std_logic;
        bclk          : in  std_logic;
        sample        : in  std_logic_vector(15 downto 0);
        dacdat        : out std_logic;
        ready         : out std_logic
    );
end audio_out;

architecture behavioral of audio_out is

    -- State machine states
    type state_type is (
        WAIT_LEFT_EDGE,     -- Wait for rising edge of DACLRC
        LOAD_SAMPLE,        -- Load sample into shift register
        WAIT_BCLK_HIGH,     -- Wait for BCLK rising edge
        WAIT_BCLK_LOW,      -- Wait for BCLK falling edge
        SHIFT_BIT,          -- Shift out one bit
        WAIT_RIGHT_EDGE,    -- Wait for DACLRC falling edge (right channel ignored)
        SHIFT_EXTRA         -- One extra shift to complete transmission
    );
    signal current_state, next_state : state_type;

    -- Shift register and bit counter
    signal shift_reg    : std_logic_vector(16 downto 0);
    signal bit_count    : integer range 0 to 15;
    signal last_bit     : std_logic;

    -- Synchronized inputs
    signal daclrc_sync  : std_logic;
    signal bclk_sync    : std_logic;

begin

    -- ========== Control Unit ==========

    process (current_state, daclrc_sync, bclk_sync, last_bit)
    begin
        case current_state is
            when WAIT_LEFT_EDGE =>
                if daclrc_sync = '1' and bclk_sync = '0' then
                    next_state <= LOAD_SAMPLE;
                else
                    next_state <= WAIT_LEFT_EDGE;
                end if;

            when LOAD_SAMPLE =>
                next_state <= WAIT_BCLK_HIGH;

            when WAIT_BCLK_HIGH =>
                if bclk_sync = '1' then
                    next_state <= WAIT_BCLK_LOW;
                else
                    next_state <= WAIT_BCLK_HIGH;
                end if;

            when WAIT_BCLK_LOW =>
                if bclk_sync = '0' then
                    next_state <= SHIFT_BIT;
                else
                    next_state <= WAIT_BCLK_LOW;
                end if;

            when SHIFT_BIT =>
                if last_bit = '0' then
                    next_state <= WAIT_BCLK_HIGH;
                elsif daclrc_sync = '0' then
                    next_state <= WAIT_LEFT_EDGE;
                else
                    next_state <= WAIT_RIGHT_EDGE;
                end if;

            when WAIT_RIGHT_EDGE =>
                if daclrc_sync = '0' and bclk_sync = '0' then
                    next_state <= SHIFT_EXTRA;
                else
                    next_state <= WAIT_RIGHT_EDGE;
                end if;

            when SHIFT_EXTRA =>
                next_state <= WAIT_BCLK_HIGH;
        end case;
    end process;

    -- State register
    process (clk, reset)
    begin
        if reset = '1' then
            current_state <= WAIT_LEFT_EDGE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Control output
    ready <= '1' when current_state = LOAD_SAMPLE else '0';

    -- ========== Data Path ==========

    process (clk, reset)
    begin
        if reset = '1' then
            shift_reg <= (others => '0');
            bit_count <= 0;
        elsif rising_edge(clk) then
            case current_state is
                when LOAD_SAMPLE =>
                    shift_reg <= sample & '0';  -- append '0' to LSB

                when SHIFT_BIT | SHIFT_EXTRA =>
                    shift_reg <= shift_reg(15 downto 0) & shift_reg(16);
                    if current_state = SHIFT_BIT then
                        bit_count <= bit_count + 1;
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process;

    dacdat <= shift_reg(16);
    last_bit <= '1' when bit_count = 15 else '0';

    -- Input synchronization
    process (clk, reset)
    begin
        if reset = '1' then
            daclrc_sync <= '0';
            bclk_sync   <= '0';
        elsif rising_edge(clk) then
            daclrc_sync <= daclrc;
            bclk_sync   <= bclk;
        end if;
    end process;

end architecture behavioral;
