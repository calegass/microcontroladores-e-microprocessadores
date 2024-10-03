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
	CONTADOR
	VALOR_ADC
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
;variáveis
#define	FIM_100MS	FLAGS,0
#define	TROCA_DISPLAY	FLAGS,1

;entradas
#define	B_UP		PORTB,0
#define	B_RESET		PORTB,1

;saídas
#define	DISPLAY		PORTD
#define	D_UNIDADE	PORTB,4    
#define	D_DEZENA	PORTB,5  
#define	D_CENTENA	PORTB,6  
#define	D_MILHAR	PORTB,7
    
;constantes
V_TMR0	    equ		.131
V_FILTRO    equ		.100	
	
RES_VECT  CODE    0x0000    ;vetor de reset,define deve estar a 1ª instrução do programa
    GOTO    START           ;pula a área de armazenamento de interrupção

INT_VECT  CODE    0x0004    ;vetor de interrupção, define deve estar a 1ª instrução da interrupção
    MOVWF   W_TEMP	    ;salvar W em W_TEMP
    MOVF    STATUS,W	    ;W = STATUS
    MOVWF   S_TEMP	    ;salvar STATUS em S_TEMP
    BTFSS   INTCON,T0IF	    ;testa se a interrupção foi por TIMER0
    GOTO    SAI_INTERRUPCAO ;se não foi, pula para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF	    ;limpa o bit de indicação de interrupção por TIMER0
    MOVLW   V_TMR0	    ;W = V_TMR0 -> W = 131
    ADDWF   TMR0,F	    ;TMR0 = TMR0 + V_TMR0 -> TMR0 = TMR0 + 131
    BSF	    TROCA_DISPLAY   ;TROCA_DISPLAY = 1
    DECFSZ  CONTADOR,F	    ;CONTADOR-- e testa se zerou
    GOTO    SAI_INTERRUPCAO ;se não zerou, pula para SAI_INTERRUPCAO
    BSF	    FIM_100MS	    ;FIM_100MS = 1
    MOVLW   .25		    ;W = 25
    MOVWF   CONTADOR	    ;CONTADOR = 25
SAI_INTERRUPCAO
    MOVF    S_TEMP,W	    ;W = S_TEMP
    MOVWF   STATUS	    ;restaura STATUS
    MOVF    W_TEMP,W	    ;restaura W
    RETFIE

START
    BANK1
    CLRF    TRISD	    ;configura todo o PORTD como saída
    MOVLW   B'00001111'	    ;W = 00001111
    MOVWF   TRISB	    ;TRISB = 00001111
    MOVLW   B'11010100'	    ;palavra de configuração do TIMER0
			    ;bit7: ativa resistores PULL_UP do PORTB
			    ;bit6: define o tipo de borda para RB0
			    ;bit5: define origem do clock do TIMER0				    
			    ;bit4: define borda do clock do TIMER0 qdo clock for externo
			    ;bit3: quem usa o PRESCALER - TMR0 ou WDT
			    ;bit2..0: define o PRESCALER - 100 - 1:32				  
    MOVWF   OPTION_REG	    ;carrega a configuração do TIMER0
    MOVLW   B'01000100'	    ;palavra de configuração do ADCON1
			    ;bit7: ADFM = 0 - Justificado à esquerda
			    ;bit6: ADCS2 = 1 - clock RC pra a ADC
			    ;bit5..4: não usado				     
			    ;bit3..0:PCFG3..PCFG0 - 0100 - entradas AN3, AN1 e AN0
    MOVWF   ADCON1	    ;carrega a configuração do ADCON1
    BANK0
    MOVLW   B'11001001'	    ;palavra de configuração do ADCON0
			    ;bit7..6 - ADCS1..ADCS0 - 11 - clock RC pra a ADC
			    ;bit5..3 - CHS2..CHS0 - seleção de canal - 001
			    ;bit2 - GO/DONE = 0 				     
			    ;bit1 - não usado
			    ;bit0 - ADON = 1 liga o conversor			    
    MOVWF   ADCON0	    ;carrega a configuração do ADCON0
    MOVLW   .25
    MOVWF   CONTADOR
    CLRF    FLAGS	    ;FLAGS = 0
    BSF	    INTCON,T0IE	    ;habilita o atendimento de interrpção por TIMER0
    BSF	    INTCON,GIE	    ;habilita o atendimento de interrupções
LACO_PRINCIPAL
    BTFSC   TROCA_DISPLAY	;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY	;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    BTFSS   FIM_100MS		;testa se já passou 100ms
    GOTO    LACO_PRINCIPAL	;se não passou 100ms, pula para LACO_PRINCIPAL
    BSF	    ADCON0,GO_DONE	;incia a conversão
    BTFSC   ADCON0,GO_DONE	;testa se a conversão foi feita
    GOTO    $-1			;se não acabou, teste de novo
    MOVF    ADRESH,W		;W = ADRESH
    MOVWF   VALOR_ADC		;VALOR_ADC = ADRESH
    CLRF    UNIDADE		;UNIDADE = 0
    CLRF    DEZENA		;DEZENA = 0
    CLRF    CENTENA		;CENTENA = 0
VERIFICA_CENTENA
    MOVLW   .100		;W = 100
    SUBWF   VALOR_ADC,W		;W = VALOR_ADC - 100
    BTFSS   STATUS,C		;testa se VALOR_ADC >= 100
    GOTO    VERIFICA_DEZENA	;se VALOR_ADC < 100, pula para VERIFICA_DEZENA
    INCF    CENTENA,F		;CENTENA++
    MOVWF   VALOR_ADC		;VALOR_ADC = VALOR_ADC - 100
    GOTO    VERIFICA_CENTENA	;pula para VERIFICA_CENTENA
VERIFICA_DEZENA
    MOVLW   .10			;W = 10
    SUBWF   VALOR_ADC,W		;W = VALOR_ADC - 10
    BTFSS   STATUS,C		;testa se VALOR_ADC >= 10
    GOTO    VERIFICA_UNIDADE	;se VALOR_ADC < 10, pula para VERIFICA_UNIDADE
    INCF    DEZENA,F		;DEZENA++
    MOVWF   VALOR_ADC		;VALOR_ADC = VALOR_ADC - 10
    GOTO    VERIFICA_DEZENA	;pula para VERIFICA_DEZENA    
VERIFICA_UNIDADE
    MOVF    VALOR_ADC,W		;carrega o resto para W
    MOVWF   UNIDADE		;carrega o resto para UNIDADE
    GOTO    LACO_PRINCIPAL	;
    
    
ATUALIZA_DISPLAY
    BCF	    TROCA_DISPLAY	;TROCA_DISPLAY = 0
    BTFSS   D_UNIDADE		;testa se a UNIDADE está acesa
    GOTO    TESTA_DEZENA	;se D_UNIDADE = 0, pula para TESTA_DEZENA
    BCF	    D_UNIDADE		;apaga display da UNIDADE
    MOVF    DEZENA,W		;W = DEZENA
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos   	       
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_DEZENA		;acende o display da DEZENA   
    RETURN			;volta para o programa principal    
TESTA_DEZENA
    BTFSS   D_DEZENA		;testa se a DEZENA está acesa 
    GOTO    TESTA_CENTENA	;se D_DEZENA = 0, pula para TESTA_CENTENA
    BCF	    D_DEZENA		;apaga o display da DEZENA
    MOVF    CENTENA,W		;W = CENTENA
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_CENTENA		;acende display da CENTENA
    RETURN			;volta para o programa principal
TESTA_CENTENA
    BCF	    D_CENTENA		;apaga o display da CENTENA
    MOVF    UNIDADE,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_UNIDADE		;acende display da UNIDADE
    RETURN			;volta para o programa principal    
       
BUSCA_CODIGO
    ADDWF   PCL,F		;PCL = PCL + W
    RETLW   0x3F		;retorna da subrotina com W = 0x3F
    RETLW   0x06		;retorna da subrotina com W = 0x06    
    RETLW   0x5B		;retorna da subrotina com W = 0x5B    
    RETLW   0x4F		;retorna da subrotina com W = 0x4F
    RETLW   0x66		;retorna da subrotina com W = 0x66
    RETLW   0x6D		;retorna da subrotina com W = 0x6D    
    RETLW   0x7D		;retorna da subrotina com W = 0x7D    
    RETLW   0x07		;retorna da subrotina com W = 0x07    
    RETLW   0x7F		;retorna da subrotina com W = 0x7F
    RETLW   0x6F		;retorna da subrotina com W = 0x6F    
    
    
    
    
    END