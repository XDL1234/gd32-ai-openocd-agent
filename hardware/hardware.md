# 硬件文档

## MCU 信息

- 芯片型号：GD32F470VET6
- 芯片系列：GD32F4xx
- 内核：Cortex-M4
- 主频：168MHz
- Flash：512KB
- SRAM：256KB
- Flash 起始地址：0x08000000
- SRAM 起始地址：0x20000000

## 下载调试接口

- LINK 类型：DAPLink
- 接口协议：SWD
- SWDIO：PA13
- SWCLK：PA14
- NRST：NRST
- GND：GND
- 3V3：3V3
- 默认下载速度：1000 kHz

## 时钟配置

- 外部晶振：8MHz
- HSE：8MHz
- LSE：32.768kHz
- 系统主频：168MHz
- APB1：42MHz
- APB2：84MHz
- ADC 时钟：42MHz

## 外设资源

| 外设 | 用途 | 引脚 | 备注 |
|------|------|------|------|
| USART0 | 调试串口 | PA9/PA10 | 波特率 115200 |
| GPIO | LED | PC13 | 低电平亮 |
| I2C0 | 传感器 | PB6/PB7 | 400kHz |
| SPI0 | Flash | PA5/PA6/PA7 | Mode 0 |

## 串口输出

- 串口号：USART0
- TX：PA9
- RX：PA10
- 波特率：115200
- 数据位：8
- 停止位：1
- 校验：None

## 启动方式

- BOOT0：低电平
- BOOT1：任意
- 默认从 Flash 启动

## 风险限制

- 是否允许全片擦除：否
- 是否允许修改 Option Bytes：否
- 是否允许解除读保护：否
