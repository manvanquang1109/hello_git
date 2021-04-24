#ifndef _MAIN_H
#define _MAIN_H

#include "stm32f10x.h"                  // Device header

#include <math.h>
#include "_HAL_GPIO.h"
#include "RCC.h"
#include "UART.h"
#include "Timer.h"

//define cac hang so
#define DIS_PER_REV	(float)41.52
#define ANGLE_PER_STEP (float)1.8
#define DURATION_PER_STEP 2	//1ms/1step

#define M_PI acos(-1.0)
#define DND (float)0.1	//distance not draw
	

//define ten cac ports va pins
#define DIR_X_PIN		3
#define DIR_X_PORT	GPIOA
#define	STEP_X_PIN	4
#define STEP_X_PORT	GPIOA

#define DIR_Y_PIN		5
#define	DIR_Y_PORT	GPIOA
#define STEP_Y_PIN	6
#define	STEP_Y_PORT	GPIOA

#define	SERVO_PIN		7
#define SERVO_PORT	GPIOA


//dinh nghia prototypes
static void initClock(void);
static void initGPIOs(void);

void delayMs(uint32_t ms);

static void startButton(void);

void TIM2_IRQHandler(void);

void SysTick_Handler(void);
uint32_t getSysTick(void);

static void moveX(float dx);
static void moveY(float dy);

static void moveXY(float dx, float dy);

static void drawCircle(float r);

static void liftPen(uint8_t pen_up);

static void testDraw(void);

#endif
