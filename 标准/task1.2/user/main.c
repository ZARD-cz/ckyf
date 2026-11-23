#include "stm32f10x.h"

void TIM2_Init(void){
	TIM_TimeBaseInitTypeDef TIM_TIMBaseStructure;
	NVIC_InitTypeDef    NVIC_InitStructure;
	
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2,ENABLE);
	
	TIM_TIMBaseStructure.TIM_Period  =2499;
	TIM_TIMBaseStructure.TIM_Prescaler = 7199;
	TIM_TIMBaseStructure.TIM_ClockDivision = TIM_CKD_DIV1;
	TIM_TIMBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
	TIM_TimeBaseInit(TIM2,&TIM_TIMBaseStructure);
	
	TIM_ClearFlag(TIM2,TIM_FLAG_Update);
	TIM_ITConfig(TIM2,TIM_IT_Update,ENABLE);
	
	NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);
	
	TIM_Cmd(TIM2,ENABLE);
}

void TIM2_IRQHandler(void){
	if(TIM_GetITStatus(TIM2,TIM_IT_Update) != RESET)
	{
		TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
		GPIOA->ODR ^=GPIO_Pin_0;
	}  
}
int main(void)
{
    
    GPIO_InitTypeDef GPIO_InitStructure;
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);   
    GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_0;              
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;        
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);   //初始化GPIOA      
	
	TIM2_Init();
    while (1)
    {
		
    }
}