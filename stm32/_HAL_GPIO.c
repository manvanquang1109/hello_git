#include "_HAL_GPIO.h"
#include <stdint.h>

void initGPIO(GPIO_TYPE gpio_type){
	GPIO_TypeDef *port = gpio_type.port;
	uint32_t pin = gpio_type.pin;
	uint32_t mode = gpio_type.mode;
	uint32_t cnf = gpio_type.cnf;
	
	//set 2 bits of MODE
	if (pin >= 8){	//control high register
		switch(mode){
			case INPUT_MODE:
				port->CRH &= ~( (1 << MODE_BIT0[pin]) | (1 << (MODE_BIT0[pin] + 1)) );
			break;
			
			case OUTPUT_MODE_SPEED_10MHZ:
				port->CRH |= (1 << MODE_BIT0[pin]);
				port->CRH &= ~(1 << (MODE_BIT0[pin] + 1));
			break;
			
			case OUTPUT_MODE_SPEED_2MHZ:
				port->CRH &= ~(1 << MODE_BIT0[pin]);
				port->CRH |= (1 << (MODE_BIT0[pin] + 1));
			break;
			
			case OUTPUT_MODE_SPEED_50MHZ:
				port->CRH |= ( (1 << MODE_BIT0[pin]) | (1 << (MODE_BIT0[pin] + 1)) );
			break;			
		}
	}
	else{	//control low register
		switch(mode){
			case INPUT_MODE:
				port->CRL &= ~( (1 << MODE_BIT0[pin]) | (1 << (MODE_BIT0[pin] + 1)) );
			break;
			
			case OUTPUT_MODE_SPEED_10MHZ:
				port->CRL |= (1 << MODE_BIT0[pin]);
				port->CRL &= ~(1 << (MODE_BIT0[pin] + 1));
			break;
			
			case OUTPUT_MODE_SPEED_2MHZ:
				port->CRL &= ~(1 << MODE_BIT0[pin]);
				port->CRL |= (1 << (MODE_BIT0[pin] + 1));
			break;
			
			case OUTPUT_MODE_SPEED_50MHZ:
				port->CRL |= ( (1 << MODE_BIT0[pin]) | (1 << (MODE_BIT0[pin] + 1)) );
			break;			
		}
	}
	
	//set 2 bits of CNF
	if (pin >= 8){	//control high register
		switch(cnf){
			case INPUT_ANALOG | OUTPUT_GEN_PP:
				port->CRH &= ~( (1 << CNF_BIT0[pin]) | (1 << (CNF_BIT0[pin] + 1)) );
			break;
			
			case INPUT_FLOATING | OUTPUT_GEN_OD:
				port->CRH |= (1 << CNF_BIT0[pin]);
				port->CRH &= ~(1 << (CNF_BIT0[pin] + 1));
			break;
			
			case INPUT_PU_PD | OUTPUT_AF_PP:
				port->CRH &= ~(1 << CNF_BIT0[pin]);
				port->CRH |= (1 << (CNF_BIT0[pin] + 1));
			break;
			
			case RESERVED | OUTPUT_AF_OD:
				port->CRH |= ( (1 << CNF_BIT0[pin]) | (1 << (CNF_BIT0[pin] + 1)) );
			break;			
		}
	}
	else{	//control low register
		switch(cnf){
			case INPUT_ANALOG | OUTPUT_GEN_PP:
				port->CRL &= ~( (1 << CNF_BIT0[pin]) | (1 << (CNF_BIT0[pin] + 1)) );
			break;
			
			case INPUT_FLOATING | OUTPUT_GEN_OD:
				port->CRL |= (1 << CNF_BIT0[pin]);
				port->CRL &= ~(1 << (CNF_BIT0[pin] + 1));
			break;
			
			case INPUT_PU_PD | OUTPUT_AF_PP:
				port->CRL &= ~(1 << CNF_BIT0[pin]);
				port->CRL |= (1 << (CNF_BIT0[pin] + 1));
			break;
			
			case RESERVED | OUTPUT_AF_OD:
				port->CRL |= ( (1 << CNF_BIT0[pin]) | (1 << (CNF_BIT0[pin] + 1)) );
			break;			
		}
	}	
}

void writePin(GPIO_TypeDef *port, uint32_t pin, uint8_t state){
	if (state){
		port->BSRR |= (1 << pin);
	}
	else{
		port->BSRR |= (1 << (pin + 16));
	}
}

uint8_t readPin(GPIO_TypeDef *port, uint32_t pin){
	uint8_t state = 0;
	
	state = (uint8_t)( ((port->IDR) & (1 << pin)) >> pin );
	
	return state;
}

void togglePin(GPIO_TypeDef *port, uint32_t pin){
	port->ODR ^= (1 << pin);
}
