#include "stm32f10x.h"                  // Device header
#include "led.h"
#include "key.h"

uint8_t KeyNum;

uint8_t Sta =0;

int main(void)
{
	LED_init();
	key_init();
    while (1)
    {
		KeyNum = key_getnum();
		if (KeyNum == 2)
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
	}
}