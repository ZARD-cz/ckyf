ckyf
将军路 182612021 蔡忠瀚



第一次作业
task1.1 main.c: 先开GPIOA时钟、PA0设置推挽输出，50MHz；while循环开250ms秒，灭250ms；

task1.2：TIM2每250ms中断翻PA0。main.c里GPIO初始化+TIM2_Init+空循环；

task1.3：led.c 和key.c中设置了GPIO初始化函数和按键输入初始化函数。main.c中LED_init+key_init，进行GPIOA0初始化和按键检测初始化，进行20ms消抖后确定按下按钮输出1，输出为1则反转GPIOA0状态。

task1.4：短按翻PA0，长按启停200ms周期闪烁。main.c中初始化+键值执行，按键输出1则反转GPIOA0状态，输出2则开关闪烁；key_在key.c，LED_init，TIM2_Init在led/led.c。

task1.5：双击翻PA0。main.c中初始化+键值2翻转；key_getnum在key.c，LED_init在led/led.c。