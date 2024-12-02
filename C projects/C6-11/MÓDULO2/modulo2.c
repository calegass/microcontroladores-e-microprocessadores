#include <modulo2.h>
#include <lcd_8bits.c>

#define INICIO 0
#define CMD_HEATER_ON 1
#define CMD_HEATER_OFF 2
#define CMD_COOLER_ON 3
#define CMD_COOLER_OFF 4

char buffer[20];
int index = 0;
int16 temp = 0;
int16 pot = 0;
int16 timeout = 0;

void parse_values(char* buffer, int16* temp, int16* pot);
void custom_strncpy(char* dest, char* src, int n);
int16 custom_atol(char* str);

#INT_RDA
void RDA_isr(void) {
    char c = getc();
    if (c == '@') {
        index = 0;
        timeout = 0;
    }
    buffer[index++] = c;
    if (c == '#') {
        buffer[index] = '\0';
        parse_values(buffer, &temp, &pot);
        lcd_gotoxy(1, 1);
        printf(lcd_write_dat, "T:%04LU P:%04LU", temp, pot);
        index = 0;
    }
}


void main() {
    enable_interrupts(INT_RDA);
    enable_interrupts(GLOBAL);

    lcd_init();

    printf("@%c#", INICIO);

    lcd_gotoxy(1, 2);
    printf(lcd_write_dat, "H:OFF C:OFF");

    while(TRUE) {
        if (input(B0) == 0) {
            printf("@%c#", CMD_HEATER_ON);
            lcd_gotoxy(1, 2);
            printf(lcd_write_dat, "H:ON ");
            delay_ms(200);
        }
        if (input(B1) == 0) {
            printf("@%c#", CMD_HEATER_OFF);
            lcd_gotoxy(1, 2);
            printf(lcd_write_dat, "H:OFF");
            delay_ms(200);
        }
        if (input(B2) == 0) {
            printf("@%c#", CMD_COOLER_ON);
            lcd_gotoxy(7, 2);
            printf(lcd_write_dat, "C:ON ");
            delay_ms(200);
        }
        if (input(B3) == 0) {
            printf("@%c#", CMD_COOLER_OFF);
            lcd_gotoxy(7, 2);
            printf(lcd_write_dat, "C:OFF");
            delay_ms(200);
        }

        timeout++;
        if (timeout > 10000) {
            index = 0;
            timeout = 0;
        }
    }
}

void custom_strncpy(char* dest, char* src, int n) {
    for (int i = 0; i < n; i++) {
        dest[i] = src[i];
    }
    dest[n] = '\0';
}

int16 custom_atol(char* str) {
    int16 result = 0;
    for (int i = 0; str[i] != '\0'; i++) {
        result = result * 10 + (str[i] - '0');
    }
    return result;
}

void parse_values(char* buffer, int16* temp, int16* pot) {
    char temp_str[5];
    char pot_str[5];

    custom_strncpy(temp_str, buffer + 1, 4);
    *temp = custom_atol(temp_str);

    custom_strncpy(pot_str, buffer + 5, 4);
    *pot = custom_atol(pot_str);
}