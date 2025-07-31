library ieee;
use ieee.std_logic_1164.all;

package hex_constants_pkg is

    type hex_display_array is array (0 to 5) of std_logic_vector(7 downto 0);

    constant ODRIVE_HEX_CODES : hex_display_array := (
        0 => x"A3",
        1 => x"BF",
        2 => x"A1",
        3 => x"AF",
        4 => x"EF",
        5 => x"E3"
    );

    constant DISTORTION_HEX_CODES : hex_display_array := (
    0 => x"FF",
    1 => x"FF",
    2 => x"F0",
    3 => x"A4",
    4 => x"F9",
    5 => x"81"
    );

    constant TREMOLO_HEX_CODES : hex_display_array := (
    0 => x"F1",
    1 => x"81",
    2 => x"89",
    3 => x"B0",
    4 => x"FA",
    5 => x"F0"
    );

    constant BOOSTER_HEX_CODES : hex_display_array := (
    0 => x"FF",
    1 => x"F0",
    2 => x"A4",
    3 => x"81",
    4 => x"81",
    5 => x"80"
    );


    -- You can add more constants here for other effects

end package hex_constants_pkg;

package body hex_constants_pkg is
end package body hex_constants_pkg;
