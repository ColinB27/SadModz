library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hex_constants_pkg.all;  -- Import your constants package

entity SadModz is 
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
end SadModz;

architecture behavioral of SadModz is

    -- Signals and types
    type hex_display_array is array (0 to 5) of std_logic_vector(7 downto 0);

    signal HEX : hex_display_array := (
        others => (others => '1')  -- blank by default
    );

    signal hex_codes_sel : hex_display_array;

    -- Signals for audio and modulation
    signal reset        : std_logic;
    signal in_ready     : std_logic;
    signal out_ready    : std_logic;
    signal sample_in    : std_logic_vector(15 downto 0);
    signal mod_enables  : std_logic_vector(5 downto 0) := "000001";

    signal odrive_sample_out : std_logic_vector(15 downto 0);
    signal trem_sample_out   : std_logic_vector(15 downto 0);
    signal disto_sample_out  : std_logic_vector(15 downto 0);
    signal sample_out        : std_logic_vector(15 downto 0);

    signal intensity         : std_logic_vector(15 downto 0) := x"00F8";
    signal multiplier        : std_logic_vector(15 downto 0) := x"00F8";

    signal trem_rate       : std_logic_vector(15 downto 0) := x"0960";  -- default ~2400
    signal trem_attack     : std_logic_vector(15 downto 0) := x"0050";  -- min gain
    signal trem_wave       : std_logic_vector(1 downto 0) := "10";      -- triangle

begin

    -- Reset is active-low
    reset <= not(KEY(0));

    -- Audio Codec Setup
    inst1: entity work.WM8731_config
        generic map ( SAMPLE_RATE => 3 )
        port map (
            reset     => reset,
            clk_50    => CLOCK_50,
            use_mic   => '0',
            i2c_sdat  => FPGA_I2C_SDAT,
            i2c_sclk  => FPGA_I2C_SCLK,
            aud_xck   => AUD_XCK
        );

    -- Audio Input
    inst2: entity work.audio_in
        port map (
            reset   => reset,
            clk     => CLOCK_50,
            adclrc  => AUD_ADCLRCK,
            bclk    => AUD_BCLK,
            adcdat  => AUD_ADCDAT,
            sample  => sample_in,
            ready   => in_ready
        );

    -- Audio Output
    inst3: entity work.audio_out
        port map (
            reset   => reset,
            clk     => CLOCK_50,
            daclrc  => AUD_DACLRCK,
            bclk    => AUD_BCLK,
            sample  => sample_out,
            dacdat  => AUD_DACDAT,
            ready   => out_ready
        );

    -- Overdrive
    inst4: entity work.overdrive
        port map (
            enable     => mod_enables(1),
            sample_in  => sample_in,
            dist_pos   => intensity,
            gain       => multiplier,
            sample_out => odrive_sample_out
        );

    -- Distortion
    inst5: entity work.distortion
        port map (
            enable      => mod_enables(2),
            sample_in   => sample_in,
            sample_out  => disto_sample_out,
            gain        => multiplier,
            dist_pos    => intensity
        );

    -- Tremolo
    inst6: entity work.tremolo
        port map (
            audio_in     => sample_in,
            audio_out    => trem_sample_out,
            enable       => mod_enables(3),
            load_sample  => in_ready,
            clk          => CLOCK_50,
            reset        => reset,
            rate         => trem_rate,
            atack        => trem_attack,
            wave         => trem_wave
        );

    -- Output routing based on modulation enable
    with mod_enables select
        sample_out <= sample_in          when "000001",
                      odrive_sample_out  when "000010",
                      disto_sample_out   when "000100",
                      trem_sample_out    when "001000",
                      (others => '0')    when others;

    -- Select HEX codes constant based on mod_enables
    with mod_enables select
        hex_codes_sel <= BOOSTER_HEX_CODES     when "000000",
                         ODRIVE_HEX_CODES      when "000010",
                         DISTORTION_HEX_CODES  when "000100",
                         TREMOLO_HEX_CODES     when "001000",
                         (others => (others => '1')) when others;  -- blank

    -- Assign HEX outputs (7 bits each) from hex_codes_sel bits 6 downto 0 (ignore MSB bit 7)
    HEX0 <= hex_codes_sel(0)(6 downto 0);
    HEX1 <= hex_codes_sel(1)(6 downto 0);
    HEX2 <= hex_codes_sel(2)(6 downto 0);
    HEX3 <= hex_codes_sel(3)(6 downto 0);
    HEX4 <= hex_codes_sel(4)(6 downto 0);
    HEX5 <= hex_codes_sel(5)(6 downto 0);

    -- LEDs blank
    LEDR <= (others => '0');

end behavioral;
