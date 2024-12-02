#include <modulo1.h>
#include <lcd_8bits.c>

#define INICIO 0
#define CMD_HEATER_ON 1
#define CMD_HEATER_OFF 2
#define CMD_COOLER_ON 3
#define CMD_COOLER_OFF 4

int1 fim_tempo = 0;
int8 contador = 50;
int8 index;
int16 temp = 0;
int16 pot = 0;
int16 new_temp = 0;
int16 new_pot = 0;
char buffer[20];

void process_command(int8 command);

#INT_RDA
void RDA_isr(void) {
    char c = getc();
    if (c == '@') {
        index = 0;
    }
    buffer[index++] = c;
    if (c == '#') {
        buffer[index] = '\0';
        process_command(buffer[1]);
    }
}

#INT_TIMER0
void TIMER0_isr(void) {
    set_timer0(get_timer0() + 6);
    contador--;
    if (contador == 0) {
        contador = 50;
        fim_tempo = 1;
    }
}

void main() {
    setup_adc(ADC_CLOCK_INTERNAL);
    setup_adc_ports(ALL_ANALOG);
    setup_timer_0(RTCC_INTERNAL|RTCC_DIV_16|RTCC_8_BIT);      //4,0 ms overflow
    enable_interrupts(INT_RDA);
    enable_interrupts(INT_TIMER0);
    enable_interrupts(GLOBAL);

    lcd_init();

    index = 0;
    
    lcd_gotoxy(1, 2);
    printf(lcd_write_dat, "H:OFF C:OFF");

    while (TRUE) {
        if (fim_tempo) {
            fim_tempo = 0;

            set_adc_channel(0);
            delay_us(20);
            new_temp = read_adc();

            set_adc_channel(1);
            delay_us(20);
            new_pot = read_adc();

			if (new_temp != temp || new_pot != pot) {
				temp = new_temp;
				pot = new_pot;

				lcd_gotoxy(1, 1);
				printf(lcd_write_dat, "T:%04LU P:%04LU", temp, pot);

				printf("@%04LU%04LU#", temp, pot);
				delay_ms(100);
			}
		}
    }
}

void process_command(int8 command) {
    switch (command) {
        case INICIO:
            printf("@%04LU%04LU#", temp, pot);
            break;
        case CMD_HEATER_ON:
            lcd_gotoxy(1, 2);
            printf(lcd_write_dat, "H:ON ");
            output_high(C2);
            break;
        case CMD_HEATER_OFF:
            lcd_gotoxy(1, 2);
            printf(lcd_write_dat, "H:OFF");
            output_low(C2);
            break;
        case CMD_COOLER_ON:
            lcd_gotoxy(7, 2);
            printf(lcd_write_dat, "C:ON ");
            output_high(C1);
            break;
        case CMD_COOLER_OFF:
            lcd_gotoxy(7, 2);
            printf(lcd_write_dat, "C:OFF");
            output_low(C1);
            break;
    }
}