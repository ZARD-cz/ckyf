#ifndef __LED_H
#define __LED_H

void LED_init(void);

void TIM2_Init(int ms);

void TIM2_IRQHandler(void);

#endif
