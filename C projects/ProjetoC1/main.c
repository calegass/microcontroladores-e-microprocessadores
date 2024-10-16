#include <main.h>

void main()
{
   output_low(LED0);
   output_low(LED1);
   output_low(LED2);
   output_low(LED3);
   
   while(TRUE)
   {
      // LIGAR LEDS
      if (!input(LED3) && !input(RA1)) {
         output_high(LED0);
      }

      if (input(LED0) && !input(RA2)) {
         output_high(LED1);
      }

      if (input(LED1) && !input(RA3)) {
         output_high(LED2);
      }

      if (input(LED2) && !input(RA4)) {
         output_high(LED3);
      }

      // DESLIGAR LEDS
      if (input(LED3) && !input(RA1)) {
         output_low(LED0);
      }

      if (input(LED3) && !input(LED0) && !input(RA2)) {
         output_low(LED1);
      }

      if (input(LED3) && !input(LED1) && !input(RA3)) {
         output_low(LED2);
      }

      if (input(LED3) && !input(LED2) && !input(RA4)) {
         output_low(LED3);
      }
   }
}
