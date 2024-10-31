#include <main.h>
#include <lcd_8bits.c>

int1 fim_tempo = 0;
int8 contador = 25;
int16 potenciometro;
float tensao;

#INT_TIMER0
void TIMER0_isr(void) {
  set_timer0(get_timer0() + 6);
  contador--;
  if (!contador) {
    contador = 25;
    fim_tempo = 1;
  }
}

void main() {
  setup_adc_ports(AN0_AN1_AN3);
  setup_adc(ADC_CLOCK_INTERNAL);
  setup_timer_0(RTCC_INTERNAL | RTCC_DIV_16 | RTCC_8_BIT); // 4,0 ms overflow

  lcd_init();

  // lcd_write_dat('I');
  // lcd_write_dat('F');
  // lcd_write_dat('T');
  // lcd_write_dat('M');

  lcd_gotoxy(7, 1);
  printf(lcd_write_dat, "IFTM");

  lcd_gotoxy(1, 2);
  printf(lcd_write_dat, "POT:");

  enable_interrupts(INT_TIMER0);
  enable_interrupts(GLOBAL);

  while (TRUE) {
    if (fim_tempo) {
      fim_tempo = 0;
      set_adc_channel(1);
      delay_us(40);
      potenciometro = read_adc();

      tensao = potenciometro * 5.0 / 1023.0;

      lcd_gotoxy(5, 2);
      printf(lcd_write_dat, "%04Lu - %4.3f", potenciometro, tensao);
    }
    // TODO: User Code
  }
}
