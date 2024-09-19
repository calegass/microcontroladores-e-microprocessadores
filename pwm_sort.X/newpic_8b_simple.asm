; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR


; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0 BCF STATUS, RP0
#define BANK1 BSF STATUS, RP0
    
    CBLOCK 0x20
	FILTRO_UP
	FILTRO_DOWN
	UNIDADE
	FLAGS
	W_TEMP
	S_TEMP
	RAMPA
    ENDC
    
    ;variaveis
    #define JA_LI_UP   FLAGS,0
    #define JA_LI_DOWN   FLAGS,1
    
    ;entradas
    #define	B_ZERAR PORTA,3
    #define	B_DOWN	PORTA,2
    #define	B_UP    PORTA,1
    
    ;saidas
    #define	DISPLAY PORTB
    #define	PWM	PORTA,0
    
    ;constantes
    V_FILTRO	EQU	.100
 
RES_VECT    CODE    0x0000		; processor reset vector
    GOTO CONFIGURE			;PULA PARA CONFIGURE
  
INT_VECT    CODE    0X0004		;VETOR DE INTERRUPÇAO
    MOVWF   W_TEMP		    ;
    MOVF    STATUS,W		    ;
    MOVWF   S_TEMP		    ;
    BTFSS   INTCON,T0IF		    ;
    GOTO    SAI_INTERRUPCAO	    ;
    BCF	    INTCON,T0IF		    ;
    MOVLW   .6
    ADDWF   TMR0,F		    ;
    INCF    RAMPA,F
    MOVLW   .16
    SUBWF   RAMPA,W
    BTFSC   STATUS,C
    CLRF    RAMPA
    MOVF    UNIDADE,W
    SUBWF   RAMPA,W
    BTFSS   STATUS,C
    GOTO    EH_MENOR
    BCF	    PWM
    GOTO    SAI_INTERRUPCAO
EH_MENOR
    BSF	PWM
SAI_INTERRUPCAO
    MOVF    S_TEMP,W		    ;
    MOVWF   STATUS		    ;
    MOVF    W_TEMP,W		    ;
    RETFIE
CONFIGURE
    BANK1			    ;seleciona banco 1 da memoria RAM
    CLRF    TRISB		    ;configura o PRTB como saída
    BCF	    TRISA,0
    MOVLW   B'11010001'				;palavra de configuração do TIMER0
						;bit7: ativa resistores PULL_UP do PORTB
						;bit6: define o tipo de borda para RB0
						;bit5: define origem do clock do TIMER0
						;bit4: define borda do clock do TIMER0
						;bit3: quem usa o PRESCALER - TMR0 ou WDT
						;bit2..0: define PRESCALER - 100 - 1:32
    MOVWF   OPTION_REG				;carrega a configuração do TIMER0
    BANK0			    ;seleciona banco 0 da memoria RAM
    MOVLW   V_FILTRO		    ;W = FILTRO_UP (W=100)
    MOVWF   FILTRO_UP		    ;FILTRO_UP = V_FILTRO (FILTRO_UP = 100)
    MOVWF   FILTRO_DOWN		    ;FILTRO_DOWN = V_FILTRO (FILTRO_UP = 100)
    BCF	    JA_LI_UP		    ;JA_LI_UP = 0
    BCF	    JA_LI_DOWN		    ;JA_LI_DONW = 0
    CLRF    UNIDADE		    ;UNIDADE = 0
    CLRF    RAMPA
    BSF	    INTCON,T0IE
    BSF	    INTCON,GIE
    CALL    ATUALIZA_DISPLAY	    ;chama a subrotina ATUALIZA_DISPLAY
LACO_PRINCIPAL
    BTFSS   B_ZERAR		    ;testa B_ZERAR
    GOTO    B_ZERAR_ACIONADO	    ;se acionado, pule para B_ZERAR_ACIONADO
    BTFSC   B_UP		    ;testa B_UP
    GOTO    B_UP_NAO_ACIONADO	    ;se acionado, pule para B_UP_NAO_ACIONADO
    BTFSC   JA_LI_UP		    ;testa JA_LI_UP
    GOTO    LACO_PRINCIPAL	    ;se JA_LI_UP = 1, pule para o LACO_PRINCIPAL
    DECFSZ  FILTRO_UP,F		    ;decrementa FILTRO_UP e verifica se zerou
    GOTO    LACO_PRINCIPAL	    ;se nao zerou, pule para o LACO_PRINCIPAL
    BSF	    JA_LI_UP		    ;JA_LI_UP = 1
    INCF    UNIDADE,F		    ;UNIDADE++
    MOVLW   .16			    ;W = 16
    SUBWF   UNIDADE,W		    ;W = UNIDADE - W
    BTFSC   STATUS,C		    ;teste se o resultado foi negativo
    CLRF    UNIDADE		    ;zera a unidade
    CALL    ATUALIZA_DISPLAY	    ;chama a subrotina ATUALIZA_DISPLAY
    
    GOTO    LACO_PRINCIPAL	    ;pule para o LACO_PRINCIPAL
B_ZERAR_ACIONADO
    CLRF    UNIDADE		    ;zera a unidade
    CALL    ATUALIZA_DISPLAY	    ;chama a subrotina ATUALIZA_DISPLAY
    GOTO    LACO_PRINCIPAL	    ;pule para o LACO_PRINCIPAL
B_UP_NAO_ACIONADO
    MOVLW   V_FILTRO		    ;W = V_FILTRO (W=100)
    MOVWF   FILTRO_UP		    ;FILTRO_UP = V_FILTRO	(FILTRO_UP = 100)
    BCF	    JA_LI_UP		    ;JA_LI_UP = 0
    BTFSC   B_DOWN		    ;VERIFICAR O B_DOWN
    GOTO    B_DOWN_N_ACIONADO
    BTFSC   JA_LI_DOWN		    ;testa JA_LI_UP
    GOTO    LACO_PRINCIPAL	    ;se JA_LI_UP = 1, pule para o LACO_PRINCIPAL
    DECFSZ  FILTRO_DOWN,F	    ;decrementa FILTRO_UP e verifica se zerou
    GOTO    LACO_PRINCIPAL	    ;se nao zerou, pule para o LACO_PRINCIPAL
    BSF	    JA_LI_DOWN		    ;JA_LI_UP = 1
    DECF    UNIDADE,F		    ;UNIDADE--
    MOVLW   .16			    ;W = 16
    SUBWF   UNIDADE,W		    ;W = UNIDADE - W
    BTFSC   STATUS,C		    ;teste se o resultado foi negativo
    CALL    EH_NEGATIVO		    ;SE UNIDADE < 16
    CALL    ATUALIZA_DISPLAY	    ;chama a subrotina ATUALIZA_DISPLAY
    GOTO    LACO_PRINCIPAL	    ;pule para o LACO_PRINCIPAL
    
EH_NEGATIVO
    MOVLW   .15			    ;W = 15
    MOVWF   UNIDADE		    ;UNIDADE = 15
    RETURN
    
B_DOWN_N_ACIONADO
    
    MOVLW   V_FILTRO
    MOVWF   FILTRO_DOWN
    BCF	    JA_LI_DOWN
    GOTO    LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    MOVF    UNIDADE,W		    ;W = UNIDADE
    CALL    BUSCA_CODIGO	    ;chama a subrotina BUSCA_CODIGO
    MOVWF   DISPLAY		    ;DISPLAY = W (PORTB = W)
    
    RETURN			    ;retorna uma subrotina
BUSCA_CODIGO
    ADDWF   PCL,F		    ;PCL = PCL + W
    RETLW   0XFE		    ;retorna a subrotina com w = 0xFE
    RETLW   0X38		    ;retorna a subrotina com w = 0x38
    RETLW   0XDD		    ;retorna a subrotina com w = 0xDD
    RETLW   0X7D		    ;retorna a subrotina com w = 0x7D
    RETLW   0X3B		    ;retorna a subrotina com w = 0x3B
    RETLW   0X77		    ;retorna a subrotina com w = 0x77
    RETLW   0XF7		    ;retorna a subrotina com w = 0xF7
    RETLW   0X3C		    ;retorna a subrotina com w = 0x3C
    RETLW   0XFF		    ;retorna a subrotina com w = 0xFF
    RETLW   0X7F		    ;retorna a subrotina com w = 0X7F
    RETLW   0xBF		    ;retorna a subrotina com w = 0xBF
    RETLW   0XF3		    ;retorna a subrotina com w = 0x73
    RETLW   0xD6		    ;retorna a subrotina com w = 0xD6
    RETLW   0XF9		    ;retorna a subrotina com w = 0xFA
    RETLW   0XD7		    ;retorna a subrotina com w = 0XD7
    RETLW   0X97		    ;retorna a subrotina com w = 0X97
    
    END
