#ifndef _UART_H
#define _UART_H

#include "stm32f10x.h"                  // Device header
#include <stdint.h>
#include "string.h"
#include "stdlib.h"
#include "stdarg.h"
#include <stdio.h>
#include "_HAL_GPIO.h"
#include "main.h"

#define DEBUG_UART	UART1

void initUSART1(void);
void printMsg(char *msg, ...);

#endif
