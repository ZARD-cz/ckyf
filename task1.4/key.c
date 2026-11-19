#include "stm32f10x.h"
#include "key.h"
#include "delay.h"

void key_init(void){
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB,ENABLE);
	
	GPIO_InitTypeDef GPIO_initstr;
	GPIO_initstr.GPIO_Mode = GPIO_Mode_IPU ; 
	GPIO_initstr.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_11;
	GPIO_initstr.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOB,&GPIO_initstr);
}


uint8_t key_getnum(void){
	uint8_t Keynum = 0;
	if (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_1)==0){
		delay_ms(20);                                       
		Keynum = 1;
		}
	delay_ms(960);
	if (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_1)==0){
			Keynum = 2;
		}
	if (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_1)==0){
	if (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_1)==0){     
			while (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_1)==0); 
	}}
	return Keynum;
}
