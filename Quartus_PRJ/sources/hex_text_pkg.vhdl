--  ============================================================================================================
--  hex_constants_pkg.vhdl
--  ============================================================================================================
--  AUTHOR(S): 
--              Colin Boule [Electrical Engineering Student @ ETS ELE749] 
--  ------------------------------------------------------------------------------------------------------------
--  DESCRIPTION:
--              Package defining hexadecimal codes for 7-segment displays on the DE1-SoC board.  
--              Each constant encodes a sequence of characters (letters, symbols, or blanks)  
--              to represent the names of different audio effects (Overdrive, Distortion, Tremolo,  
--              Fuzz, and Bitcrusher) across six 7-segment displays.  
--              
--              This package centralizes the display mappings, ensuring that effect modules  
--              reference a consistent set of codes. While customizable, the overall structure  
--              remains hardware-driven, reflecting the limitations of the 7-segment display.  
--  ------------------------------------------------------------------------------------------------------------
--  UPDATED: 
--              August 2025 Creation
--  ============================================================================================================

library ieee;
use ieee.std_logic_1164.all;

package hex_constants_pkg is

    type hex_display_array is array (5 downto 0) of std_logic_vector(7 downto 0);

    constant ODRIVE_HEX_CODES : hex_display_array := (
        5 => x"A3", -- o
        4 => x"BF", -- -
        3 => x"A1", -- d
        2 => x"AF", -- r
        1 => x"EF", -- i
        0 => x"E3"  -- v
    );

    constant DISTORTION_HEX_CODES : hex_display_array := (
	    5 => x"A1", -- d
	    4 => x"EF", -- i
	    3 => x"A4", -- S
	    2 => x"87", -- t
	    1 => x"C0", -- o
	    0 => x"FF"  -- Blank
    );

    constant TREMOLO_HEX_CODES : hex_display_array := (
	    5 => x"87", -- t
	    4 => x"AF", -- r
	    3 => x"86", -- E
	    2 => x"C0", -- O
	    1 => x"C7", -- L
	    0 => x"FF"  -- Blank 
    );
	 
	 constant FUZZ_HEX_CODES : hex_display_array := (
	    5 => x"8E", -- F
	    4 => x"C1", -- U
	    3 => x"A4", -- Z
	    2 => x"A4", -- Z
	    1 => x"FF", -- blank
	    0 => x"FF"  -- blank
    );

    constant CRUSHER_HEX_CODES : hex_display_array := (
	    5 => x"C6", -- C
	    4 => x"AF", -- r
	    3 => x"C1", -- U
	    2 => x"92", -- S
	    1 => x"89", -- H
	    0 => x"FF"  -- blank
    );

end package hex_constants_pkg;

package body hex_constants_pkg is
end package body hex_constants_pkg;
