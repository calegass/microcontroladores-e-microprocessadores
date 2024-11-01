#include <lcd_8bits.c>

int1 fim_tempo = 0;
int8 contador = 25;
int16 potenciometro, sensor, largura;

#INT_TIMER0
void TIMER0_isr(void) {
  set_timer0(get_timer0() + 6); // 4,0 ms overflow
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
  setup_timer_2(T2_DIV_BY_4, 199, 1); // 2,0 ms overflow, 2,0 ms interrupt

  lcd_init();

  printf(lcd_write_dat, "A0:");
  lcd_gotoxy(9, 1);
  printf(lcd_write_dat, "A1:");
  lcd_gotoxy(1, 2);
  printf(lcd_write_dat, "P1:");

  setup_ccp1(CCP_PWM);
  setup_ccp2(CCP_PWM);
  set_pwm1_duty((int16)0);
  set_pwm2_duty((int16)0);

  enable_interrupts(INT_TIMER0);
  enable_interrupts(GLOBAL);

  while (TRUE) {
    if (fim_tempo) {
      fim_tempo = 0;

      set_adc_channel(0);
      delay_us(40);
      sensor = read_adc();

      lcd_gotoxy(4, 1);
      printf(lcd_write_dat, "%04Lu", sensor);

      set_adc_channel(1);
      delay_us(40);
      potenciometro = read_adc();

      lcd_gotoxy(10, 1);
      printf(lcd_write_dat, "%04Lu", potenciometro);

      largura = potenciometro / 1023.0 * 799.0;

      set_pwm1_duty(largura);
      lcd_gotoxy(4, 2);
      printf(lcd_write_dat, "%04Lu", largura);

      set_pwm2_duty(largura / 2);
      lcd_gotoxy(9, 2);
      printf(lcd_write_dat, "%04Lu", (largura / 2));
    }
  }
}