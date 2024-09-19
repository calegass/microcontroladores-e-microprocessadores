; MATHEUS CALEGARI MOIZINHO - 09/2024
    
; PIC16F877A Configuration Bit Settings

; Assembly source line config statements

#include "p16f877a.inc"

; CONFIG
; __config 0xFF71
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF
 

#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0 
 
    CBLOCK  0x20
	UNIDADE
	DEZENA
	CENTENA
	MILHAR
	FLAGS
	W_TEMP
	S_TEMP
	TMR_01S
    ENDC
    
;variaveis
#define	CONTEI		FLAGS,0
#define	TROCA_DISPLAY	FLAGS,1

;entradas
#define	B_UP		PORTB,0
#define B_STOP		PORTB,1
#define	B_RESET		PORTB,2

;saidas
#define	DISPLAY		PORTD
#define	D_UNIDADE	PORTB,4   
#define	D_DEZENA	PORTB,5  
#define	D_CENTENA	PORTB,6
#define	D_MILHAR	PORTB,7
    
;constantes
V_TMR0	    equ		.131
	
	    
RES_VECT  CODE    0x0000   
  
    GOTO    START           
    

INT_VECT  CODE    0x0004   
  
    MOVWF   W_TEMP	    
    MOVF    STATUS,W	    
    MOVWF   S_TEMP	    
    
    BTFSS   INTCON,T0IF	    
    GOTO    SAI_INTERRUPCAO 
    
    BCF	    INTCON,T0IF	    
    
    MOVLW   V_TMR0	    
    ADDWF   TMR0,F	    
    
    BSF	    TROCA_DISPLAY  
    INCF    TMR_01S
    
    
SAI_INTERRUPCAO
    
    MOVF    S_TEMP,W	    
    MOVWF   STATUS	    
    MOVF    W_TEMP,W	
    
    RETFIE
    

START
    
    BANK1
    CLRF    TRISD	
    MOVLW   B'00001111'
    MOVWF   TRISB
    MOVLW   B'11010100'	   			  
    MOVWF   OPTION_REG	    
    BANK0
    
    CLRF    UNIDADE	   
    CLRF    DEZENA
    CLRF    CENTENA
    CLRF    MILHAR
        
    CLRF    FLAGS	    
    BSF	    INTCON,T0IE	    
    BSF	    INTCON,GIE	 

    
LACO_PRINCIPAL
    
    BTFSC   TROCA_DISPLAY	
    CALL    ATUALIZA_DISPLAY	
    
    BTFSS   B_RESET		
    GOTO    B_RESET_ACIONADO	
    
    BTFSS   B_UP
    GOTO    B_INCREMENTAR
    
    GOTO    LACO_PRINCIPAL
    
    
B_INCREMENTAR
    
    BTFSS   B_STOP
    GOTO    LACO_PRINCIPAL
    
    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    
    MOVLW   .50		    			; Carrega o valor 50 no registrador W (250 é 1s em 4hz, portanto 50 é 0,1s em 8hz)
    SUBWF   TMR_01S,W				; Subtrai W de MINHA_VAR e armazena o resultado em W
    BTFSS   STATUS,Z				; Testa se o bit Z (zero) no STATUS está setado (resultado da subtração foi zero)
    GOTO    B_INCREMENTAR			; Se Z = 0, a variável não é igual a 50

    CLRF    TMR_01S

    INCF    UNIDADE,F				;UNIDADE++
    MOVLW   .10					;W = 10
    SUBWF   UNIDADE,W				;W = UNIDADE - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (UNIDADE < 10)
    GOTO    B_INCREMENTAR			;se negativo, pula para LACO_PRINCIPAL

    CLRF    UNIDADE				;UNIDADE = 0

    INCF    DEZENA,F				;DEZENA++
    MOVLW   .10					;W = 10
    SUBWF   DEZENA,W				;W = DEZENA - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (DEZENA < 10)
    GOTO    B_INCREMENTAR
    
    CLRF    DEZENA
    
    INCF    CENTENA,F				;CENTENA++
    MOVLW   .10					;W = 10
    SUBWF   CENTENA,W				;W = CENTENA - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (CENTENA < 10)
    GOTO    B_INCREMENTAR
    
    CLRF    CENTENA
    
    INCF    MILHAR,F				;MILHAR++
    MOVLW   .10					;W = 10
    SUBWF   MILHAR,W				;W = MILHAR - W
    BTFSC   STATUS,C				;testa se o resultado é negativo (MILHAR < 10)

    CLRF    MILHAR				;se positivo MILHAR = 0

    GOTO    B_INCREMENTAR			;pula para LACO_PRINCIPAL
    
    
B_RESET_ACIONADO
    
    CLRF    UNIDADE		
    CLRF    DEZENA		
    CLRF    CENTENA
    CLRF    MILHAR
    GOTO    LACO_PRINCIPAL	

    
ATUALIZA_DISPLAY
    
    BCF	    TROCA_DISPLAY			;TROCA_DISPLAY = 0
    
    BTFSS   D_CENTENA				;testa se a CENTENA está acesa
    GOTO    ACENDE_CENTENA			;se QUAL_DISPLAY = 0, pula para ACENDE_CENTENA
    
    BCF	    D_CENTENA
    MOVF    MILHAR,W				;W = CENTENA
    
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    
    MOVWF   DISPLAY				;DISPLAY = W -> PORTB = W
    BSF	    D_MILHAR
    
    RETURN					;volta para o programa principal
    
    
ACENDE_CENTENA
    
    BCF	    D_MILHAR
    BTFSS   D_DEZENA
    GOTO    ACENDE_DEZENA
    BCF	    D_DEZENA
    MOVF    CENTENA,W				;W = CENTENA
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY
    BSF	    D_CENTENA
    RETURN
    
    
ACENDE_DEZENA
    
    BCF	    D_CENTENA
    BTFSS   D_UNIDADE
    GOTO    ACENDE_UNIDADE
    BCF	    D_UNIDADE
    MOVF    DEZENA,W				;W = DEZENA
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY
    BSF	    D_DEZENA
    RETURN
    
    
ACENDE_UNIDADE
    
    BCF	    D_DEZENA
    MOVF    UNIDADE,W				;W = UNIDADE
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY
    BSF	    D_UNIDADE
    RETURN
    
    
BUSCA_CODIGO
    
    ADDWF   PCL,F		;PCL = PCL + W
    RETLW   0x3F		;retorna da subrotina com W = 0xFE
    RETLW   0x06		;retorna da subrotina com W = 0x38    
    RETLW   0x5B		;retorna da subrotina com W = 0xDD    
    RETLW   0x4F		;retorna da subrotina com W = 0x7D
    RETLW   0x66		;retorna da subrotina com W = 0x3B
    RETLW   0x6D		;retorna da subrotina com W = 0x77    
    RETLW   0x7D		;retorna da subrotina com W = 0xF7    
    RETLW   0x07		;retorna da subrotina com W = 0x3C    
    RETLW   0x7F		;retorna da subrotina com W = 0xFF
    RETLW   0x6F		;retorna da subrotina com W = 0x7F    
    
    
    END
    