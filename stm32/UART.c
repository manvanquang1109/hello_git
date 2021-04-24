#include "UART.h"


//baud rate = 115200
void initUSART1(){
	USART1->BRR = 0x0271;
	USART1->CR1 |= USART_CR1_TE;	//enable transmision
	USART1->CR1	|= USART_CR1_UE;	//enable usart1
}

void printMsg(char *msg, ...){
	char buff[80];
	
	#ifdef DEBUG_UART
	
	va_list args;
	va_start(args, msg);
	vsprintf(buff, msg, args);
	
	for (uint8_t i = 0; i < strlen(buff); i++){
		volatile unsigned char c = buff[i];
		USART1->DR = c;
		while ( !(USART1->SR & USART_SR_TC));
		//delayMs(1);
	}
	
	#endif
}
