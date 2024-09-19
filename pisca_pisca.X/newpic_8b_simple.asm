; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0
 
;CBLOCK 0X20
;    TEMPO1
;    TEMPO2
;ENDC

; saídas
#define	    LAMPADA	PORTA,0

;; constantes
;V_TEMPO1    equ		.125
;V_TEMPO2    equ		.250

    
RES_VECT  CODE    0x0000            ; processor reset vector
    BANK1
    BCF	    TRISA,0
    BANK0
    
    
LACO_PRINCIPAL
    
    BSF	    LAMPADA
;    CALL    ESPERAR_500MS
;    
;    BCF	    LAMPADA
;    CALL    ESPERAR_500MS
    
    GOTO    LACO_PRINCIPAL
;    
;
;ESPERAR_500MS
;    
;    MOVLW   V_TEMPO1		    ; 1us
;    MOVWF   TEMPO1		    ; 1us
;    
;
;INICIALIZA_TEMPO2
;    
;    MOVLW   V_TEMPO2		    ; 1us
;    MOVWF   TEMPO2		    ; 1us
;    
;    
;DEC_TEMPO2
;    
;    NOP
;    NOP
;    NOP
;    NOP
;    NOP
;    
;    DECFSZ  TEMPO2,F		    ; 1us/2us
;    GOTO    DEC_TEMPO2		    ; 2us
;    
;   
;DEC_TEMPO1
;    
;    DECFSZ  TEMPO1,F		    ; 1us/2us
;    GOTO    INICIALIZA_TEMPO2	    ; 2us
;    
;    RETURN			    ; 2us
    
    
    END
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    