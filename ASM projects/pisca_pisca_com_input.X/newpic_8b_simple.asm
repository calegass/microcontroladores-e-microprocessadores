; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

 
#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0
 
CBLOCK 0X20
    TEMPO1
    TEMPO2
    FLAG_PISCA
ENDC

; saídas
#define LAMPADA	    PORTA,0
#define	BOTAO_2HZ   PORTA,1
#define	BOTAO_5HZ   PORTA,2
#define	BOTAO_OFF   PORTA,3

; constantes
#define V_TEMPO	   250
    
FREQ_2HZ    equ	.250
FREQ_5HZ    equ	.100

    
RES_VECT  CODE    0x0000            ; processor reset vector
    
    BANK1
    BCF	    TRISA,0
    BSF	    TRISA,1
    BSF	    TRISA,2
    BSF	    TRISA,3
    BANK0
    
    BCF     LAMPADA
    CLRF    FLAG_PISCA

LACO_PRINCIPAL
    
    BCF	    LAMPADA
    
    BTFSS   BOTAO_2HZ
    GOTO    PISCAR_2HZ
    
    BTFSS   BOTAO_5HZ
    GOTO    PISCAR_5HZ
    
    GOTO    LACO_PRINCIPAL

PISCAR_2HZ
    
    BSF	    LAMPADA
    CALL    ESPERAR_250MS	    ; 250000 us

    BCF	    LAMPADA
    CALL    ESPERAR_250MS	    ; 250000 us
    
    GOTO    PISCAR_2HZ

PISCAR_5HZ
    
    BSF	    LAMPADA
    CALL    ESPERAR_100MS	    ; 100000 us
    
    BCF	    LAMPADA
    CALL    ESPERAR_100MS	    ; 100000 us
    
    GOTO    PISCAR_5HZ

ESPERAR_250MS
    
    MOVLW   FREQ_2HZ		    ; 1us
    MOVWF   TEMPO1		    ; 1us
    GOTO    INICIALIZA_TEMPO2	    ; 1us
    
ESPERAR_100MS
    
    MOVLW   FREQ_5HZ		    ; 1us
    MOVWF   TEMPO1		    ; 1us
    GOTO    INICIALIZA_TEMPO2	    ; 1us
    
    
INICIALIZA_TEMPO2
    
    MOVLW   V_TEMPO		    ; 1us
    MOVWF   TEMPO2		    ; 1us
    
    GOTO    DEC_TEMPO2
    
DEC_TEMPO2
    
    BTFSS   BOTAO_OFF
    GOTO    LACO_PRINCIPAL	    ; 1us
    
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    
    DECFSZ  TEMPO2,F		    ; 2us
    GOTO    DEC_TEMPO2		    ; 2us
    
DEC_TEMPO1
    
    DECFSZ  TEMPO1,F		    ; 2us
    GOTO    INICIALIZA_TEMPO2	    ; 2us
    
    RETURN			    ; 2us
    
    END
