--  ============================================================================================================
--  audio_in.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--              Adapted and translated from original work by Andoni Arruti
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Converts serial audio data from the WM8731 codec into 16-bit samples.  
--              Assumes the codec is configured as I2S master using "left-justified" format.  
--              Only the left channel is read and processed.  
--              Although translated and updated, the structure and functions  
--              are essentially unchanged since they follow the codec hardware specification.  
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              July 2025
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;

entity audio_in is
	port (
		clk           : in	std_logic;
		reset         : in	std_logic;
		adclrc        : in  std_logic;
		bclk          : in  std_logic;
		adcdat        : in  std_logic;
		sample        : out std_logic_vector(15 downto 0);
		ready         : out std_logic
	);
end audio_in;

architecture behavioral of audio_in is

	-- State machine states (renamed for clarity)
	type state_type is (
		WAIT_LEFT_START,   -- Wait for left channel to start (ADCLRC low)
		WAIT_BCLK_LOW,     -- Wait for ADCLRC high and BCLK low
		WAIT_BCLK_HIGH,    -- Wait for BCLK rising edge
		SHIFT_SAMPLE_BIT,  -- Shift in ADCDAT bit
		WAIT_NEXT_BIT,     -- Wait for next BCLK falling edge
		SAMPLE_READY       -- All 16 bits received
	);
	signal current_state, next_state : state_type;

	-- Shift register and bit counter
	signal shift_reg    : std_logic_vector(15 downto 0);
	signal bit_count    : integer range 0 to 15;

	-- Control signals
	signal shift_enable : std_logic;
	signal count_enable : std_logic;
	signal last_bit     : std_logic;

	-- Synchronized inputs
	signal adclrc_sync  : std_logic;
	signal bclk_sync    : std_logic;
	signal adcdat_sync  : std_logic;

begin

	-- ========== Control Unit ==========

	-- Next state logic
	process (current_state, adclrc_sync, bclk_sync, last_bit)
	begin
		case current_state is
			when WAIT_LEFT_START =>
				if adclrc_sync = '0' then
					next_state <= WAIT_BCLK_LOW;
				else
					next_state <= WAIT_LEFT_START;
				end if;
			when WAIT_BCLK_LOW =>
				if adclrc_sync = '1' and bclk_sync = '0' then
					next_state <= WAIT_BCLK_HIGH;
				else
					next_state <= WAIT_BCLK_LOW;
				end if;
			when WAIT_BCLK_HIGH =>
				if bclk_sync = '1' then
					next_state <= SHIFT_SAMPLE_BIT;
				else
					next_state <= WAIT_BCLK_HIGH;
				end if;
			when SHIFT_SAMPLE_BIT =>
				if last_bit = '0' then
					next_state <= WAIT_NEXT_BIT;
				else
					next_state <= SAMPLE_READY;
				end if;
			when WAIT_NEXT_BIT =>
				if bclk_sync = '0' then
					next_state <= WAIT_BCLK_HIGH;
				else
					next_state <= WAIT_NEXT_BIT;
				end if;
			when SAMPLE_READY =>
				next_state <= WAIT_LEFT_START;
		end case;
	end process;

	-- State register
	process (clk, reset)
	begin
		if reset = '1' then
			current_state <= WAIT_LEFT_START;
		elsif rising_edge(clk) then
			current_state <= next_state;
		end if;
	end process;
	
	ready        <= '1' when current_state = SAMPLE_READY else '0';

	-- ========== Data Path ==========

	-- Merged shift register and bit counter
	process (clk, reset)
	begin
		if reset = '1' then
			shift_reg <= (others => '0');
			bit_count <= 0;
		elsif rising_edge(clk) then
			if current_state = SHIFT_SAMPLE_BIT then
				shift_reg <= shift_reg(14 downto 0) & adcdat_sync;
				bit_count <= bit_count + 1;
			end if;
		end if;
	end process;

	sample <= shift_reg;
	last_bit <= '1' when bit_count = 15 else '0';

	-- Input signal synchronization
	process (clk, reset)
	begin
		if reset = '1' then
			adclrc_sync  <= '0';
			bclk_sync    <= '0';
			adcdat_sync  <= '0';
		elsif rising_edge(clk) then
			adclrc_sync  <= adclrc;
			bclk_sync    <= bclk;
			adcdat_sync  <= adcdat;
		end if;
	end process;

end architecture behavioral;
