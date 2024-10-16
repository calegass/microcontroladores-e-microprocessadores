; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0x3F70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


; MATHEUS CALEGARI MOIZINHO - 08/2024 
 
; saídas
#define LED0 PORTB,0
#define LED1 PORTB,1
#define LED2 PORTB,2
#define LED3 PORTB,3

; entradas
#define BOTAO_RA1 PORTA,1
#define BOTAO_RA2 PORTA,2
#define BOTAO_RA3 PORTA,3
#define BOTAO_RA4 PORTA,4


RES_VECT CODE 0x0000	    ; processor reset vector
    BCF	    STATUS,RP0	    ; selecionar banco 0 da RAM

    GOTO START		    ; Ir para o início do programa

; definir configurações padrão fora de res_vect para reaproveitar
START
    CLRF    PORTB	    ; LEDs apagados
    GOTO    LIGAR_RB0


LIGAR_RB0		    ; ligar RB0 caso RA1 seja pressionado
    BTFSC   BOTAO_RA1	    ; verifica se RA1 foi pressionado, caso não tenha sido:
    GOTO    LIGAR_RB0	    ; volta a verificar se foi pressionado

    BSF	    LED0	    ; caso tenha sido, acende LED0

    GOTO    LIGAR_RB1	    ; repete o mesmo processo para LED1

LIGAR_RB1
    BTFSC   BOTAO_RA2
    GOTO    LIGAR_RB1

    BSF	    LED1

    GOTO    LIGAR_RB2

LIGAR_RB2
    BTFSC   BOTAO_RA3
    GOTO    LIGAR_RB2

    BSF	    LED2

    GOTO    LIGAR_RB3

LIGAR_RB3
    BTFSC   BOTAO_RA4
    GOTO    LIGAR_RB3

    BSF	    LED3

    GOTO    DESLIGAR_RB0    ; como todos os LEDs estão acesos:


DESLIGAR_RB0
    BTFSC   BOTAO_RA1	    ; caso RA1 não seja pressionado,
    GOTO    DESLIGAR_RB0    ; ele volta a esperar RA1 ser pressionado

    BCF	    LED0	    ; RA1 foi pressionado, desligar LED0

    GOTO    DESLIGAR_RB1    ; repetir para todos os LEDs

DESLIGAR_RB1
    BTFSC   BOTAO_RA2
    GOTO    DESLIGAR_RB1

    BCF	    LED1

    GOTO    DESLIGAR_RB2

DESLIGAR_RB2
    BTFSC   BOTAO_RA3
    GOTO    DESLIGAR_RB2

    BCF	    LED2

    GOTO    DESLIGAR_RB3

DESLIGAR_RB3
    BTFSC   BOTAO_RA4
    GOTO    DESLIGAR_RB3

    BCF	    LED3

    GOTO    START	    ; como todos os LEDs estão apagados, voltar ao início


END