; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

    CBLOCK	0X20
	FLAGS
	FILTRO
    ENDC

;variáveis   
#define	B_ACIONADO  FLAGS,0

;entradas
#define	BOTAO	    PORTA,1
    
;sáidas
#define	LAMPADA	    PORTA,0    
    
RES_VECT  CODE    0x0000    ;processor reset vector
    BSF	    STATUS,RP0	    ;seleciona o banco 1 da memória RAM
    BCF	    TRISA,0	    ;zera o bit0 do TRISA, configura o bit0 do PORTA como saída
    BCF	    STATUS,RP0	    ;seleciona o banco 0 da memória RAM
    BCF	    LAMPADA	    ;apaga a lâmpada
    MOVLW   .100	    ;W = 100
    MOVWF   FILTRO	    ;FILTRO = 100
    BCF	    B_ACIONADO	    ;B_ACIONADO = 0
LOOP
    BTFSC   BOTAO	    ;testa se o BOTAO = 0 (acionado)
    GOTO    NAO_ACIONADO    ;se BOTAO = 1, pula para NAO_ACIONADO
    BTFSC   B_ACIONADO	    ;testa se o B_ACIONADO = 0
    GOTO    LOOP	    ;se B_ACIONADO = 1, pula para LOOP
    DECFSZ  FILTRO,F	    ;FILTRO--, testa se zerou
    GOTO    LOOP	    ;se FILTRO != 0, pula para LOOP
    BSF	    B_ACIONADO	    ;B_ACIONADO = 1
    BTFSS   LAMPADA	    ;testa se LAMPADA = 1
    GOTO    ACENDE_LAMPADA  ;se LAMPADA = 0, pula para ACENDE_LAMPADA
    BCF	    LAMPADA	    ;LAMPADA = 0
    GOTO    LOOP	    ;pula para LOOP
ACENDE_LAMPADA    
    BSF	    LAMPADA	    ;LAMPADA = 1 
    GOTO    LOOP	    ;pula para LOOP
NAO_ACIONADO
    BCF	    B_ACIONADO	    ;B_ACIONADO = 0
    MOVLW   .100	    ;W = 100
    MOVWF   FILTRO	    ;FILTRO = 100
    GOTO    LOOP	    ;pula para LOOP    

    END