#include "stm32f10x.h"                  // Device header
#include "led.h"
#include "key.h"

uint8_t KeyNum;

uint8_t Sta =0;

int main(void)
{
	LED_init();
	key_init();
	TIM2_Init(100);
    while (1)
    {
		KeyNum = key_getnum();
		if (KeyNum == 1)
		{
			if (GPIO_ReadOutputDataBit(GPIOA, GPIO_Pin_0) == 1)
			{
				GPIO_ResetBits(GPIOA, GPIO_Pin_0);
			}
			else
			{
				GPIO_SetBits(GPIOA, GPIO_Pin_0);
			}
		}
		if(KeyNum == 2){
			if(Sta==0){Sta =1;}
			else {Sta = 0;
			TIM_Cmd(TIM2, DISABLE);
			GPIO_SetBits(GPIOA, GPIO_Pin_0);}
		}
			
		if(Sta == 1){
				TIM_Cmd(TIM2,ENABLE);;
		}		
	
}
	
}