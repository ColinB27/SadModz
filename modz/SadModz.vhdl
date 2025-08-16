--  ============================================================================================================
--  SadModz.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749]
--              Co-designed by Zachary Proulx [Electrical Engineering Student @ ETS ELE749]
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Top-level audio modulation module connecting multiple effects:
--              Overdrive, Distortion, Tremolo, Fuzz, and Bitcrusher.
--              This implementation selects the active effect via switches
--              and displays the effect name on 6 7-segment displays.
--  ------------------------------------------------------------------------------------------------------------
--  CREDITS:
--              Jose Angel Gumiel : Audio effect VHDL implementation reference
--              Andoni Arruti : Audio Codec VHDL implementation reference
--              ChatGPT : Formatting and translation
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hex_constants_pkg.all;  

entity SadModz is 
    port(
        CLOCK_50        : in    std_logic;
        KEY             : in    std_logic_vector(0 downto 0);

        -- AUDIO
        AUD_XCK         : out   std_logic;
        AUD_BCLK        : in    std_logic;
        AUD_ADCLRCK     : in    std_logic;
        AUD_DACLRCK     : in    std_logic;
        AUD_ADCDAT      : in    std_logic;
        AUD_DACDAT      : out   std_logic;
        FPGA_I2C_SCLK   : out   std_logic;
        FPGA_I2C_SDAT   : inout std_logic;

        -- HEX DISPLAYS for effect names
        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0);
        HEX4 : out std_logic_vector(6 downto 0);
        HEX5 : out std_logic_vector(6 downto 0);

        -- SWITCHES to select MODZ
        SW   : in std_logic_vector(5 downto 0);
		  
		  -- add a led for ready so it does give a warning haha
		  LEDR : out std_logic_vector(0 downto 0)
		  
    );
end SadModz;

architecture behavioral of SadModz is

	-- array of signals for easier display assignations on 7 segment displays
    signal hex_codes_sel : hex_display_array := (others => (others => '1'));


    -- Signals for audio and modulation
    signal reset              : std_logic := '0';
    signal in_ready           : std_logic := '0';
    signal out_ready          : std_logic := '0';
    signal sample_in          : std_logic_vector(15 downto 0) := (others => '0');
    signal mod_enables        : std_logic_vector( 5 downto 0) := "000001";

    signal odrive_sample_out  : std_logic_vector(15 downto 0) := (others => '0');
    signal trem_sample_out    : std_logic_vector(15 downto 0) := (others => '0');
    signal disto_sample_out   : std_logic_vector(15 downto 0) := (others => '0');
	 signal delay_sample_out   : std_logic_vector(15 downto 0) := (others => '0');
	 signal fuzz_sample_out    : std_logic_vector(15 downto 0) := (others => '0');
	 signal crush_sample_out   : std_logic_vector(15 downto 0) := (others => '0');
    signal sample_out         : std_logic_vector(15 downto 0) := (others => '0');

    constant intensity          : std_logic_vector(15 downto 0) := x"00F8";
    constant multiplier         : std_logic_vector(15 downto 0) := x"03F8";
	 constant threshold          : std_logic_vector(15 downto 0) := x"00D3";

	 -- tremolo parameters
    constant trem_rate          : std_logic_vector(15 downto 0) := x"0960";  -- default ~2400
    constant trem_attack        : std_logic_vector(15 downto 0) := x"0050";  -- min gain
    constant trem_wave          : std_logic_vector( 1 downto 0) := "10";     -- triangle
	 
	 -- bit crusher parameters
	 constant b_crusher_mask     : std_logic_vector(15 downto 0) := x"FF80";
	 constant b_crusher_divider  :         unsigned(15 downto 0) := x"01F0";
	

begin
	 -- ======================================================= PERIPHERALS
    -- Hardware Connections
    reset <= not(KEY(0));
	 mod_enables <= SW(5 downto 0);
	 LEDR(0) <= out_ready;
	 
	 -- Assign HEX outputs
    HEX0 <= hex_codes_sel(0)(6 downto 0);
    HEX1 <= hex_codes_sel(1)(6 downto 0);
    HEX2 <= hex_codes_sel(2)(6 downto 0);
    HEX3 <= hex_codes_sel(3)(6 downto 0);
    HEX4 <= hex_codes_sel(4)(6 downto 0);
    HEX5 <= hex_codes_sel(5)(6 downto 0);
	 
	 -- ====================================================================
	 
	 
	 -- ======================================================= SIGNAL LOGIC
	 -- Output routing based on modulation enable
    with mod_enables select
        sample_out <= odrive_sample_out    when "000001",
                      disto_sample_out     when "000010",
                      trem_sample_out      when "000100",
                      fuzz_sample_out      when "001000",
	    			       crush_sample_out     when "010000",
                      (sample_in)          when others;


    -- Select HEX codes constant based on mod_enables
    with mod_enables select
        hex_codes_sel <= ODRIVE_HEX_CODES     when "000001",
                         DISTORTION_HEX_CODES when "000010",
                         TREMOLO_HEX_CODES    when "000100",
                         FUZZ_HEX_CODES       when "001000",
	    			          CRUSHER_HEX_CODES    when "010000",
                         (others => (others => '1')) when others;
							
	 -- ====================================================================
							
	 
	 -- =============================================== AUDIO CODEC HANDLING
    -- Audio Codec Setup
    inst1: entity work.WM8731_config
        generic map ( SAMPLE_RATE => 3 )
        port map (
            reset           => reset,
            clk_50          => CLOCK_50,
            use_mic         => '0',
            i2c_sdat        => FPGA_I2C_SDAT,
            i2c_sclk        => FPGA_I2C_SCLK,
            aud_xck         => AUD_XCK
        );

    -- Audio Input
    inst2: entity work.audio_in
        port map (
            reset           => reset,
            clk             => CLOCK_50,
            adclrc          => AUD_ADCLRCK,
            bclk            => AUD_BCLK,
            adcdat          => AUD_ADCDAT,
            sample          => sample_in,
            ready           => in_ready
        );

    -- Audio Output
    inst3: entity work.audio_out
        port map (
            reset           => reset,
            clk             => CLOCK_50,
            daclrc          => AUD_DACLRCK,
            bclk            => AUD_BCLK,
            sample          => sample_out,
            dacdat          => AUD_DACDAT,
            ready           => out_ready
        );
	 -- ====================================================================
	
	
	 -- =========================================== AUDIO MODULATION EFFECTS

    inst4: entity work.overdrive
        port map (
            enable          => mod_enables(0),
            sample_in       => sample_in,
            sample_out      => odrive_sample_out,
            clip_pos        => intensity,
            gain            => multiplier
        );

    inst5: entity work.distortion
        port map (
            enable          => mod_enables(1),
            sample_in       => sample_in,
            sample_out      => disto_sample_out,
            gain            => multiplier,
            clip_pos        => intensity
        );

    inst6: entity work.tremolo
        port map (
			   clk             => CLOCK_50,
            reset           => reset, -- CAN BE REMOVED
			   enable          => mod_enables(2),
            load_sample     => in_ready,
            sample_in       => sample_in, -- rename to sample
            sample_out      => trem_sample_out,       -- rename to sample    
            rate            => trem_rate,
            atack           => trem_attack,
            wave            => trem_wave
        );
		  
    inst7: entity work.fuzz
        port map (
				enable          => mod_enables(3),
				sample_in       => sample_in,
				sample_out      => fuzz_sample_out,
				gain            => multiplier,  -- unused but kept for consistency
				fuzz_pos        => threshold
        );
	 
    inst8: entity work.bitcrusher
        port map (
				clk             => CLOCK_50,
				enable          => mod_enables(4),
				sample_in       => sample_in,
				sample_out      => crush_sample_out,
				gain            => multiplier,
				mask            => b_crusher_mask,  
				rate_divider    => b_crusher_divider
        );
	 
	 -- ====================================================================

end behavioral;