#include "alt_types.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "system.h"
#include <stdio.h>
#include <unistd.h>

static alt_u16 count;

static void count_led()
{
#ifdef LED_PIO_BASE
    IOWR_ALTERA_AVALON_PIO_DATA(LED_PIO_BASE,count);
#endif
}


int main(void)
{ 

    count = 0;

    while( 1 ) 
    {
    	if(count >= 0xA){
    		count = 0;
    	}
    	usleep(100000);
        count++;
        count_led();
    }
    return 0;
}
