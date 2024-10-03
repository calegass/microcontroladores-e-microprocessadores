/*
 * File:   newmain.c
 * Author: matheus
 *
 * Created on 20 de Setembro de 2024, 17:59
 */

#include <xc.h>

__CONFIG( FOSC_HS & WDTE_OFF & PWRTE_OFF & CP_OFF & BOREN_ON & LVP_OFF & CPD_OFF & WRT_OFF & DEBUG_OFF);

#define R1 RB0
#define R2 RB1
#define R3 RB2
#define R4 RB3
#define C1 RB4
#define C2 RB5
#define C3 RB6

void delay_ms(unsigned int milliseconds);
unsigned char key();
void keyinit();
void blink(unsigned int n, unsigned int v_delay_ms, unsigned int port);
void display(unsigned char num, char port);
void timer0_init(void);

unsigned char keypad[4][3]={{'1','2','3'},{'4','5','6'},{'7','8','9'},{'*','0','#'}};
unsigned char rowloc,colloc;
unsigned char display_state = 1; // Estado para alternar "_" e display apagado
unsigned int interrupt_count = 0;  // Contador de interrupï¿½ï¿½es

void __interrupt() isr() {
    if (T0IF) {
        T0IF = 0;  // Limpar flag de interrupï¿½ï¿½o do Timer0
        TMR0 = 61;  // Reiniciar o Timer0 para prï¿½xima contagem

        interrupt_count++;  // Incrementa o contador de interrupï¿½ï¿½es

        if (interrupt_count >= 38) {  // 38 interrupï¿½ï¿½es equivalem a ~500ms
            interrupt_count = 0;  // Reseta o contador
            if (display_state) {
                display(11, 'C');  // Mostrar "_"
                display(11, 'D');
            } else {
                display(12, 'C');  // Apagar display
                display(12, 'D');
            }
            display_state = !display_state;  // Alterna estado
        }
    }
}

void main(void) {
    TRISA = 0x00;
    TRISC = 0x00;
    TRISD = 0x00;
    
    keyinit();
    timer0_init();
    
    while(1) {
        T0IE = 0;

        display(10, 'C');
        display(10, 'D');

        unsigned char password[2] = {0, 0};
        unsigned char new_password[2] = {0, 0};

        unsigned char confirmation = 0;
        while(confirmation != '*') {
            confirmation = key();
        }

        T0IE = 1;

        display(11, 'C');
        display(11, 'D');

//        blink(1, 1000, 0);

        for (unsigned char i = 0; i < 2; i++) {
            while(password[i] == 0) {
                password[i] = key();  // Obtem o valor da tecla pressionada
                if (password[i] == '*' || password[i] == '#') {
                    password[i] = 0;
                    // Chamada para o buzzer
                    blink(3, 200, 2);  // Faz o buzzer emitir três "pis" com 200ms de intervalo
                    blink(1, 500, 1);
                }
            }
            if(i == 0) {
                T0IE = 0;
                display(11, 'C');
                display(password[i] - 48, 'D');
            } else {
                display(password[i - 1] - 48, 'C');
                display(password[i] - 48, 'D');
            }
    //        blink(1, 500, 2);
        }

        blink(1, 1000, 0);
        
        while(1) {
            PORTAbits.RA1 = 0xFF;

            T0IE = 1;

            display(11, 'C');
            display(11, 'D');
            
            for (unsigned char i = 0; i < 2; i++) {
                while(new_password[i] == 0) {
                    new_password[i] = key();  // Obtem o valor da tecla pressionada
                    if (new_password[i] == '*' || new_password[i] == '#') {
                        new_password[i] = 0;
                        blink(1, 500, 1);
                        PORTAbits.RA1 = 0xFF;
                    }
                }
                if(i == 0) {
                    T0IE = 0;
                    display(11, 'C');
                    display(new_password[i] - 48, 'D');
                } else {
                    display(new_password[i - 1] - 48, 'C');
                    display(new_password[i] - 48, 'D');
                }
        //        blink(1, 500, 2);
            }

            if (password[0] == new_password[0] && password[1] == new_password[1]) {
                blink(1, 2500, 0);
                break;
            } else {
                blink(1, 1000, 1);
                new_password[0] = 0;
                new_password[1] = 0;
            }
        }
    }
}

void delay_ms(unsigned int milliseconds)
{
    unsigned int i;
    unsigned int j;
    for (i = 0; i < milliseconds; i++)
    {
        for (j = 0; j < 500; j++) // Ajuste para gerar aproximadamente 1ms de atraso para 20 MHz
        {
            // Loop de atraso
        }
    }
}

void blink(unsigned int n, unsigned int v_delay_ms, unsigned int port) {
   for (unsigned char t = 0; t < n; t++) {
       switch (port) {
            case 0:
                PORTAbits.RA0 = 0xFF;
                delay_ms(v_delay_ms);
                PORTAbits.RA0 = 0x00;
                delay_ms(v_delay_ms);
                break;
            case 1: 
                PORTAbits.RA1 = 0xFF;
                delay_ms(v_delay_ms);
                PORTAbits.RA1 = 0x00;
                delay_ms(v_delay_ms);
                break;
            case 2:
                PORTAbits.RA2 = 0xFF;
                delay_ms(v_delay_ms);
                PORTAbits.RA2 = 0x00;
                delay_ms(v_delay_ms);
                break;
       }
   }
}

void keyinit()
{
    TRISB=0XF0;
    OPTION_REG&=0X7F;           //ENABLE PULL UP
}

unsigned char key()
{
    PORTB=0X00;
    while(C1&&C2&&C3);
    while(!C1||!C2||!C3) {
        R1=0;
        R2=R3=R4=1;
        if(!C1||!C2||!C3) {
            rowloc=0;
            break;
        }
        R2=0;R1=1;
        if(!C1||!C2||!C3) {
            rowloc=1;
            break;
        }
        R3=0;R2=1;
        if(!C1||!C2||!C3) {
            rowloc=2;
            break;
        }
        R4=0; R3=1;
        if(!C1||!C2||!C3){
            rowloc=3;
            break;
        }
    }
    if(C1==0&&C2!=0&&C3!=0)
            colloc=0;
    else if(C1!=0&&C2==0&&C3!=0)
            colloc=1;
    else if(C1!=0&&C2!=0&&C3==0)
            colloc=2;
    else if(C1!=0&&C2!=0&&C3!=0)
            colloc=3;
    while(C1==0||C2==0||C3==0);
    return (keypad[rowloc][colloc]);
}

void display(unsigned char num, char port) {
    volatile unsigned char *PORT;
    
    // Define the correct port based on the input parameter
    if (port == 'B') {
        PORT = &PORTB;
    } else if (port == 'C') {
        PORT = &PORTC;
    } else if (port == 'D') {
        PORT = &PORTD;
    } else {
        return; // Invalid port, exit the function
    }

    switch(num) {
        case 0:
            *PORT = 0x3F;  // 0b00111111;     // 0
            break;
        case 1:
            *PORT = 0x06;  // 0b00000110;     // 1
            break;
        case 2:
            *PORT = 0x5B;  // 0b01011011;     // 2
            break;
        case 3:
            *PORT = 0x4F;  // 0b01001111;     // 3
            break;
        case 4:
            *PORT = 0x66;  // 0b01100110;     // 4
            break;
        case 5:
            *PORT = 0x6D;  // 0b01101101;     // 5
            break;
        case 6:
            *PORT = 0x7D;  // 0b01111101;     // 6
            break;
        case 7:
            *PORT = 0x07;  // 0b00000111;     // 7
            break;
        case 8:
            *PORT = 0x7F;  // 0b01111111;     // 8
            break;
        case 9:
            *PORT = 0x6F;  // 0b01101111;     // 9
            break;
        case 10: // Case for displaying '-'
            *PORT = 0x40;  // 0b01000000;     // -
            break;
        case 11: // Case for displaying '_'
            *PORT = 0x08;  // 0b00001000;     // _
            break;
        case 12: // All segments off
            *PORT = 0x00;  // 0b00000000;     // All segments off
            break;
    }
}

void timer0_init(void) {
    OPTION_REG = 0x07;  // Prescaler 1:256
    TMR0 = 61;          // Carregar Timer0 para gerar 500ms
    T0IE = 1;           // Habilitar interrupï¿½ï¿½o do Timer0
    T0IF = 0;           // Limpar flag de interrupï¿½ï¿½o
    GIE = 1;            // Habilitar interrupï¿½ï¿½es globais
    PEIE = 1;           // Habilitar interrupï¿½ï¿½es perifï¿½ricas
}