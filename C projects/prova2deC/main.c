//MATHEUS CALEGARI MOIZINHO
//RA: 09389728630

#include <main.h>

#define TEMPO_BUZZER 5000 // em ms

int1 fim_100ms = 0;
int1 decrementando = 0;
int1 buzzer_acionado = 0;

int8 aux_tempo = 100;
int8 display = 0;
int8 unidade = 0, dezena = 0, centena = 0, milhar = 0;
int8 codigo_7seg[] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

int16 aux_tempo_buzzer = TEMPO_BUZZER;
int16 contador = 0;

void atualizar_display();
void incrementar();
void decrementar();
void ler_botoes();

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0() + 6); // 1 ms overflow
	aux_tempo--; 
	if (!aux_tempo) 
	{ 
		aux_tempo = 100; 
		fim_100ms = 1; 
	}

	if (buzzer_acionado)
	{
		aux_tempo_buzzer--;
		if (!aux_tempo_buzzer)
		{
			output_low(BUZZER);
			buzzer_acionado = 0;
			aux_tempo_buzzer = TEMPO_BUZZER;
		}
	}
	atualizar_display();
}

void main()
{
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_4 | RTCC_8_BIT); // 1,0 ms overflow
	set_timer0(get_timer0() + 6);
	
	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_100ms)
		{
			fim_100ms = 0;
			if (decrementando)
			{
				decrementar();
				if (contador == 0)
				{
					buzzer_acionado = 1;
					output_high(BUZZER);

					decrementando = 0;
				}
			}
		}
		ler_botoes();
	}
}

void atualizar_display()
{
	output_low(D_UNIDADE);
	output_low(D_DEZENA);
	output_low(D_CENTENA);
	output_low(D_MILHAR);

	switch (display)
	{
	case 0:
		output_high(D_UNIDADE);
		output_d(codigo_7seg[unidade]);
		display = 1;
		break;
	case 1:
		output_high(D_DEZENA);
		output_d(codigo_7seg[dezena]);
		display = 2;
		break;
	case 2:
		output_high(D_CENTENA);
		output_d(codigo_7seg[centena]);
		display = 3;
		break;
	case 3:
		output_high(D_MILHAR);
		output_d(codigo_7seg[milhar]);
		display = 0;
		break;
	}
}

void incrementar()
{
	contador++;
	if (contador == 10000)
	{
		contador = 0;
	}
	unidade = contador % 10; // pega o resto da divisão por 10
	dezena = (contador / 10) % 10; // pega o resto da divisão por 100
	centena = (contador / 100) % 10; // pega o resto da divisão por 1000
	milhar = (contador / 1000) % 10; // pega o resto da divisão por 10000
}

void decrementar()
{
	contador--;
	if (contador == -1)
	{
		contador = 9999;
	}
	unidade = contador % 10;
	dezena = (contador / 10) % 10;
	centena = (contador / 100) % 10;
	milhar = (contador / 1000) % 10;
}

void ler_botoes()
{
	if (contador > 0 && input(S1) == 0)
	{
		decrementando = !decrementando;
		delay_ms(100);
	}
	if (input(S2) == 0)
	{
		aux_tempo_buzzer = 1;
		decrementando = 0;
		contador = 0;
		unidade = 0;
		dezena = 0;
		centena = 0;
		milhar = 0;
		delay_ms(100);
	}
	if (!decrementando)
	{
		if (input(S3) == 0)
		{
			incrementar();
			delay_ms(100);
		}
		if (input(S4) == 0)
		{
			decrementar();
			delay_ms(100);
		}
	}
}