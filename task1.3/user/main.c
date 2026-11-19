#include "stm32f10x.h"                  // Device header
#include "led.h"
#include "key.h"

uint8_t KeyNum;

int main(void)
{
	LED_init();
	key_init();
    while (1)
    {
		KeyNum = key_getnum();
		if (KeyNum == 1)
		{
			if (GPIO_ReadOutputDataBit(GPIOA, GPIO_Pin_1) == 1)
			{
				GPIO_ResetBits(GPIOA, GPIO_Pin_1|GPIO_Pin_0);
			}
			else
			{
				GPIO_SetBits(GPIOA, GPIO_Pin_1|GPIO_Pin_0);
			}
		}
	}
	
}