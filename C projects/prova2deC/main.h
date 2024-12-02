#include <16F877A.h>
#device ADC=10

#FUSES PUT                   	//Power Up Timer
#FUSES BROWNOUT                 //Reset when brownout detected
#FUSES NOLVP                 	//No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O

#use delay(crystal=4MHz)
#use FIXED_IO( A_outputs=PIN_A5 )
#define BUZZER	    PIN_A5
#define S1	        PIN_B0
#define S2	        PIN_B1
#define S3	        PIN_B2
#define S4	        PIN_B3
#define D_UNIDADE   PIN_B4
#define D_DEZENA    PIN_B5
#define D_CENTENA   PIN_B6
#define D_MILHAR    PIN_B7

