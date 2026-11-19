#include "stm32f10x.h"                  // Device header
#include "delay.h"

int main(void)
{
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA,ENABLE);
	
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA,&GPIO_InitStructure);  //GPIO初始化
	
	
	
	while(1)
		{
			for(int i=0;i<
			GPIO_ResetBits(GPIOA,GPIO_Pin_0);
			delay_ms(500);
			GPIO_SetBits(GPIOA,GPIO_Pin_0);
			delay_ms(500);
			GPIO_WriteBit(GPIOA, GPIO_Pin_0,0);
			delay_ms(500);
			GPIO_WriteBit(GPIOA, GPIO_Pin_0,1);
			delay_ms(500);
		}
}
