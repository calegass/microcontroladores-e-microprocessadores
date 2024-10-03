;PROVA - 1 MICRO
;RAFAEL JARDIM CARONI
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF
;=======================================================
#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0
;=======================================================
;nomear posições da memória RAM
    CBLOCK  0X20    ;bloco de memória
	FLAGS	    ;0x20
	AUX_CONT    ;0x21
	S_TEMP	    ;0x22
	W_TEMP	    ;0x23	
	UNIDADE	    ;0x24
	FILTRO_INC  ;0x25
	FILTRO_DEC  ;0x26
    ENDC	    ;fim de bloco de memória
;======================================================= 
;variáveis boolenas
#define	PISCANDO    FLAGS,0
#define	FIM_TEMPO   FLAGS,1
#define	JA_LI_UP    FLAGS,2
#define	JA_LI_DOWN  FLAGS,3

;=======================================================    
;entradas
#define B_LIGA	    PORTA,1
#define B_DESLIGA   PORTA,2    
#define B_FREQ_UP   PORTA,3    
#define B_FREQ_DOWN PORTA,4
;=======================================================
;saídas
#define LAMPADA	    PORTA,0    
#define DISPLAY	    PORTB
;=======================================================
;constantes
V_TMR0	    equ	    .131	;256 - 131 = 125 PULSOS
V_TEMPO	    equ	    .250
V_FILTRO    equ	    .100
;=======================================================
RES_VECT  CODE    0x0000        ;processor reset vector
    GOTO    START               ;go to beginning of program
;=======================================================
;USANDO O PRESCALER DE 08 B'XXXXX010' COM MULTIPLOS PARA AS FREQUENCIAS PEDIDAS
;SENDO ELAS:
;	2Hz -- 500Ms/2 -- 250	AUX
;	4Hz -- 250Ms/2 -- 125	AUX
;	5Hz -- 200Ms/2 -- 100	AUX
;	6.67Hz -- 150Ms/2 -- 75	AUX
;	8.33Hz -- 120Ms/2 -- 60	AUX
;	10Hz -- 100Ms/2 -- 50	AUX
;	12.5Hz -- 80Ms/2 -- 40	AUX
;	16.67Hz -- 60Ms/2 -- 30	AUX
;	20Hz -- 50Ms/2 -- 25	AUX
;	25Hz -- 40Ms/2 -- 20	AUX

;=======================================================
;rotina de interrução
ISR       CODE    0x0004	; interrupt vector location
    MOVWF   W_TEMP		;salva o conteúdo de W em W_TEMP
    MOVF    STATUS,W		;carrega o conteúdo de STATUS em W
    MOVWF   S_TEMP		;salva o conteúdo de STATUS em S_TEMP
    BTFSS   INTCON,T0IF		;testa se a interrupção é por TMR0
    GOTO    SAI_INTERRUPCAO	;se não é por TMR0, pule para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF		;limpa o bit indicador de interrupção por TMR0
    MOVLW   V_TMR0		;carrega 6 em W
    ADDWF   TMR0,F		;soma 6 ao conteúdo do TMR0
    DECFSZ  AUX_CONT,F		;decrementa AUX_CONT e testa se é 0
    GOTO    SAI_INTERRUPCAO	;se for 0, pule para SAI_INTERRUPCAO
    BSF	    FIM_TEMPO		;seta indicador de fim de tempo
;    MOVLW   V_TEMPO		;carrega o valor inicial do contador auxiliar em W
;    MOVWF   AUX_CONT		;carrega o valor no contador auxiliar - AUX_CONT
    CALL    MUDA_FREQ
SAI_INTERRUPCAO
    MOVF    S_TEMP,W		;carrega o conteúdo de S_TEMP em W 
    MOVWF   STATUS		;salva o conteúdo de W em STATUS
    MOVF    W_TEMP,W		;salva o conteúdo de W_TEMP em W    
    RETFIE
;fim da rotina de interrução
;=======================================================
;código principal
START
    BANK1		    ;seleciona o banco 1 da memória RAM
    BCF	    TRISA,0	    ;configura o bit 0 do PORTA como saída
    CLRF    TRISB
    MOVLW   B'11010010'	    ;define a palavra de configuração do TIMER0
			    ;bit 7 - RBPU:1 - desabilita os registros do PORTB
			    ;bit 6 - INTEDG:1 - define a borda da interrupção por borda
			    ;bit 5 - T0CS:0 - define clock interno para TMR0
			    ;bit 4 - T0SE:1 - define borda do clock TMR0, quando externo
			    ;bit 3 - PSA:0 - associa o prescaler ao TMR0
			    ;bit 2..0 - PS<2..0>:011 - define prescaler em 1:16
    MOVWF   OPTION_REG	    ;carrega a configuração no OPTION_REG
    BANK0		    ;seleciona o banco 0 da memória RAM    
    BCF	    LAMPADA	    ;apaga a lâmpada
    BCF	    PISCANDO	    ;limpa a booleana PISCANDO
    BCF	    FIM_TEMPO	    ;limpa a booleana FIM_TEMPO
    BCF	    JA_LI_UP
    BCF	    JA_LI_DOWN
    MOVLW   V_FILTRO
    MOVWF   FILTRO_INC
    MOVWF   FILTRO_DEC
    CLRF    UNIDADE
    CALL    ESCREVE_DISPLAY
    BSF	    INTCON,T0IE	    ;habilita o atendimento da interrupção por TIMER0
    BSF	    INTCON,GIE	    ;habilita o atendimento das interrupções    
LACO_PRINCIPAL
    BTFSC   PISCANDO	    ;testa se pisca não está ativo
    GOTO    TESTA_DESLIGA   ;se estiver ativo, pule para testar o botão DESLIGA
    BTFSC   B_LIGA	    ;testa se o botão LIGA está acionado
    GOTO    TESTA_B_INC	    ;se não estiver acionado, pule para LACO_PRINCIPAL
    BSF	    LAMPADA	    ;acende a lâmpada
    BSF	    PISCANDO	    ;seta a booleana PISCANDO
    MOVLW   V_TMR0	    ;carrega o valor inicial do TMR0 em W
    MOVWF   TMR0	    ;carrega o valor no TMR0
    ;CALL    MUDA_FREQ
    BCF	    FIM_TEMPO	    ;zera a boolena FIM_TEMPO
    GOTO    LACO_PRINCIPAL  ;pule para LACO_PRINCIPAL    
TESTA_DESLIGA
    BTFSC   B_DESLIGA	    ;testa se o botão DESLIGA está acionado
    GOTO    TESTA_FIM_TEMPO ;se não estiver acionado, pule para TESTA_FIM_TEMPO
    BCF	    LAMPADA	    ;apaga a lâmpada
    BCF	    PISCANDO	    ;limpa a booleana PISCANDO    
    GOTO    LACO_PRINCIPAL  ;pule para LACO_PRINCIPAL 
TESTA_FIM_TEMPO
    BTFSS   FIM_TEMPO	    ;testa se o intervalo de tempo expirou
    GOTO    LACO_PRINCIPAL  ;se não, pule para LACO_PRINCIPAL
    BCF     FIM_TEMPO	    ;limpa o indicador de fim de tempo
    BTFSS   LAMPADA	    ;testa se a lâmpada acesa
    GOTO    ACENDE_LAMPADA  ;se lâmpada apagada, pule para ACENDE_LAMPADA	
    BCF	    LAMPADA	    ;apaga a lâmpada
    GOTO    LACO_PRINCIPAL  ;pule para LACO_PRINCIPAL    
ACENDE_LAMPADA
    BSF	    LAMPADA	    ;acende a lâmpada
    GOTO    LACO_PRINCIPAL  ;pule para LACO_PRINCIPAL  
;======================================================= TESTES E FILTROS
TESTA_B_INC
    BTFSS   B_FREQ_UP
    GOTO    INCREMENTA
    MOVLW   V_FILTRO
    MOVWF   FILTRO_INC
    BCF	    JA_LI_UP
TESTA_B_DEC
    BTFSS   B_FREQ_DOWN
    GOTO    DECREMENTA
    MOVLW   V_FILTRO
    MOVWF   FILTRO_DEC
    BCF	    JA_LI_DOWN
    GOTO    LACO_PRINCIPAL
;======================================================= CONTADORES    
INCREMENTA
    BTFSC   JA_LI_UP
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO_INC,F
    GOTO    LACO_PRINCIPAL
    BSF	    JA_LI_UP
    INCF    UNIDADE,F		    ;incrementa o valor da UNIDADE
    MOVLW   .10			    ;carrega 10 em W (W = 10)
    SUBWF   UNIDADE,W		    ;subtrai 10 da UNIDADE, resultado em W (W = UNIDADE - W)
    BTFSC   STATUS,C		    ;testa se o resultado foi negativo
    CLRF    UNIDADE		    ;se UNIDADE > 9; faça UNIDADE = 0 
    CALL    ESCREVE_DISPLAY
    CALL    MUDA_FREQ
    GOTO    LACO_PRINCIPAL
DECREMENTA
    BTFSC   JA_LI_DOWN
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO_DEC,F
    GOTO    LACO_PRINCIPAL
    BSF	    JA_LI_DOWN
    DECFSZ  FILTRO_DEC,F
    MOVF    UNIDADE,W
    XORLW   .0
    BTFSC   STATUS,Z
    CALL    MOVE_10W
    DECF    UNIDADE,F
    CALL    ESCREVE_DISPLAY
    CALL    MUDA_FREQ
    GOTO    LACO_PRINCIPAL
;======================================================= FUNÇÕES PRONTAS
MOVE_10W
    MOVLW   .10
    MOVWF   UNIDADE
    RETURN
ESCREVE_DISPLAY
    MOVF    UNIDADE,W	    ;W = UNIDADE
    CALL    BUSCA_CODIGO    ;chama a subrotina para buscar o código a ser escrito no display
    MOVWF   DISPLAY	    ;escreve o valor no display (PORTB)
    RETURN
BUSCA_CODIGO
    ADDWF   PCL,F	    ; PC = PC + W (UNIDADE)
    RETLW   B'11111110'	    ;retorna com o valor 0xFE em W
    RETLW   B'00111000'	    ;retorna com o valor 0x38 em W    
    RETLW   B'11011101'	    ;retorna com o valor 0xDD em W
    RETLW   B'01111101'	    ;retorna com o valor 0x7D em W    
    RETLW   B'00111011'	    ;retorna com o valor 0x3B em W
    RETLW   B'01110111'	    ;retorna com o valor 0x77 em W    
    RETLW   B'11110111'	    ;retorna com o valor 0xF7 em W
    RETLW   B'00111100'	    ;retorna com o valor 0x3C em W     
    RETLW   B'11111111'	    ;retorna com o valor 0xFF em W
    RETLW   B'01111111'	    ;retorna com o valor 0x7F em W 
;=======================================================    
;FUNÇÕES RESPONSAVEIS POR MUDAR A FREQUECINCA
;RETORNAM UMA LITERAL PARA O AUX_CONT TODA VEZ QUE A UNIDADE É TROCADA
;ASSIM MUDANDO A FREQUENCIA EM QUE A LAMPADA PISCA
MUDA_FREQ
    MOVF    UNIDADE,W	    ;W = UNIDADE
    CALL    BUSCA_FREQ	    ;chama a subrotina para buscar o código a ser escrito no display
    MOVWF   AUX_CONT	    ;escreve o valor no display (PORTB)
    RETURN
BUSCA_FREQ
    ADDWF   PCL,F	    ; PC = PC + W (UNIDADE)
    RETLW   .250	    ;retorna com o valor 0xFE em W
    RETLW   .125	    ;retorna com o valor 0x38 em W    
    RETLW   .100	    ;retorna com o valor 0xDD em W
    RETLW   .75		    ;retorna com o valor 0x7D em W    
    RETLW   .60		    ;retorna com o valor 0x3B em W
    RETLW   .50		    ;retorna com o valor 0x77 em W    
    RETLW   .40		    ;retorna com o valor 0xF7 em W
    RETLW   .30		    ;retorna com o valor 0x3C em W     
    RETLW   .25		    ;retorna com o valor 0xFF em W
    RETLW   .20		    ;retorna com o valor 0x7F em W 
;=======================================================

    END