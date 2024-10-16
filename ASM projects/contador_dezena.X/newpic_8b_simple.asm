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
	FLAGS
	W_TEMP
	S_TEMP
	TMR_1S
    ENDC

;variáveis
#define	    TROCA_DISPLAY   FLAGS,1


;entradas
#define	    B_INC	    PORTA,1
#define	    B_DEC	    PORTA,2
#define	    B_STOP	    PORTA,3
#define	    B_RESET	    PORTA,4

;saídas
#define	    DISPLAY	    PORTB
#define	    QUAL_DISPLAY    PORTB,4

;constantes
V_TMR0	    equ		    .131


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

    INCF    TMR_1S

    BSF	    TROCA_DISPLAY			;TROCA_DISPLAY = 1


SAI_ITERRUPCAO

    MOVF    S_TEMP,W				;W = S_TEMP
    MOVWF   STATUS				;restaura STATUS
    MOVF    W_TEMP,W				;restaura W
    RETFIE


START

    BANK1
    CLRF    TRISB				;configura todo o PORTB como saída
    MOVLW   B'11010100'				;palavra de configuração do TIMER0
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

    CLRF    FLAGS				;FLAGS = 0
    CLRF    TMR_1S
    BSF	    INTCON,T0IE				;habilita o atendimento de iterrupção por TIMER0
    BSF	    INTCON,GIE				;habilita o atenddimento de iterrupções

;    MOVLW   .3
;    MOVWF   DEZENA ; valendo 3 haha

LACO_PRINCIPAL

    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY

    BTFSS   B_RESET				;testa se B_RESET está pressionado
    GOTO    B_RESET_ACIONADO			;se pressionado, pula para B_RESET_ACIONADO

    BTFSS   B_INC
    GOTO    B_INCREMENTAR

    BTFSS   B_DEC
    GOTO    B_DECREMENTAR

    GOTO    LACO_PRINCIPAL


PADRAO

    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY

    BTFSS   B_STOP
    GOTO    LACO_PRINCIPAL

    RETURN


B_INCREMENTAR

    CALL    PADRAO

    MOVLW   .250				; Carrega o valor 250 no registrador W
    SUBWF   TMR_1S,W				; Subtrai W de MINHA_VAR e armazena o resultado em W
    BTFSS   STATUS,Z				; Testa se o bit Z (zero) no STATUS está setado (resultado da subtração foi zero)
    GOTO    B_INCREMENTAR			; Se Z = 0, a variável não é igual a 250

    CLRF    TMR_1S


    INCF    UNIDADE,F				;UNIDADE++
    MOVLW   .10					;W = 10
    SUBWF   UNIDADE,W				;W = UNIDADE - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (UNIDADE < 10)
    GOTO    B_INCREMENTAR			;se negativo, pula para LACO_PRINCIPAL

    CLRF    UNIDADE				;UNIDADE = 0

    INCF    DEZENA,F				;DEZENA++
    MOVLW   .10					;W = 10
    SUBWF   DEZENA,W				;W = DEZENA - W
    BTFSC   STATUS,C				;testa se o resultado é negativo (DEZENA < 10)

    CLRF    DEZENA				;se positivo DEZENA = 0

    GOTO    B_INCREMENTAR			;pula para LACO_PRINCIPAL


B_DECREMENTAR

    CALL    PADRAO

    MOVLW   .250
    SUBWF   TMR_1S,W
    BTFSS   STATUS,Z
    GOTO    B_DECREMENTAR

    CLRF    TMR_1S


    DECF    UNIDADE,F            ; Decrementa a UNIDADE
    MOVF    UNIDADE,W            ; Move o valor de UNIDADE para W
    XORLW   0xFF                ; Verifica se UNIDADE == FF (equivalente a -1)
    BTFSS   STATUS,Z             ; Se UNIDADE não for -1 (FF), continua o loop
    GOTO    B_DECREMENTAR

    MOVLW   .9                   ; Se UNIDADE foi para -1 (FF), reinicia com 9
    MOVWF   UNIDADE

    DECF    DEZENA,F             ; Decrementa a DEZENA
    MOVF    DEZENA,W             ; Move o valor de DEZENA para W
    XORLW   0xFF                ; Verifica se DEZENA == FF
    BTFSS   STATUS,Z             ; Se DEZENA não for -1, continua o loop
    GOTO    B_DECREMENTAR

    MOVLW   .9                   ; Se DEZENA foi para -1, reinicia com 9
    MOVWF   DEZENA

    GOTO    B_DECREMENTAR        ; Retorna para o loop principal de decremento


B_RESET_ACIONADO

    CLRF    UNIDADE				;UNIDADE = 0
    CLRF    DEZENA				;DEZENA = 0
    GOTO    LACO_PRINCIPAL			;pula para LACO_PRINCIPAL


ATUALIZA_DISPLAY

    BCF	    TROCA_DISPLAY			;TROCA_DISPLAY = 0
    BTFSS   QUAL_DISPLAY			;testa se a UNIDADE está acesa
    GOTO    ACENDE_UNIDADE			;se QUAL_DISPLAY = 0, pula para ACENEDE_UNIADE
    MOVF    DEZENA,W				;W = DEZENA
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    ANDLW   B'11101111'				;W = W & B'11101111'


ESCREVE_DISPLAY

    MOVWF   DISPLAY				;DISPLAY = W -> PORTB = W
    RETURN					;volta para o programa principal


ACENDE_UNIDADE

    MOVF    UNIDADE,W				;W = UNIDADE
    CALL    BUSCA_CODIGO			;chama a subrotina para obter o código de 7 segmentos
    GOTO    ESCREVE_DISPLAY


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