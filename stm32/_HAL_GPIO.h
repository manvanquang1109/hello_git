#ifndef	_HAL_GPIO
#define _HAL_GPIO

#include "stm32f10x.h"                  // Device header

#define DELAY_1S	for (unsigned int volatile i = 0; i < 500000; i++)
//pin states
#define LOW 0
#define HIGH 1

//port names
#define PORTA	GPIOA
#define PORTB	GPIOB
#define PORTC	GPIOC
#define PORTD	GPIOD
#define PORTE	GPIOE
#define PORTF	GPIOF

//pin modes
#define INPUT_MODE							((uint32_t) 0x00)	//reset state
#define OUTPUT_MODE_SPEED_10MHZ ((uint32_t) 0x01)
#define OUTPUT_MODE_SPEED_2MHZ	((uint32_t) 0x10)
#define OUTPUT_MODE_SPEED_50MHZ ((uint32_t) 0x11)

//input configs
#define INPUT_ANALOG		((uint32_t) 0x00)
#define INPUT_FLOATING	((uint32_t) 0x01)	//reset state
#define INPUT_PU_PD			((uint32_t) 0x02)
#define RESERVED				((uint32_t) 0x03)

//output configs
#define OUTPUT_GEN_PP		((uint32_t) 0x00)
#define OUTPUT_GEN_OD		((uint32_t) 0x01)
#define OUTPUT_AF_PP		((uint32_t) 0x02)
#define OUTPUT_AF_OD		((uint32_t) 0x03)

static uint32_t MODE_BIT0[16] = {
	(0x00),
	(0x04),
	(0x08),
	(0x0C),
	(0x10),
	(0x14),
	(0x18),
	(0x1C),
	(0x00),
	(0x04),
	(0x08),
	(0x0C),
	(0x10),
	(0x14),
	(0x18),
	(0x1C)
};

static uint32_t CNF_BIT0[16] = {
	(0x02),
	(0x06),
	(0x0A),
	(0x0E),
	(0x12),
	(0x16),
	(0x1A),
	(0x1E),
	(0x02),
	(0x06),
	(0x0A),
	(0x0E),
	(0x12),
	(0x16),
	(0x1A),
	(0x1E)	
};

//configuration struction
typedef struct{
	
	GPIO_TypeDef *port;	
	uint32_t	pin;
	uint32_t	mode;
	uint32_t	cnf;
	
}GPIO_TYPE;



//Function prototypes

//gpio configuration
void initGPIO(GPIO_TYPE gpio_type);

//gpio user pin functions
void writePin(GPIO_TypeDef *port, uint32_t pin, uint8_t state);

uint8_t readPin(GPIO_TypeDef *port, uint32_t pin);

void togglePin(GPIO_TypeDef *port, uint32_t pin);

#endif

