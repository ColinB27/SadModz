library ieee;
use ieee.std_logic_1164.all;

entity QSYS_SDRAM is
	port(
		clock_50 : in std_logic;
		LEDR : out std_logic_vector(9 downto 0)
		);
		end QSYS_SDRAM;
		
architecture behavioral of QSYS_SDRAM is
		
	component SDRAM_TEST is
		port(
			clk_clk       : in std_logic := '0';
			reset_reset_n : in std_logic := '0';
			ledr_export   : out std_logic_vector(9 downto 0) := (others => '0')
		);
		end component;
		
begin

	nios : SDRAM_TEST
	port map(
		clk_clk       => clock_50,
		reset_reset_n => '0',
		ledr_export   => ledr
	);
end behavioral;