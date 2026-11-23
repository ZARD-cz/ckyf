#include "stm32f10x.h"
#include "led.h"

void TIM2_Init(int ms){
	TIM_TimeBaseInitTypeDef TIM_TIMBaseStructure;
	NVIC_InitTypeDef    NVIC_InitStructure;
	
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2,ENABLE);
	
	int period = ms *10 -1;
	
	
	TIM_TIMBaseStructure.TIM_Period  =period;
	TIM_TIMBaseStructure.TIM_Prescaler = 7199;
	TIM_TIMBaseStructure.TIM_ClockDivision = TIM_CKD_DIV1;
	TIM_TIMBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TIMBaseStructure.TIM_RepetitionCounter =0;
	TIM_TimeBaseInit(TIM2,&TIM_TIMBaseStructure);
	
	TIM_ClearFlag(TIM2,TIM_FLAG_Update);
	TIM_ITConfig(TIM2,TIM_IT_Update,ENABLE);
	
	NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);
	

}

void TIM2_IRQHandler(void){
	if(TIM_GetITStatus(TIM2,TIM_IT_Update) != RESET)
	{
		TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
		GPIOA->ODR ^=GPIO_Pin_0;
		GPIOA->ODR ^=GPIO_Pin_1;
	}  
}

void LED_init(void){
    GPIO_InitTypeDef GPIO_InitStructure;
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);   
    GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_0 | GPIO_Pin_1;              
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;        
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);
}

