#include	"Timer.h"

void initTimer2(void){
	//init Timer2 -> stepper X va Y
	TIM2->CR1 &= ~(TIM_CR1_CEN);	
	TIM2->PSC = 9 - 1;
	TIM2->ARR = 25600 - 1;
	TIM2->CR1 |= TIM_CR1_URS;
	TIM2->DIER |= TIM_DIER_UIE;
	TIM2->EGR |= TIM_EGR_UG;
	
	NVIC_EnableIRQ(TIM2_IRQn);
}

void initTimer3(void){
	//init Timer 3 -> PWM Channel 2 PA7 -> servo
	TIM3->CCER |= TIM_CCER_CC2E;	//enable capture, compare
	TIM3->CR1	|= TIM_CR1_ARPE;
	
	//pwm mode 1
	TIM3->CCMR1 |= TIM_CCMR1_OC2M_2 | TIM_CCMR1_OC2M_1;
	TIM3->CCMR1	&= ~TIM_CCMR1_OC2M_0;
	
	TIM3->CCMR1 |= TIM_CCMR1_OC2PE;	//enable preload
	
	TIM3->PSC = 72 - 1;
	TIM3->ARR	= 1000 - 1;
	TIM3->CCR2 = 300 - 1;
	
	TIM3->EGR |= TIM_EGR_UG;
	TIM3->CR1	|= TIM_CR1_CEN;	//enable counter	
}
