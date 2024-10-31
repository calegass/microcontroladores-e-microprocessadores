#include <main.h>
#include <lcd_8bits.c>

int1 fim_tempo = 0;
int8 contador = 50;

int1 ligado = 0;
int1 heater_on = 0;

float histerese = 0.1;	// 0.1 - 9.9

int16 temp;
int16 pot;

float temp_c;
float pot_c;

void leitura_botoes();

#INT_TIMER0
void TIMER0_isr(void) {
  set_timer0(get_timer0() + 6);
  contador--;
  if (!contador) {
    contador = 50;	// 200 ms
    fim_tempo = 1;
  }
}

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL|RTCC_DIV_32|RTCC_8_BIT);	//4,0 ms overflow


	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	lcd_init();

	lcd_gotoxy(1, 1);
	printf(lcd_write_dat, "T:");
	lcd_gotoxy(1, 2);
	printf(lcd_write_dat, "P:");

	lcd_gotoxy(12, 1);
	printf(lcd_write_dat, "L");

	lcd_gotoxy(15, 1);
	printf(lcd_write_dat, "E");

	lcd_gotoxy(12, 2);
	printf(lcd_write_dat, "H:");

	while(TRUE)
	{
		leitura_botoes();

		if (fim_tempo) {
			fim_tempo = 0;

			set_adc_channel(1);
			delay_us(20);
			pot = read_adc();
			pot_c = 37.5 + (30.0 * pot / 1023.0);

			set_adc_channel(0);
			delay_us(20);
			temp = read_adc();
			temp_c = 27.5 + ((77.5 - 27.5) * (temp - 341.0) / (742.0 - 341.0));	// menor + ((maior - menor) * (valor - menor) / (maior - menor))
			
			if (ligado) {
				if (temp_c < pot_c - histerese) {
					output_high(HEATER);
					heater_on = 1;
				} else if (temp_c > pot_c + histerese) {
					output_low(HEATER);
					heater_on = 0;
				}
			} else {
				output_low(HEATER);
				heater_on = 0;
			}

			lcd_gotoxy(2, 1);
			printf(lcd_write_dat, "%04LU-%3.1f", temp, temp_c);
			lcd_gotoxy(2, 2);
			printf(lcd_write_dat, "%04LU-%3.1f", pot, pot_c);

			lcd_gotoxy(13, 1);
			printf(lcd_write_dat, "%1d", ligado);
			lcd_gotoxy(16, 1);
			printf(lcd_write_dat, "%1d", heater_on);

			lcd_gotoxy(14, 2);
			printf(lcd_write_dat, "%1.1f", histerese);


		}
	
		//TODO: User Code
	}

}

void leitura_botoes() {
	if (input(B0) == 0) {
		ligado = 1;
	} else if (input(B1) == 0) {
		ligado = 0;
	} else if (input(B2) == 0 && histerese < 9.9) {
		histerese += 0.1;
		delay_ms(200);
	} else if (input(B3) == 0 && histerese > 0.1) {
		histerese -= 0.1;
		delay_ms(200);
	}

	if (histerese < 0.1) {
		histerese = 0.1;
	} else if (histerese > 9.9) {
		histerese = 9.9;
	}
}