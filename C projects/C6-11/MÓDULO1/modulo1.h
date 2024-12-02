#include <16F877A.h>
#device ADC=10

#FUSES PUT                   	//Power Up Timer
#FUSES NOLVP                 	//No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O

#use delay(crystal=4MHz)

#define C1	PIN_C1
#define C2	PIN_C2

#use rs232(baud=9600,parity=N,xmit=PIN_C6,rcv=PIN_C7,bits=8)

