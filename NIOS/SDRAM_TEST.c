#include <stdio.h>
#include <alt_types.h>
#include <io.h>
#include <system.h>
#include <string.h>
#include <unistd.h>

#include "sys/alt_dma.h"
#include "system.h"
#include "sys/alt_flash.h"
#include "sys/alt_flash_dev.h"



static alt_u8 count;
static alt_u8 read_data;

static void display_leds(alt_u16 value)
{
#ifdef LED_PIO_BASE
    IOWR_ALTERA_AVALON_PIO_DATA(LED_PIO_BASE, value);
#endif
}

int run_test(void)
{
    count = 0;

    while(1)
    {
        // Update count value
        if (count >= 0x1F) {
            count = 0;
        } else {
            count++;
        }

        // Write to memory
        IOWR_8DIRECT(SDRAM_BASE, 4, count);

        // Read from memory
        read_data = IORD_8DIRECT(SDRAM_BASE, 4);

        // Combine first 5 bits of read_data and count
        alt_16 display_value = ((read_data & 0x1F) << 5) | (count & 0x1F);

        // Pass combined value to LEDs
        display_leds(display_value);

        usleep(100000);
    }

    return 0;
}

/******************************************************************
*  Function: main
*
*  Purpose: Continually prints the menu and performs the actions
*           requested by the user.
* 
******************************************************************/
int main(void)
{
  run_test();
}

