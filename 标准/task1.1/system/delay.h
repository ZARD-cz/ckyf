/**
  ******************************************************************************
  * @file    delay.h
  * @brief   SysTick 精确延时模块（us / ms 级）
  *
  * 特点：
  *   - 纯轮询实现，不开启 SysTick 中断，因此不需要写 SysTick_Handler，
  *     也不会和启动文件/中断文件里的同名函数冲突；
  *   - 不依赖 HAL 或标准外设库的任何外设驱动，只要芯片头文件即可；
  *   - 移植时只需修改 delay.c 顶部的芯片头文件。
  ******************************************************************************
  */

#ifndef __DELAY_H
#define __DELAY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
  * @brief  延时模块初始化：把 SysTick 配置为 1ms 周期（HCLK 时钟源、无中断）
  * @note   必须在系统时钟初始化完成之后调用一次；
  *         若运行中修改了主频，需要重新调用一次。
  */
void delay_init(void);

/**
  * @brief  毫秒级延时
  * @param  ms: 要延时的毫秒数，0 表示不延时
  */
void delay_ms(uint32_t ms);

/**
  * @brief  微秒级延时
  * @param  us: 要延时的微秒数，0 表示不延时
  */
void delay_us(uint32_t us);

#ifdef __cplusplus
}
#endif

#endif /* __DELAY_H */
