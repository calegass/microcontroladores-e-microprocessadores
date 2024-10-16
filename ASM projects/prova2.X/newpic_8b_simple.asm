;prescaler de 1:8
;v_tmr0 de 131
    
;t = 1 * 8 * (256 - 131) = 1000 us = 1 ms
    
;250ms = 1ms * (256 - 6) -> contador comecando em 6
    
; Author: Matheus Calegari
; CPF/RA: 09389728630 
; Created on 09 de Outubro de 2024, 09:00
    
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
	CONTADOR ;contador auxiliar para informar se passou 250ms
	VALOR_ADC
	VALOR_ADC_POT
	VALOR_ADC_TEMP
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
;variáveis
#define	FIM_250MS	FLAGS,0
#define	TROCA_DISPLAY	FLAGS,1
#define EH_NEGATIVO	FLAGS,2
#define PROCESSO_ATIVO	FLAGS,3
#define LENDO_TEMP	FLAGS,4

;entradas
#define	B_ON		PORTB,0 ;S1
#define	B_OFF		PORTB,1	;S2
#define B_POT		PORTB,2 ;S3
#define B_TEMP		PORTB,3 ;S4

;saídas
#define	DISPLAY		PORTD
#define	D_UNIDADE	PORTB,4    
#define	D_DEZENA	PORTB,5  
#define	D_CENTENA	PORTB,6  
#define	D_MILHAR	PORTB,7
;#define COOLER		PORTC,1
#define	HEATER		PORTC,2 ;resistencia ohmica para ligar e desliga a temperatura
    
;constantes
V_TMR0	    equ		.131
	    
; como meu prescaler eh 1:8 e meu tmr0 vai de 131 a 256 (125), meu tmr0 acontece de 1ms em 1ms
	    
	
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
    DECFSZ  CONTADOR,F	    ;CONTADOR-- e teta se zerou
    GOTO    SAI_INTERRUPCAO ;se nao zerou, pula para SAI_INTERRUPCAO
    BSF	    FIM_250MS	    ;FIM_250MS = 1
    
    ;como eu quero que seja lido de 250 em 250 ms e meu TMR0 vai de 1 em 1, meu contador roda 250 vezes (256 - 6)
    
    MOVLW   .6		    ;W = 6 -> como cada interrupcao acontece a cada 1 ms, se ja passou 6 = 250ms
    MOVWF   CONTADOR
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
    
    BCF	    TRISC,2	    ;configura o pino 2 da PORTC como saída
;    BCF	    TRISC,1
    
    MOVLW   B'11010010'	    ;prescaler de 1:8
    MOVWF   OPTION_REG
    
    MOVLW   B'01000100'
    MOVWF   ADCON1    

    BANK0
    
    MOVLW   B'11001001'	
    MOVWF   ADCON0	
        
    MOVLW   .6
    MOVWF   CONTADOR	    ;inicializando o contador para n demorar a ler
    
    CLRF    FLAGS	    ;FLAGS = 0
    CLRF    UNIDADE
    CLRF    DEZENA
    CLRF    CENTENA
    CLRF    MILHAR
    
    BSF	    INTCON,T0IE	    ;habilita o atendimento de interrpção por TIMER0
    BSF	    INTCON,GIE	    ;habilita o atendimento de interrupções
    
    
LACO_PRINCIPAL
    
    BTFSC   TROCA_DISPLAY	;testa se já passou 1ms
    CALL    ATUALIZA_DISPLAY	;se já passou 1ms,chama a subrotina ATUALIZA_DISPLAY

    CALL    LER_BOTOES
    
    BTFSS   FIM_250MS
    GOTO    LACO_PRINCIPAL
    
    BCF	    FIM_250MS
    
    BTFSC   PROCESSO_ATIVO
    CALL    REALIZAR_PROCESSO
    
    BTFSS   PROCESSO_ATIVO
    BCF	    HEATER
    
    BTFSC   LENDO_TEMP
    CALL    INICIA_LEITURA_TEMP
    
    BTFSS   LENDO_TEMP
    CALL    INICIA_LEITURA_POT
    
    BSF	    ADCON0,GO_DONE
    BTFSC   ADCON0,GO_DONE
    GOTO    $-1
    
    MOVF    ADRESH,W
    MOVWF   VALOR_ADC
    
    CLRF    UNIDADE
    CLRF    DEZENA
    CLRF    CENTENA
        
    GOTO    VERIFICA_CENTENA
    
    
REALIZAR_PROCESSO
    
    CALL    INICIA_LEITURA_POT
    
    BSF     ADCON0,GO_DONE
    BTFSC   ADCON0,GO_DONE
    GOTO    $-1
    MOVF    ADRESH,W
    MOVWF   VALOR_ADC_POT

    CALL    INICIA_LEITURA_TEMP
    
    BSF     ADCON0,GO_DONE
    BTFSC   ADCON0,GO_DONE
    GOTO    $-1
    MOVF    ADRESH,W
    MOVWF   VALOR_ADC_TEMP

    MOVF    VALOR_ADC_TEMP,W
    SUBWF   VALOR_ADC_POT,W
    
    BTFSC   STATUS,C
    BSF     HEATER
    
    BTFSS   STATUS,C
    BCF     HEATER
    
    RETURN
    
    
LER_BOTOES
    
    BTFSS   B_POT
    BCF    LENDO_TEMP
    
    BTFSS   B_TEMP
    BSF    LENDO_TEMP
    
    BTFSS   B_ON
    BSF	    PROCESSO_ATIVO
    
    BTFSS   B_OFF
    BCF	    PROCESSO_ATIVO
    
    RETURN

    
INICIA_LEITURA_POT

    MOVLW   B'11001001'	
    MOVWF   ADCON0	
    
    RETURN

    
INICIA_LEITURA_TEMP
    
    MOVLW   B'11000001'	  
    MOVWF   ADCON0	 
    
    RETURN
    
        
;-------------------------------------------
;----------- CODIGO APROVEITADO: -----------
;-------------------------------------------


    
VERIFICA_CENTENA
    MOVLW   .100
    SUBWF   VALOR_ADC,W
    BTFSS   STATUS,C
    GOTO    VERIFICA_DEZENA
    INCF    CENTENA,F
    MOVWF   VALOR_ADC
    GOTO    VERIFICA_CENTENA
    
VERIFICA_DEZENA
    MOVLW   .10
    SUBWF   VALOR_ADC,W
    BTFSS   STATUS,C
    GOTO    VERIFICA_UNIDADE
    INCF    DEZENA,F
    MOVWF   VALOR_ADC
    GOTO    VERIFICA_DEZENA
    
VERIFICA_UNIDADE
    MOVF    VALOR_ADC,W
    MOVWF   UNIDADE
    GOTO    LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    BCF	    TROCA_DISPLAY	
    BTFSS   D_UNIDADE	
    GOTO    TESTA_DEZENA
    BCF	    D_UNIDADE
    MOVF    DEZENA,W		
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF	    D_DEZENA
    RETURN	
    
TESTA_DEZENA
    BTFSS   D_DEZENA	
    GOTO    TESTA_CENTENA
    BCF	    D_DEZENA
    MOVF    CENTENA,W		
    CALL    BUSCA_CODIGO	
    MOVWF   DISPLAY
    BSF	    D_CENTENA
    RETURN
    
TESTA_CENTENA
    BTFSS   D_CENTENA		;testa se a DEZENA está acesa
    GOTO    TESTA_MILHAR	;se D_DEZENA = 0, pula para ACENDE_UNIDADE
    BCF	    D_CENTENA		;apaga o display da DEZENA
    MOVF    MILHAR,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_MILHAR		;acende display da UNIDADE
    RETURN			;volta para o programa principal
    
TESTA_MILHAR
    BCF	    D_MILHAR		;apaga o display da DEZENA
    MOVF    UNIDADE,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_UNIDADE		;acende display da UNIDADE
    RETURN			;volta para o programa principal    
    
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
