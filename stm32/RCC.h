#ifndef _RCC_H
#define	_RCC_H

#include "stm32f10x.h"                  // Device header

//clock enabling	
#define GPIO_CLOCK_ENABLE_AF		(RCC->APB2ENR |= 1)

#define GPIO_CLOCK_ENABLE_PORTA	(RCC->APB2ENR |= RCC_APB2ENR_IOPAEN)
#define GPIO_CLOCK_ENABLE_PORTB	(RCC->APB2ENR |= RCC_APB2ENR_IOPBEN)
#define GPIO_CLOCK_ENABLE_PORTC	(RCC->APB2ENR |= RCC_APB2ENR_IOPCEN)
#define GPIO_CLOCK_ENABLE_PORTD	(RCC->APB2ENR |= RCC_APB2ENR_IOPDEN)

#define CLOCK_ENABLE_UART1			(RCC->APB2ENR	|= RCC_APB2ENR_USART1EN)

void enableClockForAltFunc(void);
void enableClockForPort(GPIO_TypeDef *port);
void enableClockForUART1(void);
void enableClockForTimer2(void);
void enableClockForTimer3(void);

#endif
