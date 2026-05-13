#include "gd32f4xx.h"
#include <stdio.h>

int fputc(int ch, FILE *f)
{
    (void)f;
    usart_data_transmit(USART0, (uint8_t)ch);
    while (RESET == usart_flag_get(USART0, USART_FLAG_TBE))
        ;
    return ch;
}

int fgetc(FILE *f)
{
    (void)f;
    while (RESET == usart_flag_get(USART0, USART_FLAG_RBNE))
        ;
    return (int)usart_data_receive(USART0);
}
