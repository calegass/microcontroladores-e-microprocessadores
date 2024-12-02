#include <main.h>
#include <lcd_8bits.c>

int1 fim_tempo = 0;
int16 contador = 1000;
int16 tempo = 0;

int8 hours = 0;
int8 minutes = 0;
int8 seconds = 0;

int8 days = 1;
int8 months = 1;
int16 years = 1;

int8 alarm_hours = 0;
int8 alarm_minutes = 0;
int8 alarm_seconds = 0;

int8 alarm_days = 1;
int8 alarm_months = 1;
int16 alarm_years = 1;

int1 showing_alarm = 0;
int1 setting_time = 0;

int8 position = 0;
int8 alarm_position = 0;

int1 alarm_on = 0;
int1 ringing = 0;

void ler_botoes();
void convert_time();
void convert_date();
void display_datetime();
void display_alarm(); 
void alarm();

#INT_TIMER0
void  TIMER0_isr(void) 
{
	set_timer0(get_timer0() + 6); // = 1 ms overflow
	contador--; 
	if (!contador) 
	{ 
		contador = 1000; 
		fim_tempo = 1; 
	}
}

void main()
{
	setup_timer_0(RTCC_INTERNAL|RTCC_DIV_8|RTCC_8_BIT);		//1,0 ms overflow
	set_timer0(get_timer0() + 6); // = 1 ms overflow


	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	lcd_init();

	lcd_gotoxy(1, 1);
	printf(lcd_write_dat, "00:00:00        ");
	//					   12345678901234
	lcd_gotoxy(1, 2);
	printf(lcd_write_dat, "00/00/0000      ");
	while(TRUE)
	{
		ler_botoes();
		if (alarm_on)
		{
			alarm();
		}
		if (ringing)
		{
			if (!input(S4))
			{
				ringing = 0;
				output_low(BUZZER);
				alarm_on = 0;
			}
		}
		if (fim_tempo)
		{
			if (setting_time)
			{
				if (showing_alarm) 
				{
					if (!input(S3))
					{
						alarm_position++;
						if (alarm_position > 5)
						{
							alarm_position = 0;
						}
						delay_ms(200);
					}
					if (!input(S4))
					{
						switch (alarm_position)
						{
						case 0:
							alarm_hours++;
							if (alarm_hours == 24)
							{
								alarm_hours = 0;
							}
							break;
						case 1:
							alarm_minutes++;
							if (alarm_minutes == 60)
							{
								alarm_minutes = 0;
							}
							break;
						case 2:
							alarm_seconds++;
							if (alarm_seconds == 60)
							{
								alarm_seconds = 0;
							}
							break;
						case 3:
							alarm_days++;
							if (alarm_months == 1 || alarm_months == 3 || alarm_months == 5 || alarm_months == 7 || alarm_months == 8 || alarm_months == 10 || alarm_months == 12)
							{
								if (alarm_days == 32)
								{
									alarm_days = 1;
								}
							}
							else if (alarm_months == 4 || alarm_months == 6 || alarm_months == 9 || alarm_months == 11)
							{
								if (alarm_days == 31)
								{
									alarm_days = 1;
								}
							}
							else if (alarm_months == 2)
							{
								if (alarm_years % 4 == 0)
								{
									if (alarm_days == 30)
									{
										alarm_days = 1;
									}
								}
								else
								{
									if (alarm_days == 29)
									{
										alarm_days = 1;
									}
								}
							}
							break;
						case 4:
							alarm_months++;
							if (alarm_months == 13)
							{
								alarm_months = 1;
							}
							break;
						case 5:
							alarm_years++;
							break;
						}
						display_alarm();
						delay_ms(100);
					}
					switch (alarm_position)
					{
					case 0:
						lcd_gotoxy(16, 2);
						lcd_write_dat(" ");
						lcd_gotoxy(10, 1);
						lcd_write_dat("_");
						break;
					case 1:
						lcd_gotoxy(10, 1);
						lcd_write_dat(":");
						lcd_gotoxy(13, 1);
						lcd_write_dat("_");
						break;
					case 2:
						lcd_gotoxy(13, 1);
						lcd_write_dat(":");
						lcd_gotoxy(16, 1);
						lcd_write_dat("_");
						break;
					case 3:
						lcd_gotoxy(16, 1);
						lcd_write_dat(" ");
						lcd_gotoxy(8, 2);
						lcd_write_dat("_");
						break;
					case 4:
						lcd_gotoxy(8, 2);
						lcd_write_dat("/");
						lcd_gotoxy(11, 2);
						lcd_write_dat("_");
						break;
					case 5:
						lcd_gotoxy(11, 2);
						lcd_write_dat("/");
						lcd_gotoxy(16, 2);
						lcd_write_dat("_");
						break;
					}
					
				}
				else {
					if (!input(S3))
					{				
						position++;
						if (position > 5)
						{
							position = 0;
						}
						delay_ms(200);
					}
					if (!input(S4))
					{
						switch (position)
						{
						case 0:
							hours++;
							if (hours == 24)
							{
								hours = 0;
							}
							break;
						case 1:
							minutes++;
							if (minutes == 60)
							{
								minutes = 0;
							}
							break;
						case 2:
							seconds++;
							if (seconds == 60)
							{
								seconds = 0;
							}
							break;
						case 3:
							days++;
							if (months == 1 || months == 3 || months == 5 || months == 7 || months == 8 || months == 10 || months == 12)
							{
								if (days == 32)
								{
									days = 1;
								}
							}
							else if (months == 4 || months == 6 || months == 9 || months == 11)
							{
								if (days == 31)
								{
									days = 1;
								}
							}
							else if (months == 2)
							{
								if (years % 4 == 0)
								{
									if (days == 30)
									{
										days = 1;
									}
								}
								else
								{
									if (days == 29)
									{
										days = 1;
									}
								}
							}
							break;
						case 4:
							months++;
							if (months == 13)
							{
								months = 1;
							}
							break;
						case 5:
							years++;
							break;
						}
						display_datetime();
						delay_ms(100);
					}
					switch (position)
					{
					case 0:
						lcd_gotoxy(11, 2);
						lcd_write_dat(" ");
						lcd_gotoxy(3, 1);
						lcd_write_dat("_");
						break;
					case 1:
						lcd_gotoxy(3, 1);
						lcd_write_dat(":");
						lcd_gotoxy(6, 1);
						lcd_write_dat("_");
						break;
					case 2:
						lcd_gotoxy(6, 1);
						lcd_write_dat(":");
						lcd_gotoxy(9, 1);
						lcd_write_dat("_");
						break;
					case 3:
						lcd_gotoxy(9, 1);
						lcd_write_dat(" ");
						lcd_gotoxy(3, 2);
						lcd_write_dat("_");
						break;
					case 4:
						lcd_gotoxy(3, 2);
						lcd_write_dat("/");
						lcd_gotoxy(6, 2);
						lcd_write_dat("_");
						break;
					case 5:
						lcd_gotoxy(6, 2);
						lcd_write_dat("/");
						lcd_gotoxy(11, 2);
						lcd_write_dat("_");
						break;
					}
				}
			}
			else {
				if (!showing_alarm)
				{
					display_datetime();
				}
				else
				{
					display_alarm();
				}
				convert_time();

				fim_tempo = 0;
			}
		}
		
		//TODO: User Code
	}
}

void ler_botoes()
{
	if (!input(S1))
	{
		if (!setting_time)
		{
			showing_alarm = !showing_alarm;
		}
		else {
			if (showing_alarm) 
			{
				alarm_on = !alarm_on;

				if (alarm_on)
				{
					lcd_gotoxy(1, 2);
					printf(lcd_write_dat, "ON ");
				}
				else {
					lcd_gotoxy(1,2);
					printf(lcd_write_dat, "OFF");
				}
			}
		}

		delay_ms(100);
	}
	if (!input(S2))
	{
		setting_time = !setting_time;

		delay_ms(100);
	}     
}

void convert_time()
{
	seconds++;
	if (seconds == 60)
	{
		seconds = 0;
		minutes++;
		if (minutes == 60)
		{
			minutes = 0;
			hours++;
			if (hours == 24)
			{
				hours = 0;
				convert_date();
			}
		}
	}
}

void convert_date()
{
	days++;
	if (months == 1 || months == 3 || months == 5 || months == 7 || months == 8 || months == 10 || months == 12)
	{
		if (days == 32)
		{
			days = 1;
			months++;
			if (months == 13)
			{
				months = 1;
				years++;
			}
		}
	}
	else if (months == 4 || months == 6 || months == 9 || months == 11)
	{
		if (days == 31)
		{
			days = 1;
			months++;
		}
	}
	else if (months == 2)
	{
		if (years % 4 == 0)
		{
			if (days == 30)
			{
				days = 1;
				months++;
			}
		}
		else
		{
			if (days == 29)
			{
				days = 1;
				months++;
			}
		}
	}
}

void display_datetime()
{
	lcd_gotoxy(1, 1);
	printf(lcd_write_dat, "%02u:%02u:%02u     ", hours, minutes, seconds);
	lcd_gotoxy(1, 2);
	printf(lcd_write_dat, "%02d/%02d/%04LU      ", days, months, years);

	if (alarm_on)
	{
		lcd_gotoxy(14, 1);
		printf(lcd_write_dat, "ON ");
	}
	else {
		lcd_gotoxy(14, 1);
		printf(lcd_write_dat, "OFF");
	}
}

void display_alarm()
{
	lcd_gotoxy(1, 1);
	printf(lcd_write_dat, "ALARM: %02u:%02u:%02u ", alarm_hours, alarm_minutes, alarm_seconds);
	lcd_gotoxy(1, 2);
	printf(lcd_write_dat, "     %02d/%02d/%04LU ", alarm_days, alarm_months, alarm_years);

	if (alarm_on)
	{
		lcd_gotoxy(1, 2);
		printf(lcd_write_dat, "ON ");
	}
	else {
		lcd_gotoxy(1,2);
		printf(lcd_write_dat, "OFF");
	}
}

void alarm()
{
	if (hours == alarm_hours && minutes == alarm_minutes && seconds == alarm_seconds && days == alarm_days && months == alarm_months && years == alarm_years)
	{
		ringing = 1;
		output_high(BUZZER);
	}
}