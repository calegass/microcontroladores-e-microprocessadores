; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0	 BCF STATUS,RP0
#define BANK1	 BSF STATUS,RP0 

    CBLOCK  0X20
	W_TEMP
	S_TEMP
	FLAGS
	CONTADOR
    ENDC

#define	    LAMPADA	PORTA,0
#define	    FIM_TEMPO	FLAGS,0    
    
V_TMR0	    equ	    .6
V_CONTADOR  equ	    .125    
    
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    INICIO
INT_VECT  CODE    0x0004            ; processor interrupt vector
    MOVWF   W_TEMP		    ;
    MOVF    STATUS,W		    ;
    MOVWF   S_TEMP		    ;
    BTFSS   INTCON,T0IF		    ;
    GOTO    SAI_INTERRUPCAO	    ;
    BCF	    INTCON,T0IF		    ;
    MOVLW   V_TMR0		    ;
    ADDWF   TMR0,F		    ;
    DECFSZ  CONTADOR,F		    ;
    GOTO    SAI_INTERRUPCAO	    ;
    BSF	    FIM_TEMPO		    ;
    MOVLW   V_CONTADOR		    ;
    MOVWF   CONTADOR		    ;
SAI_INTERRUPCAO
    MOVF    S_TEMP,W		    ;
    MOVWF   STATUS		    ;
    MOVF    W_TEMP,W		    ;
    RETFIE  
INICIO  
    BANK1   
    BCF	    TRISA,0		    ;
    MOVLW   B'11010011'		    ;palavra de configuração do TIMER0
				    ;bit7: ativa resistores PULL_UP do PORTB
				    ;bit6: define o tipo de borda para RB0
				    ;bit5: define origem do clock do TIMER0				    
				    ;bit4: define borda do clock do TIMER0 qdo clock for externo
				    ;bit3: quem usa o PRESCALER - TMR0 ou WDT
				    ;bit2..0: define o PRESCALER - 011 - 1:16				  
    MOVWF   OPTION_REG		    ;
    BANK0
    BCF	    LAMPADA		    ;
    MOVLW   V_CONTADOR		    ;
    MOVWF   CONTADOR		    ;
    BCF	    FIM_TEMPO		    ;
    MOVLW   V_TMR0		    ;
    MOVWF   TMR0		    ;
    BSF	    INTCON,T0IE		    ;
    BSF	    INTCON,GIE		    ;   
    
LACO_PRINCIPAL
    BTFSS   FIM_TEMPO		    ;
    GOTO    LACO_PRINCIPAL	    ;
    BCF	    FIM_TEMPO		    ;
    BTFSS   LAMPADA		    ;
    GOTO    ACENDE_LAMPADA	    ;
    BCF	    LAMPADA  
    GOTO    LACO_PRINCIPAL
ACENDE_LAMPADA   
    BSF	    LAMPADA
    GOTO    LACO_PRINCIPAL 

    END