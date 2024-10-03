; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0
 
 CBLOCK	0X20
    FILTRO_UP
    FILTRO_DOWN
    UNIDADE
    FLAGS
    W_TEMP
    S_TEMP
    RAMPA
 ENDC
 
;variáveis
#define	JA_LI_UP    FLAGS,0
#define	JA_LI_DOWN  FLAGS,1
 
;entradas
#define	B_UP	    PORTA,1
#define	B_DOWN	    PORTA,2 
#define	B_ZERAR	    PORTA,3
 
;saídas
#define	DISPLAY	    PORTB
#define	PWM 	    PORTA,0 
 
;constantes
V_FILTRO    equ	.100
 
RES_VECT  CODE    0x0000	;processor reset vector
    GOTO    CONFIGURE		;pula para CONFIGURE
INT_VECT  CODE    0x0004	;processor interrupt vector  
    MOVWF   W_TEMP		    ;salvo W
    MOVF    STATUS,W		    ;
    MOVWF   S_TEMP		    ;salvo STATUS
    BTFSS   INTCON,T0IF		    ;testa se a interrupção é por TIMER0
    GOTO    SAI_INTERRUPCAO	    ;se não for, pula pra SAI_INTERRUPCAO
    BCF	    INTCON,T0IF		    ;se for, zera o bit indicador de interrupção por TIMER0
    MOVLW   .6			    ;somar 6 ao TMR0 
    ADDWF   TMR0,F		    ;para contar só 250 pulsos
    INCF    RAMPA,F		    ;incrementa o gerador de rampa
    MOVLW   .16			    ;W = 16
    SUBWF   RAMPA,W		    ;W = RAMPA - 16
    BTFSC   STATUS,C		    ;testa se RAMPA < 16
    CLRF    RAMPA		    ;se RAMPA >= 16, RAMPA = 0
    MOVF    UNIDADE,W		    ;W = UNIDADE
    SUBWF   RAMPA,W		    ;W = RAMPA - UNIDADE
    BTFSS   STATUS,C	    	    ;testa se RAMPA < UNIDADE
    GOTO    EH_MENOR		    ;se for menor, pula para EH_MENOR
    BCF	    PWM			    ;PWM = 0
    GOTO    SAI_INTERRUPCAO	    ;pula pra SAI_INTERRUPCAO
EH_MENOR
    BSF	    PWM			    ;PWM = 1
SAI_INTERRUPCAO
    MOVF    S_TEMP,W		    ;
    MOVWF   STATUS		    ;
    MOVF    W_TEMP,W		    ;
    RETFIE
    
CONFIGURE  
    BANK1			;seleciona banco 1 da memória RAM
    CLRF    TRISB		;configura o PORTB como saída
    BCF	    TRISA,0		;configura o bit 0 do PORTA como saída
    MOVLW   B'11010001'		;palavra de configuração do TIMER0
				;bit7: ativa resistores PULL_UP do PORTB
				;bit6: define o tipo de borda para RB0
				;bit5: define origem do clock do TIMER0				    
				;bit4: define borda do clock do TIMER0 qdo clock for externo
				;bit3: quem usa o PRESCALER - TMR0 ou WDT
				;bit2..0: define o PRESCALER - 001 - 1:4				  
    MOVWF   OPTION_REG		;
    BANK0			;seleciona banco 0 da memória RAM
    MOVLW   V_FILTRO		;W = V_FILTRO (W = 100)
    MOVWF   FILTRO_UP		;FILTRO_UP = V_FILTRO (FILTRO_UP = 100)
    MOVWF   FILTRO_DOWN		;FILTRO_DOWN = V_FILTRO (FILTRO_DOWN = 100)    
    BCF	    JA_LI_UP		;JA_LI_UP = 0
    BCF	    JA_LI_DOWN		;JA_LI_DOWN = 0    
    CLRF    UNIDADE		;UNIDADE = 0
    CLRF    RAMPA		;RAMPA = 0
    BSF	    INTCON,T0IE		;
    BSF	    INTCON,GIE		;
    CALL    ATUALIZA_DISPLAY	;chama a subrotina ATUALIZA_DISPLAY
LACO_PRINCIPAL
    BTFSS   B_ZERAR		;testa B_ZERAR
    GOTO    B_ZERAR_ACIONADO	;se acionado, pule para B_ZERAR_ACIONADO
    BTFSC   B_UP		;testa_UP
    GOTO    B_UP_N_ACIONADO	;se não acionado, pule para B_UP_N_ACIONADO
    BTFSC   JA_LI_UP		;testa JA_LI_UP
    GOTO    LACO_PRINCIPAL	;se JA_LI_UP = 1, pule para LACO_PRINCIPAL
    DECFSZ  FILTRO_UP,F		;decrementa FILTRO_UP e verifica se zerou
    GOTO    LACO_PRINCIPAL	;se não zerou, pule para LACO_PRINCIPAL
    BSF	    JA_LI_UP		;JA_LI_UP = 1
    INCF    UNIDADE,F		;UNIDADE++
    MOVLW   .16			;W = 16
    SUBWF   UNIDADE,W		;W = UNIDADE - W
    BTFSC   STATUS,C		;teste se o resultado foi negativo
    CLRF    UNIDADE		;UNIDADE = 0
    CALL    ATUALIZA_DISPLAY	;chama a subrotina ATUALIZA_DISPLAY
    GOTO    LACO_PRINCIPAL	;pule para LACO_PRINCIPAL
B_ZERAR_ACIONADO
    CLRF    UNIDADE		;UNIDADE = 0
    CALL    ATUALIZA_DISPLAY	;chama a subrotina ATUALIZA_DISPLAY
    GOTO    LACO_PRINCIPAL	;pule para LACO_PRINCIPAL
B_UP_N_ACIONADO    
    MOVLW   V_FILTRO		;W = V_FILTRO (W = 100)
    MOVWF   FILTRO_UP		;FILTRO_UP = V_FILTRO (FILTRO_UP = 100)
    BCF	    JA_LI_UP		;JA_LI_UP = 0 
    BTFSC   B_DOWN		;testa se B_DOWN está acionado
    GOTO    B_DOWN_N_ACIONADO	;pule para B_DOWN_N_ACIONADO

    BTFSC   JA_LI_DOWN		;testa JA_LI_DOWN
    GOTO    LACO_PRINCIPAL	;se JA_LI_UP = 1, pule para LACO_PRINCIPAL
    DECFSZ  FILTRO_DOWN,F	;decrementa FILTRO_DOWN e verifica se zerou
    GOTO    LACO_PRINCIPAL	;se não zerou, pule para LACO_PRINCIPAL
    BSF	    JA_LI_DOWN		;JA_LI_DOWN = 1
    DECF    UNIDADE,F		;UNIDADE--
    MOVLW   .16			;W = 16
    SUBWF   UNIDADE,W		;W = UNIDADE - W
    BTFSS   STATUS,C		;teste se o resultado foi negativo
    GOTO    EH_NEGATIVO		;se UNIDADE < 16
    MOVLW   .15			;W = 15
    MOVWF   UNIDADE		;UNIDADE = 15
EH_NEGATIVO        
    CALL    ATUALIZA_DISPLAY	;chama a subrotina ATUALIZA_DISPLAY
    GOTO    LACO_PRINCIPAL	;pule para LACO_PRINCIPAL    
B_DOWN_N_ACIONADO    
    MOVLW   V_FILTRO		;W = V_FILTRO (W = 100)
    MOVWF   FILTRO_DOWN		;FILTRO_DOWN = V_FILTRO (FILTRO_DOWN = 100)
    BCF	    JA_LI_DOWN		;JA_LI_DOWN = 0 
    GOTO    LACO_PRINCIPAL	;pule para LACO_PRINCIPAL 
    
ATUALIZA_DISPLAY
    MOVF    UNIDADE,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina BUSCA_CODIGO
    MOVWF   DISPLAY		;DISPLAY = W (PORTB = W)
    RETURN			;retorna de uma subrotina
BUSCA_CODIGO
    ADDWF   PCL,F		;PCL = PCL + W
    RETLW   0xFE		;retorna da subrotina com W = 0xFE - "0"
    RETLW   0x38		;retorna da subrotina com W = 0x38 - "1"    
    RETLW   0xDD		;retorna da subrotina com W = 0xDD - "2"    
    RETLW   0x7D		;retorna da subrotina com W = 0x7D - "3"
    RETLW   0x3B		;retorna da subrotina com W = 0x3B - "4"
    RETLW   0x77		;retorna da subrotina com W = 0x77 - "5"    
    RETLW   0xF7		;retorna da subrotina com W = 0xF7 - "6"    
    RETLW   0x3C		;retorna da subrotina com W = 0x3C - "7"    
    RETLW   0xFF		;retorna da subrotina com W = 0xFF - "8"
    RETLW   0x7F		;retorna da subrotina com W = 0x7F - "9"
    RETLW   0xBF		;retorna da subrotina com W = 0xBF - "A"    
    RETLW   0xF3		;retorna da subrotina com W = 0xF3 - "b"    
    RETLW   0xD6		;retorna da subrotina com W = 0xD6 - "C"    
    RETLW   0xF9		;retorna da subrotina com W = 0xF9 - "d"
    RETLW   0xD7		;retorna da subrotina com W = 0xD7 - "E"
    RETLW   0x97		;retorna da subrotina com W = 0x97 - "F"
    END