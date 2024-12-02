/*=========================================
8-BIT LCD DRIVER FOR PIC16F877A CCSC
==========================================*/
///////////////////////////////////////////////////////////////////
// CCS C Compiler
// LCD 16x2
//
// by Nisar Ahmed
// 2009/03/27
//////////////////////////////////////////////////////////////////
//#include <16F877.h>                           // PIC16F877 header file
//#use delay(clock=4000000)                       // for 4Mhz crystal
//#fuses XT, NOWDT, NOPROTECT, NOLVP              // for debug mode

#define PORT_A                  0               // define for function output()
#define PORT_B                  1
#define PORT_C                  2
#define PORT_D                  3
#define PORT_E                  4

#define NCHAR_PER_LINE          16              // max char numbers per line
#define LCD_RS                  PIN_E0
#define LCD_RW                  PIN_E2
#define LCD_E                   PIN_E1
#define LCD_DAT                 PORT_D
//===========================================================================//
//--- output() -----------------/////////////////////////////////////////////// 
//lcd data bus output
void output(int8 port, int8 dat)
{
        switch(port)
                {
                case PORT_A: output_a(dat);      break;
                case PORT_B: output_b(dat);      break;
                case PORT_C: output_c(dat);      break;
                case PORT_D: output_d(dat);      break;
                case PORT_E: output_e(dat);      break;
                default :       //??? port maybe error!
                        break;
                }
}//end output()
//===========================================================================//
//--- lcd_write_cmd() -----------////////////////////////////////////////////// 
void lcd_write_cmd(int8 cmd)
{
   delay_us(40);
   output_low(LCD_RS);
   output_low(LCD_RW);
   output(LCD_DAT, cmd);
   
   output_high(LCD_E);
   delay_us(40);
   output_low(LCD_E);
}//end lcd_write_cmd()
//===========================================================================//
//--- lcd_write_dat() ------------///////////////////////////////////////////// 
void lcd_write_dat(int8 dat)
{
   delay_us(40);
   output_high(LCD_RS);
   output_low(LCD_RW);
   output(LCD_DAT, dat);
   
   output_high(LCD_E);
   delay_us(40);
   output_low(LCD_E);
}//end lcd_write_dat()
//===========================================================================//
//--- lcd_init() ------------////////////////////////////////////////////////// 
void lcd_init(void)
{
   output_low(LCD_E);              // Let LCD E line low
   
   lcd_write_cmd(0x38);            // LCD 16x2, 5x7, 8bits data
   delay_ms(15);
   lcd_write_cmd(0x01);            // Clear LCD display
   delay_ms(10);
   lcd_write_cmd(0x0C);            // Open display & current
   delay_ms(10);
   lcd_write_cmd(0x06);            // Window fixed
   delay_ms(10);
}//end lcd_init()
//===========================================================================//
//--- lcd_display_char() ------------//////////////////////////////////////////
void lcd_display_char(int8 line, int8 pos, int8 ch)
{
        int8 tmp;

        line = (line==0) ? 0 : 1;
        pos  = (pos >NCHAR_PER_LINE) ? NCHAR_PER_LINE : pos;

        tmp = 0x80 + 0x40*line + pos;
        lcd_write_cmd(tmp);
        lcd_write_dat(ch);
}//end lcd_display_char()
//===========================================================================//
//--- lcd_display_str() ------------/////////////////////////////////////////// 
void lcd_display_str(int8 line, char str[])
{
     int8 i;

        for(i=0; i<NCHAR_PER_LINE; i++)
            {
                lcd_display_char(line, i, ' ');
                }
        for(i=0; i<NCHAR_PER_LINE; i++)
                {
                if(str[i] == '\0') break;
                lcd_display_char(line, i, str[i]);
                }
}//end lcd_display_str()
//===========================================================================//
//--- lcd_gotoxy(coluna linha) -----/////////////////////////////////////////// 
void lcd_gotoxy(unsigned int8 x, unsigned int8 y)
{
   unsigned int8 address;
   
   if(y != 1)
      address = 0x40;
   else
      address = 0x00;
     
   address += (x-1);   
   lcd_write_cmd(0x80|address);
}
//===========================================================================//
