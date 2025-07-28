library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testaudio_DE1SoC is 
	port(
		CLOCK_50        : in  std_logic;
		KEY             : in  std_logic_vector(0 downto 0);

		-- AUDIO
		AUD_XCK         : out std_logic;
		AUD_BCLK        : in  std_logic;
		AUD_ADCLRCK     : in  std_logic;
		AUD_DACLRCK     : in  std_logic;
		AUD_ADCDAT      : in  std_logic;
		AUD_DACDAT      : out std_logic;
		FPGA_I2C_SCLK   : out std_logic;
		FPGA_I2C_SDAT   : inout std_logic;

		-- ADC
		SW              : in  std_logic_vector(9 downto 0);
		LEDR            : out std_logic_vector(9 downto 0);
		ADC_SCLK        : out std_logic;
		ADC_CS_N        : out std_logic;
		ADC_DOUT        : in  std_logic;
		ADC_DIN         : out std_logic;

		-- HEX DISPLAYS
		HEX0 : out std_logic_vector(0 to 6);
		HEX1 : out std_logic_vector(0 to 6);
		HEX2 : out std_logic_vector(0 to 6);
		HEX3 : out std_logic_vector(0 to 6);
		HEX4 : out std_logic_vector(0 to 6);
		HEX5 : out std_logic_vector(0 to 6)
	);
end testaudio_DE1SoC;

architecture a of testaudio_DE1SoC is

	-- Components
	component au_setup
		generic ( SAMPLE_RATE : integer range 1 to 3 );
		port (
			reset     : in std_logic;
			clk_50    : in std_logic;
			mic_lin   : in std_logic;
			i2c_sdat  : inout std_logic;
			i2c_sclk  : out std_logic;
			aud_xck   : out std_logic
		);
	end component;

	component au_in
		port (
			clk, reset : in std_logic;
			adclrc     : in std_logic;
			bclk       : in std_logic;
			adcdat     : in std_logic;
			sample     : out std_logic_vector(15 downto 0);
			ready      : out std_logic
		);
	end component;

	component au_out
		port (
			clk, reset : in std_logic;
			daclrc     : in std_logic;
			bclk       : in std_logic;
			sample     : in std_logic_vector(15 downto 0);
			dacdat     : out std_logic;
			ready      : out std_logic
		);
	end component;

	-- Signals
	signal reset        : std_logic;
	signal in_ready     : std_logic;
	signal out_ready    : std_logic;
	signal sample_in    : std_logic_vector(15 downto 0);
	signal sample_out   : std_logic_vector(15 downto 0);

begin

	-- Reset is active-low
	reset <= not(KEY(0));

	-- Audio Codec Setup
	inst1: au_setup
		generic map ( SAMPLE_RATE => 3 )  -- 32 kHz
		port map (
			reset     => reset,
			clk_50    => CLOCK_50,
			mic_lin   => '0',               -- Use LINE-IN
			i2c_sdat  => FPGA_I2C_SDAT,
			i2c_sclk  => FPGA_I2C_SCLK,
			aud_xck   => AUD_XCK
		);

	-- Audio Input (from WM8731 ADC)
	inst2: au_in
		port map (
			reset   => reset,
			clk     => CLOCK_50,
			adclrc  => AUD_ADCLRCK,
			bclk    => AUD_BCLK,
			adcdat  => AUD_ADCDAT,
			sample  => sample_in,
			ready   => in_ready
		);

	-- Audio Output (to WM8731 DAC)
	inst3: au_out
		port map (
			reset   => reset,
			clk     => CLOCK_50,
			daclrc  => AUD_DACLRCK,
			bclk    => AUD_BCLK,
			sample  => sample_out,
			dacdat  => AUD_DACDAT,
			ready   => out_ready
		);

	-- Pass-through: Input sample goes directly to output
	sample_out <= sample_in;

	-- Optional: Clear displays and LEDs
	LEDR <= (others => '0');
	HEX0 <= "1111111"; -- blank
	HEX1 <= "1111111";
	HEX2 <= "1111111";
	HEX3 <= "1111111";
	HEX4 <= "1111111";
	HEX5 <= "1111111";

end a;
