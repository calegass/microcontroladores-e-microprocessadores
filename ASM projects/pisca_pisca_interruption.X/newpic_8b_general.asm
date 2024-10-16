; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

    
; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0
    
    CBLOCK 0X20
	UNIDADE
	DEZENA
	FILTRO
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
;variáveis
#define	    CONTEI	    FLAGS,0
#define	    TROCA_DISPLAY   FLAGS,1

    
;entradas
#define	    B_UP	    PORTA,1
#define	    B_RESET	    PORTA,2
    
;saídas
#define	    DISPLAY	    PORTB
#define	    QUAL_DISPLAY    PORTB,4
    
;constantes
V_TMR0	    equ		    .131
V_FILTRO    equ		    .100
    
RES_VECT    CODE    0x0000			; processor reset vector

    GOTO    START				;pula a área de armazenamento de iterrupção
INT_VEC	    CODE    0X0004			;vetor de iterrupção
    
    MOVWF   W_TEMP				;salvar w em W_TEMP
    MOVF    STATUS,W				;w = STATUS
    MOVWF   S_TEMP				;salvar SATATUS em S_TEMP
    BTFSS   INTCON,T0IF				;testa se a iterrupção foi por TIMER0
    GOTO    SAI_ITERRUPCAO			;se não foi, pula para SAI_ITERRUPCAO
    BCF	    INTCON,T0IF				;limpa o bit de indicação de iterrupção por TIMER0
    MOVLW   V_TMR0				;W = V_TMR0 -> W = 131
    ADDWF   TMR0,F				;TMR0 = TMR0 + V_TMR0 -> TMR0 = TMR0 + 131
    BSF	    TROCA_DISPLAY			;TROCA_DISPLAY = 1
    
SAI_ITERRUPCAO
    
    MOVF    S_TEMP,W				;W = S_TEMP
    MOVWF   STATUS				;restaura STATUS
    MOVF    W_TEMP,W				;restaura W
    RETFIE
    
START
    
    BANK1
    CLRF    TRISB				;configura todo o PORTB como saída
    MOVLW   B'11010001'				;palavra de configuração do TIMER0
						;bit7: ativa resistores PULL_UP do PORTB
						;bit6: define o tipo de borda para RB0
						;bit5: define origem do clock do TIMER0
						;bit4: define borda do clock do TIMER0
						;bit3: quem usa o PRESCALER - TMR0 ou WDT
						;bit2..0: define PRESCALER - 100 - 1:32
    MOVWF   OPTION_REG				;carrega a configuração do TIMER0
    BANK0
    CLRF    UNIDADE				;UNIDADE = 0
    CLRF    DEZENA				;DEZENA = 0
    MOVLW   V_FILTRO				;W = V_FILTRO
    MOVWF   FILTRO				;FILTRO = V_FILTRO
    CLRF    FLAGS				;FLAGS = 0
    BSF	    INTCON,T0IE				;habilita o atendimento de iterrupção por TIMER0
    BSF	    INTCON,GIE				;habilita o atenddimento de iterrupções
 
LACO_PRINCIPAL
    
    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    BTFSS   B_RESET				;testa se B_RESET está pressionado
    GOTO    B_RESET_ACIONADO			;se pressionado, pula para B_RESET_ACIONADO
    BTFSC   B_UP				;testa se B_UP está acionado
    GOTO    B_UP_NAO_ACIONADO			;se não acionado, pula para B_UP_NAO_ACIONADO
    BTFSC   CONTEI				;testa se CONTEI = 0
    GOTO    LACO_PRINCIPAL			;se CONTEI = 1, pula para LACO_PRINCIPAL
    DECFSZ  FILTRO,F				;decrementa o FILTRO e teste se zerou
    GOTO    LACO_PRINCIPAL			;se não zerou, pula para LACO_PRINCIPAL
    BSF	    CONTEI				;CONTEI = 1
    INCF    UNIDADE,F				;UNIDADE++
    MOVLW   .10					;W = 10
    SUBWF   UNIDADE,W				;W = UNIDADE - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (UNIDADE < 10)
    GOTO    LACO_PRINCIPAL			;se negativo, pula para LACO_PRINCIPAL
    CLRF    UNIDADE				;UNIDADE = 0
    INCF    DEZENA,F				;DEZENA++
    MOVLW   .10					;W = 10
    SUBWF   DEZENA,W				;W = DEZENA - W
    BTFSC   STATUS,C				;testa se o resultado é negativo (DEZENA < 10)
    CLRF    DEZENA				;se positivo DEZENA = 0
    GOTO    LACO_PRINCIPAL			;pula para LACO_PRINCIPAL

B_RESET_ACIONADO
    
    CLRF    UNIDADE				;UNIDADE = 0
    CLRF    DEZENA				;DEZENA = 0
    GOTO    LACO_PRINCIPAL			;pula para LACO_PRINCIPAL
    
B_UP_NAO_ACIONADO
    
    MOVLW   V_FILTRO
    MOVWF   FILTRO
    BCF	    CONTEI				;CONTEI
    GOTO    LACO_PRINCIPAL			;pula para o LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    
    BCF	    TROCA_DISPLAY			;TROCA_DISPLAY = 0
    BTFSS   QUAL_DISPLAY			;testa se a UNIDADE está acesa
    GOTO    ACENDE_UNIDADE			;se QUAL_DISPLAY = 0, pula para ACENEDE_UNIADE
    MOVF    DEZENA,W				;W = DEZENA
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    ANDLW   B'11101111'				;W = W & B'11101111'
    
ESCREVA_DISPLAY
    
    MOVWF   DISPLAY				;DISPLAY = W -> PORTB = W
    RETURN					;volta para o programa principal
    
ACENDE_UNIDADE
    
    MOVF    UNIDADE,W				;W = UNIDADE
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    GOTO    ESCREVA_DISPLAY			

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
    
    END