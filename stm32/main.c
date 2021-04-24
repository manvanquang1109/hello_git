#include "main.h"

static volatile uint32_t my_tick = 0;
static volatile uint32_t sys_tick = 0;
static volatile uint32_t time = 0;

static volatile float step_x = 0;
static volatile float step_y = 0;

static volatile float step_x10 = 0;
static volatile float step_y10 = 0;

static volatile float step_x_i10 = 0;
static volatile float step_y_i10 = 0;

static volatile uint8_t x_only = 0;
static volatile uint8_t y_only = 0;

int main(){
	SysTick_Config(SystemCoreClock / 1000);	
	initClock();
	initGPIOs();
	
	initUSART1();
//	printMsg("Chao %.2lf ban\n", step_x);
	
	initTimer2();
	
	initTimer3();
	
	liftPen(1);
	
	writePin(PORTC, 13, 0);	
	startButton();	
	togglePin(GPIOC, 13);

	testDraw();
	
	//writePin(GPIOA, 4, 0);
	while(1){
	}
}

static void initClock(){
	enableClockForPort(PORTC);
	
	enableClockForTimer2();
	enableClockForTimer3();
	
	enableClockForAltFunc();
	enableClockForPort(GPIOA);
	enableClockForUART1();
}

static void initGPIOs(){
	GPIO_TYPE my_gpio;
	
	//led
	my_gpio.port = PORTC;
	my_gpio.pin = 13;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_GEN_PP;
	
	initGPIO(my_gpio);
	
	//button
	my_gpio.port = PORTA;
	my_gpio.pin = 0;
	my_gpio.mode = INPUT_MODE;
	my_gpio.cnf = INPUT_PU_PD;
	GPIOA->ODR |= 1;
	
	initGPIO(my_gpio);

	//dir_x_pin
	my_gpio.port = DIR_X_PORT;
	my_gpio.pin = DIR_X_PIN;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_GEN_PP;
	
	initGPIO(my_gpio);
	
	//step_x_pin
	my_gpio.port = STEP_X_PORT;
	my_gpio.pin = STEP_X_PIN;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_GEN_PP;
	
	initGPIO(my_gpio);
	
	//dir_y_pin
	my_gpio.port = DIR_Y_PORT;
	my_gpio.pin = DIR_Y_PIN;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_GEN_PP;
	
	initGPIO(my_gpio);
	
	//step_y_pin
	my_gpio.port = STEP_Y_PORT;
	my_gpio.pin = STEP_Y_PIN;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_GEN_PP;
	
	initGPIO(my_gpio);	
	
	//uart1 PA9 Tx
	my_gpio.port = GPIOA;
	my_gpio.pin = 9;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_AF_PP;
	
	initGPIO(my_gpio);
	
	//servo PWM PA7
	my_gpio.port = SERVO_PORT;
	my_gpio.pin = SERVO_PIN;
	my_gpio.mode = OUTPUT_MODE_SPEED_10MHZ;
	my_gpio.cnf = OUTPUT_AF_PP;
	
	initGPIO(my_gpio);
}

void delayMs(uint32_t ms){
	time = sys_tick;		
	while ((sys_tick - time) < ms);
}

void SysTick_Handler(void){
	sys_tick++;
}

uint32_t getSysTick(void){
	return sys_tick;
}

void TIM2_IRQHandler(void){
	
	if (TIM2->SR & TIM_SR_UIF){
		my_tick++;
		
		if (x_only == 0 && y_only == 0){
		
			if (my_tick % (unsigned int)step_y10 == 0){
				togglePin(STEP_X_PORT, STEP_X_PIN);	//step_x_pin
				step_x_i10 += 5;
			}
			//printMsg("line = %d. my_tick = %d, step_x_i = %.1lf, step_x = %.1lf\n", line++, my_tick, step_x_i, step_x);
			
			if (my_tick % (unsigned int)step_x10 == 0)
				togglePin(STEP_Y_PORT, STEP_Y_PIN);	//step_y_pin
		
		}
		
		else{
			
			if (x_only == 1){
				if (my_tick % 48 == 0){
					togglePin(STEP_X_PORT, STEP_X_PIN);
					step_x_i10 += 5;
				}
			}

			else if (y_only == 1){
				if (my_tick % 48 == 0){
					togglePin(STEP_Y_PORT, STEP_Y_PIN);
					step_y_i10 += 5;
				}
			}
			
		}
	}
	
	TIM2->SR &= ~(TIM_SR_UIF);
	
}

static void startButton(void){
	while(readPin(GPIOA, 0)){
		delayMs(100);
		if (!readPin(GPIOA, 0)){
			delayMs(100);
			break;
		}
	}
}

static void moveX(float dx){
	x_only = 1;
	
	//set gia tri ARR dua tren tich |dx| * 1
	float dx_abs = (float)fabs((double)dx);
	uint16_t psc_value = TIM2->PSC;
	uint16_t arr_value = (uint16_t)(120000 / (float)(psc_value + 1) / dx_abs) - 1;
	TIM2->ARR = arr_value;
	
	//chon chieu quay stepper X
	if (dx > 0){
		writePin(DIR_X_PORT, DIR_X_PIN, 0);
	}
	else{
		writePin(DIR_X_PORT, DIR_X_PIN, 1);
	}
	
	step_x = (360 / DIS_PER_REV) * dx_abs / ANGLE_PER_STEP;
	
	step_x10 = roundf(step_x * 10);
	
	my_tick = 0;
	step_x_i10 = 0;
	
	TIM2->CR1 |= TIM_CR1_CEN;
	
	while (step_x_i10 < step_x10);
	
	TIM2->CR1 &= ~(TIM_CR1_CEN);
	
	x_only = 0;
	
	delayMs(20);
}

static void moveY(float dy){
	y_only = 1;
	
	//set gia tri ARR dua tren tich |dy| * 1
	float dy_abs = (float)fabs((double)dy);
	uint16_t psc_value = TIM2->PSC;
	uint16_t arr_value = (uint16_t)(120000 / (float)(psc_value + 1) / dy_abs) - 1;
	TIM2->ARR = arr_value;
	
	//chon chieu quay stepper Y
	if (dy > 0){
		writePin(DIR_Y_PORT, DIR_Y_PIN, 0);
	}
	else{
		writePin(DIR_Y_PORT, DIR_Y_PIN, 1);
	}
	
	step_y = (360 / DIS_PER_REV) * dy_abs / ANGLE_PER_STEP;
	
	step_y10 = roundf(step_y * 10);
	
	my_tick = 0;
	step_y_i10 = 0;
	
	TIM2->CR1 |= TIM_CR1_CEN;
	
	while (step_y_i10 < step_y10);
	
	TIM2->CR1 &= ~(TIM_CR1_CEN);
	
	y_only = 0;
	
	delayMs(20);
}

static void moveXY(float dx, float dy){

	float dx_abs = (float)fabs((double)dx);
	float dy_abs = (float)fabs((double)dy);
	
	//xet gia tri dx, dy xem co ve khong
	if (dx_abs < DND || dy_abs < DND){
		
		if (dx_abs >= DND && dy_abs < DND){
			moveX(dx);
		}
		else if (dx_abs < DND && dy_abs >= DND){
			moveY(dy);
		}
		else if (dx_abs < DND && dy_abs < DND){
			//not drawing
		}
		
	}
	
	else{
		//set gia tri ARR dua tren tich |dx| * |dy|
		uint16_t psc_value = TIM2->PSC;
		uint16_t arr_value = (uint16_t)(120000 / (float)(psc_value + 1) / dx_abs / dy_abs) - 1;
		TIM2->ARR = arr_value;
	
		//chon chieu quay cua stepper motors dua vao gia tri dx, dy
		if (dx > 0){
			writePin(DIR_X_PORT, DIR_X_PIN, 0);
		}
		else{
			writePin(DIR_X_PORT, DIR_X_PIN, 1);
		}
		
		if (dy > 0){
			writePin(DIR_Y_PORT, DIR_Y_PIN, 0);
		}
		else{
			writePin(DIR_Y_PORT, DIR_Y_PIN, 1);
		}
		
		step_x = (360 / (float)DIS_PER_REV) * dx_abs / (float)ANGLE_PER_STEP;
		step_y = (360 / (float)DIS_PER_REV) * dy_abs / (float)ANGLE_PER_STEP;
		
		step_x10 = roundf(step_x * 10);
		step_y10 = roundf(step_y * 10);
		
		my_tick = 0;
		step_x_i10 = 0;
		step_y_i10 = 0;
		
		TIM2->CR1 |= TIM_CR1_CEN;
		
		while (step_x_i10 < step_x10);
		
		TIM2->CR1 &= ~(TIM_CR1_CEN);
		
		togglePin(GPIOC, 13);
		
		delayMs(20);
	}
}

static void drawCircle(float r){
	static volatile float x = 0;
	static volatile float y = 0;

	static volatile float pre_x = 0;
	static volatile float pre_y = 0;
	
	volatile float dx = 0;
	volatile float dy = 0;
	
	for (volatile float i = 0; i <= 180; i = i + 10){
		x = r * (float)cos( (double)( i * (float)(M_PI / 180) ) );
		y = r * (float)sin( (double)( i * (float)(M_PI / 180) ) );
		
		if (i > 0){
			dx = x - pre_x;
			dy = y - pre_y;
			
			moveXY(dx, dy);
		}
		
		pre_x = x;
		pre_y = y;
	}
	
	delayMs(20);
}

static void liftPen(uint8_t pen_up){
	if (pen_up){
		for (volatile uint16_t duty = 85; duty >= 50; duty -= 5){
			TIM3->CCR2 = duty * 10;
			delayMs(20);
		}
	}
	else{
		for (volatile uint16_t duty = 50; duty <= 85; duty += 5){
			TIM3->CCR2 = duty * 10;
			delayMs(20);
		}
	}
	
	delayMs(20);
}

static void testDraw(void){
	
//	for (volatile uint16_t i = 0; i < 3; i++){
//		liftPen(0);
//		
//		moveXY(30, -30);
//		
//		moveXY(0, 15);
//		
//		liftPen(1);
//		
//		moveXY(-30, 15);
//		
//	}
	
	liftPen(0);
	drawCircle(40);
	
	liftPen(1);
	moveXY(40, 0);
	
	liftPen(0);
	drawCircle(30);
	
}

