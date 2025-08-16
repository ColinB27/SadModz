--  ============================================================================================================
--  WM8731_config.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--              Adapted and translated from original work by Andoni Arruti
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Configuration module for the WM8731 Audio Codec on the DE1-SoC board.
--              Initializes the codec registers and sets up audio input/output paths.  
--              Although this version has been adapted and translated, the structure  
--              and functions remain essentially the same as the original, since they  
--              are defined by the codec hardware specification.  
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              Original adaptation November 2016  
--              Reformatted August 2025
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WM8731_config is
	generic (
		SAMPLE_RATE : integer range 1 to 3 := 3  -- 1 = 8kHz, 2 = 48kHz, 3 = 32kHz
	);
	port (
		reset       : in std_logic;
		clk_50      : in std_logic;
		use_mic     : in std_logic;       -- '1' for MIC, '0' for LINE-IN
		i2c_sdat    : inout std_logic;
		i2c_sclk    : out std_logic;
		aud_xck     : out std_logic
	);
end WM8731_config;

architecture rtl of WM8731_config is

	-- FSM states
	type state_type is (idle, start, wait_ack, shift_out, next_reg, done);
	signal current_state, next_state : state_type;

	-- Bit counter
	signal bit_counter     : integer range 0 to 24;
	signal inc_bit         : std_logic;
	signal clr_bit         : std_logic;
	signal is_last_bit     : std_logic;
	signal pause_transmit  : std_logic;

	-- Register address counter
	constant NUM_REGISTERS : integer := 7;
	signal reg_index       : integer range 0 to NUM_REGISTERS;
	signal inc_reg         : std_logic;
	signal clr_reg         : std_logic;
	signal is_last_reg     : std_logic;

	-- Delay counter (clock divider)
	signal delay_counter   : unsigned(7 downto 0);
	signal inc_delay       : std_logic;
	signal reset_delay     : std_logic;
	signal delay_rising    : std_logic;
	signal delay_falling   : std_logic;

	-- I2C data signals
	signal data_bit        : std_logic;
	signal load_data_bit   : std_logic;
	signal set_data_0      : std_logic;
	signal set_data_1      : std_logic;
	signal set_data_highz  : std_logic;
	signal sdat_driver     : std_logic;

	-- Configuration data
	signal config_data     : std_logic_vector(0 to 23);

	-- Clock divider for XCK (divide by 4)
	signal clk_div         : unsigned(1 downto 0);

begin

	-- Configuration data values
	config_data(0 to 7) <= "00110100";  -- WM8731 write address

	 process (reg_index, use_mic)
	 begin
		case reg_index is
			when 0 =>
				config_data(8 to 23) <= x"0C00";  -- Power down: disable
			when 1 =>
				config_data(8 to 23) <= x"0E41";  -- Audio format: master, 16-bit, left justified
			when 2 =>
				case SAMPLE_RATE is
					when 3 =>      config_data(8 to 23) <= x"1000"; -- 32kHz
					when 2 =>      config_data(8 to 23) <= x"1018"; -- 48kHz
					when others => config_data(8 to 23) <= x"100C"; -- 8kHz
				end case;
			when 3 =>
				if use_mic = '1' then
					config_data(8 to 23) <= x"0814";  -- MIC input, DAC output
				else
					config_data(8 to 23) <= x"0810";  -- LINE-IN input, DAC output
				end if;
			when 4 =>
				config_data(8 to 23) <= x"0579";  -- Output volume: LOUT & ROUT
			when 5 =>
				config_data(8 to 23) <= x"0117";  -- Input volume: LIN & RIN
			when 6 =>
				config_data(8 to 23) <= x"0A00";  -- Enable DAC
			when NUM_REGISTERS =>
				config_data(8 to 23) <= x"1201";  -- Activate interface
			when others =>
				config_data(8 to 23) <= (others => '0');
		end case;
	 end process;

	-- FSM: Next state logic
	process (current_state, delay_falling, delay_rising, pause_transmit, is_last_bit, is_last_reg, i2c_sdat)
	begin
		case current_state is
			when idle =>
				if delay_falling = '1' then next_state <= start;
				else next_state <= idle;
				end if;

			when start =>
				if delay_falling = '1' and pause_transmit = '1' then next_state <= wait_ack;
				else next_state <= start;
				end if;

			when wait_ack =>
				if delay_rising = '0' then
					next_state <= wait_ack;
				elsif i2c_sdat = '1' then
					next_state <= idle;
				else
					next_state <= shift_out;
				end if;

			when shift_out =>
				if delay_falling = '0' then
					next_state <= shift_out;
				elsif is_last_bit = '0' then
					next_state <= start;
				else
					next_state <= next_reg;
				end if;

			when next_reg =>
				if delay_falling = '0' then
					next_state <= next_reg;
				elsif is_last_reg = '0' then
					next_state <= idle;
				else
					next_state <= done;
				end if;

			when done =>
				next_state <= done;
		end case;
	end process;

	-- FSM: State register
	process (clk_50, reset)
	begin
		if reset = '1' then
			current_state <= idle;
		elsif rising_edge(clk_50) then
			current_state <= next_state;
		end if;
	end process;

	-- Control signals
	inc_delay     <= '0' when current_state = done else '1';
	reset_delay   <= '1' when (current_state = idle and delay_falling = '1')
	                     or (current_state = wait_ack and delay_rising = '1' and i2c_sdat = '1')
	                     or (current_state = next_reg and delay_falling = '1' and is_last_reg = '0') else '0';

	set_data_0    <= '1' when (current_state = idle and delay_falling = '1')
	                     or (current_state = shift_out and delay_falling = '1' and is_last_bit = '1') else '0';

	set_data_1    <= '1' when (current_state = next_reg and delay_falling = '1') else '0';

	set_data_highz<= '1' when (current_state = wait_ack or current_state = shift_out) else '0';

	load_data_bit <= '1' when (current_state = start and delay_falling = '1' and pause_transmit = '0')
	                     or (current_state = shift_out and delay_falling = '1' and is_last_bit = '0') else '0';

	inc_bit       <= load_data_bit;
	clr_bit       <= '1' when (current_state = wait_ack and delay_rising = '1' and i2c_sdat = '1')
	                     or (current_state = next_reg and delay_falling = '1' and is_last_reg = '0') else '0';

	clr_reg       <= clr_bit;
	inc_reg       <= '1' when (current_state = next_reg and delay_falling = '1' and is_last_reg = '0') else '0';

	-- Bit counter
	process (clk_50, reset)
	begin
		if reset = '1' then
			bit_counter <= 0;
		elsif rising_edge(clk_50) then
			if inc_bit = '1' then
				bit_counter <= bit_counter + 1;
			elsif clr_bit = '1' then
				bit_counter <= 0;
			end if;
		end if;
	end process;

	pause_transmit <= '1' when bit_counter = 8 or bit_counter = 16 or bit_counter = 24 else '0';
	is_last_bit    <= '1' when bit_counter = 24 else '0';

	-- Register address counter
	process (clk_50, reset)
	begin
		if reset = '1' then
			reg_index <= 0;
		elsif rising_edge(clk_50) then
			if inc_reg = '1' then
				reg_index <= reg_index + 1;
			elsif clr_reg = '1' then
				reg_index <= 0;
			end if;
		end if;
	end process;

	is_last_reg <= '1' when reg_index = NUM_REGISTERS else '0';

	-- Delay counter (I2C clock generation)
	process (clk_50, reset)
	begin
		if reset = '1' then
			delay_counter <= "10000000";
		elsif rising_edge(clk_50) then
			if reset_delay = '1' then
				delay_counter <= "10000000";
			elsif inc_delay = '1' then
				delay_counter <= delay_counter + 1;
			end if;
		end if;
	end process;

	i2c_sclk     <= delay_counter(7);
	delay_rising <= '1' when delay_counter = "01111111" else '0';
	delay_falling<= '1' when delay_counter = "11111111" else '0';

	-- I2C data output
	process (clk_50, reset)
	begin
		if reset = '1' then
			sdat_driver <= '1';
		elsif rising_edge(clk_50) then
			if load_data_bit = '1' then
				sdat_driver <= data_bit;
			elsif set_data_0 = '1' then
				sdat_driver <= '0';
			elsif set_data_1 = '1' then
				sdat_driver <= '1';
			end if;
		end if;
	end process;

	data_bit <= config_data(bit_counter);
	i2c_sdat <= sdat_driver when set_data_highz = '0' else 'Z';

	-- Clock output (divide clk_50 by 4)
	process (clk_50, reset)
	begin
		if reset = '1' then
			clk_div <= "00";
		elsif rising_edge(clk_50) then
			clk_div <= clk_div + 1;
		end if;
	end process;

	aud_xck <= clk_div(1);

end rtl;
