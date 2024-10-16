; 09389728630 + 1 + 23/04/2004
; 0+9+3+8+9+7+2+8+6+3+0+1+2+3+0+4+2+0+0+4 = 71
; 71 * 150 = 10650 -> 10,65s
    
; prescaler 1:256
; TMR0 contando de 0 a 256
; 256 * (256 - 0) = 65536us   
; 10.650.000us / 65536us ~= 162

; Author: Matheus Calegari
; Created on 25 de Setembro de 2024, 09:00

; PIC16F628A Configuration Bit Settings
#include "p16f628a.inc"

; CONFIG
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

    
; Defini��o de Bancos
#define BANK0   BCF STATUS,RP0
#define BANK1   BSF STATUS,RP0    

; Vari�veis
CBLOCK  0x20
    FLAGS
    FILTRO
    UNIDADE
    TMR_MS
    S_TEMP
    W_TEMP
ENDC

; Defini��o de Flags
#define JA_LI   FLAGS,0
#define LIGADO  FLAGS,1

; Entradas
#define B_LIGA      PORTA,3
#define B_DESLIGA   PORTA,4

; Sa�das
#define C_PRINCIPAL PORTA,0
#define C_ESTRELA   PORTA,1
#define C_TRIANGULO PORTA,2
#define DISPLAY     PORTB

; Constantes
V_FILTRO    equ .100
V_TMR0      equ .0

; Vetores de Interrup��o e Reset
RES_VECT  CODE    0x0000            ; Vetor de Reset
    GOTO    START                   ; In�cio do programa

INT_VEC	CODE    0x0004              ; Vetor de interrup��o
    MOVWF   W_TEMP                  ; Salvar W em W_TEMP
    MOVF    STATUS,W                ; W = STATUS
    MOVWF   S_TEMP                  ; Salvar STATUS em S_TEMP
    BTFSS   INTCON,T0IF             ; Verifica se a interrup��o foi por TIMER0
    GOTO    SAI_INTERRUPCAO         ; Se n�o, pula para SAI_INTERRUPCAO
    BCF     INTCON,T0IF             ; Limpa o bit de interrup��o por TIMER0
    MOVLW   V_TMR0                  ; W = V_TMR0 -> 244
    ADDWF   TMR0,F                  ; TMR0 = TMR0 + V_TMR0

    INCF    TMR_MS,F                ; Incrementa TMR_MS
    CALL    MUDAR_CONTATOR          ; Atualiza o contator

SAI_INTERRUPCAO
    MOVF    S_TEMP,W                ; Restaura STATUS
    MOVWF   STATUS
    MOVF    W_TEMP,W                ; Restaura W
    RETFIE

; C�digo principal
MAIN_PROG CODE

START
    BANK1
    MOVLW   B'11111000'             ; Configura RA0, RA1, RA2 como sa�das e RA3, RA4 como entradas
    MOVWF   TRISA                   ; Configura��o do registrador TRISA
    MOVLW   B'11010111'             ; Configura��o do TIMER0: prescaler 1:256
    MOVWF   OPTION_REG              ; Carrega configura��o no OPTION_REG

    CLRF    TRISB                   ; Configura PORTB como sa�da
    BANK0
    
START_SIMPLIFICADO
    MOVLW   V_FILTRO                ; W = V_FILTRO (100)
    MOVWF   FILTRO                  ; Carrega FILTRO
    
    BCF     JA_LI                   ; JA_LI = 0
    BCF     LIGADO
    
    CLRF    UNIDADE
    BCF     C_PRINCIPAL
    BCF     C_ESTRELA
    BCF     C_TRIANGULO
    
    CALL    ATUALIZA_DISPLAY        ; Atualiza display
    CLRF    TMR_MS                  ; Zera o contador do Timer0
    
    BCF     INTCON,T0IE             ; Desabilita interrup��o por Timer0
    BSF     INTCON,GIE              ; Habilita interrup��es globais

    GOTO    LACO_PRINCIPAL          ; Loop principal

LACO_PRINCIPAL    
    BTFSS   B_DESLIGA               ; Verifica se o bot�o de desligar foi pressionado
    GOTO    START_SIMPLIFICADO
    
    BTFSS   B_LIGA                  ; Verifica se o bot�o de ligar foi pressionado
    GOTO    LIGAR
    
    MOVLW   V_FILTRO                ; W = V_FILTRO (100)
    MOVWF   FILTRO                  ; Reinicia o filtro
    
    BCF     JA_LI                   ; JA_LI = 0
    GOTO    LACO_PRINCIPAL
    
LIGAR
    BTFSC   LIGADO                  ; Verifica se j� est� ligado
    GOTO    LACO_PRINCIPAL
    
    BTFSC   JA_LI                   ; Verifica JA_LI
    GOTO    LACO_PRINCIPAL          ; Se j� foi lido, pula para o loop principal
    
    DECFSZ  FILTRO,F                ; Decrementa o filtro
    GOTO    LACO_PRINCIPAL          ; Se n�o zerou, continua no loop
    
    BSF     JA_LI                   ; Marca que foi lido
    BSF     LIGADO                  ; Marca que est� ligado
    
    INCF    UNIDADE,F               ; Incrementa a unidade
    CALL    ATUALIZA_DISPLAY        ; Atualiza display
    
    BSF     C_PRINCIPAL             ; Liga a sa�da principal
    BSF     C_ESTRELA               ; Liga a sa�da estrela
    
    CLRF    TMR_MS                  ; Zera o temporizador
    BSF     INTCON,T0IE             ; Habilita interrup��o por Timer0
    
    GOTO    LACO_PRINCIPAL          ; Volta ao loop principal
    
MUDAR_CONTATOR
    MOVLW   .162                    ; Carrega o valor 162 em W
    SUBWF   TMR_MS,W                ; Subtrai W de TMR_MS
    BTFSS   STATUS,Z                ; Testa se o resultado � zero
    RETURN                          ; Se n�o for, retorna
    
    BCF     INTCON,T0IE             ; Desabilita interrup��o por Timer0
    BCF     C_ESTRELA               ; Desliga C_ESTRELA
    BSF     C_TRIANGULO             ; Liga C_TRIANGULO
    
    INCF    UNIDADE,F               ; Incrementa unidade
    CALL    ATUALIZA_DISPLAY        ; Atualiza display
    
    GOTO    LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    MOVF    UNIDADE,W               ; W = UNIDADE
    CALL    BUSCA_CODIGO            ; Busca o c�digo correspondente ao valor
    MOVWF   DISPLAY                 ; Exibe no display (PORTB = W)
    RETURN                          ; Retorna da subrotina
    
BUSCA_CODIGO
    ADDWF   PCL,F                   ; Adiciona W ao contador de programa
    RETLW   0xFE                    ; C�digo 0
    RETLW   0x38                    ; C�digo 1
    RETLW   0xDD                    ; C�digo 2
    
END
