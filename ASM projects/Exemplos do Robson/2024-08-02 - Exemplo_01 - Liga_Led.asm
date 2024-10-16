; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

    
RES_VECT  CODE    0x0000            ; processor reset vector
    BSF	    STATUS,RP0
    BCF	    TRISA,0
    BCF	    STATUS,RP0
    BCF	    PORTA,0
LOOP
    BTFSC   PORTA,1
    GOTO    LE_BOTAO_2
    BSF	    PORTA,0
    GOTO    LOOP
LE_BOTAO_2
    BTFSS   PORTA,2
    BCF	    PORTA,0
    GOTO    LOOP    
    END