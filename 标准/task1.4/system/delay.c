/**
  ******************************************************************************
  * @file    delay.c
  * @brief   SysTick 精确延时模块（us / ms 级）
  *
  * 实现原理：
  *   - delay_init() 把 SysTick 配置成 1ms 重装载、时钟源 = HCLK、不开启中断；
  *   - delay_us() 轮询 SysTick->VAL 的递减值，累计出需要等待的节拍数，
  *     因此精度只取决于 SystemCoreClock，不受中断影响；
  *   - delay_ms() 由 1ms 累加实现，不受 SysTick 24 位重装载值（最大约 1.6 万 ms）
  *     的限制，可延时任意长度。
  *
  * 移植说明：
  *   1. 把下面【第 1 节】的芯片头文件改成你的芯片/库对应的头文件；
  *   2. 在系统时钟初始化完成之后调用一次 delay_init()；
  *   3. 主频变化后重新调用 delay_init()。
  *
  * 注意：
  *   本模块会把 SysTick 重新配置为“不开中断”的轮询模式。
  *   HAL 库依靠 SysTick 中断维护 HAL_GetTick()/HAL_Delay()，两者不要混用：
  *   HAL 工程请直接用 HAL_Delay()，或参考 README.md 里给出的 DWT 版本。
  ******************************************************************************
  */

/* ===================== 1. 选择芯片头文件（按实际芯片修改） ===================== */
#include "stm32f10x.h"                 /* STM32F1 标准外设库                    */
/* #include "stm32f4xx.h" */           /* STM32F4 标准外设库                    */
/* #include "stm32f1xx_hal.h" */       /* HAL 库（工程已包含对应芯片头文件时用这个）*/

#include "delay.h"

/* ===================== 2. 模块内部变量 ===================== */
/* 1us 对应的 SysTick 节拍数，即 SystemCoreClock / 1000000 */
static uint32_t s_fac_us = 0U;

/* ===================== 3. 模块内部函数 ===================== */

/**
  * @brief  轮询等待指定的 SysTick 节拍数
  * @param  ticks: 需要等待的节拍数，范围 1 ~ (SysTick->LOAD + 1)
  * @retval 无
  * @note   一次等待不能超过一个重装载周期，超出的部分由 delay_us() 分段。
  */
static void delay_ticks(uint32_t ticks)
{
    uint32_t told = SysTick->VAL;              /* 进入时的计数值 */
    uint32_t tnow;
    uint32_t tcnt = 0U;                        /* 已经累计的节拍数 */
    const uint32_t reload = SysTick->LOAD;

    while (tcnt < ticks)
    {
        tnow = SysTick->VAL;
        if (tnow != told)
        {
            if (tnow < told)
            {
                /* 正常递减：VAL 从 told 减到 tnow */
                tcnt += told - tnow;
            }
            else
            {
                /* 跨过一次重装载：
                 * told -> 0 走了 told 拍，0 -> LOAD 占 1 拍，LOAD -> tnow 走 (reload - tnow) 拍 */
                tcnt += (told + 1U) + (reload - tnow);
            }
            told = tnow;
        }
    }
}

/* ===================== 4. 对外函数 ===================== */

/**
  * @brief  延时模块初始化（SysTick：1ms 周期、HCLK 时钟源、不产生中断）
  * @param  无
  * @retval 无
  * @note   SystemCoreClockUpdate() 会按 RCC 的实际配置刷新 SystemCoreClock，
  *         所以只要你的时钟配置正确，延时就是准的。
  */
void delay_init(void)
{
    SystemCoreClockUpdate();                        /* 刷新当前主频 */
    s_fac_us = SystemCoreClock / 1000000U;         /* 1us 需要的节拍数 */

    if (s_fac_us == 0U)                             /* 极低主频兜底，防止死循环 */
    {
        s_fac_us = 1U;
    }

    SysTick->CTRL = 0U;                             /* 先关闭 SysTick */
    SysTick->LOAD = (SystemCoreClock / 1000U) - 1U; /* 1ms 重装载值 */
    SysTick->VAL  = 0U;                             /* 清空当前计数值 */
    /* bit2 CLKSOURCE = 1：时钟源 HCLK
     * bit1 TICKINT   = 0：不产生中断
     * bit0 ENABLE    = 1：启动计数 */
    SysTick->CTRL = 0x00000005U;
}

/**
  * @brief  微秒级延时
  * @param  us: 要延时的微秒数
  * @retval 无
  * @note   内部自动分段，所以任意长度都不会溢出；忘记调用 delay_init() 时会自动初始化。
  */
void delay_us(uint32_t us)
{
    uint32_t max_us;                                /* 单次 delay_ticks 能覆盖的最大 us 数 */

    if (us == 0U)
    {
        return;
    }

    if (s_fac_us == 0U)                             /* 容忍忘记调用 delay_init() */
    {
        delay_init();
    }

    /* 保证 max_us * s_fac_us <= LOAD + 1，避免一次等待超过一个重装载周期 */
    max_us = (SysTick->LOAD + 1U) / s_fac_us;
    if (max_us == 0U)
    {
        max_us = 1U;
    }

    while (us > max_us)
    {
        delay_ticks(max_us * s_fac_us);
        us -= max_us;
    }
    delay_ticks(us * s_fac_us);
}

/**
  * @brief  毫秒级延时
  * @param  ms: 要延时的毫秒数
  * @retval 无
  */
void delay_ms(uint32_t ms)
{
    while (ms > 0U)
    {
        delay_us(1000U);                            /* 1ms 一个周期，逐个累加 */
        ms--;
    }
}
