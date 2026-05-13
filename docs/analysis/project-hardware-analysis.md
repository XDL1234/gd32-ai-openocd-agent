# 工程与硬件分析

## 硬件信息

- MCU：GD32F470VET6
- 芯片系列：GD32F4xx
- 内核：Cortex-M4
- 主频：168MHz
- Flash：512KB
- SRAM：256KB
- 调试器：DAPLink
- 串口：USART0 / 115200

## 源码扫描

### 工程类型

- HAL_Library：STM32CubeMX 生成的 HAL 库工程
- Standard_Library：标准库工程

### 启动文件

- HAL_Library：startup_stm32f429xx.s
- Standard_Library：startup_gd32f450_470.s

### 链接脚本

- HAL_Library：GD32_Demo.sct（Keil scatter 文件）
- Standard_Library：gd32f470zk_flash.ld（bootloader 配置）

### 头文件

- gd32f4xx.h（GD32F4xx 系列）
- gd32f4xx_libopt.h（库配置）

## 一致性检查

| 项目 | 硬件文档 | 源码 | 结果 |
|------|----------|------|------|
| 芯片系列 | GD32F4xx | GD32F4xx | 一致 |
| Flash | 512KB | 512KB | 一致 |
| SRAM | 256KB | 192KB | 部分一致 |
| 启动文件 | GD32F450/470 | GD32F450/470 | 一致 |

## 风险点

1. HAL_Library 使用 startup_stm32f429xx.s，可能与 GD32F470 不完全兼容
2. Standard_Library 的链接脚本是 bootloader 配置（Flash 32K），不是完整芯片配置
3. SRAM 配置不一致，硬件文档显示 256KB，scatter 文件显示 192KB

## 建议

1. HAL_Library 应使用 GD32F470 的启动文件
2. Standard_Library 的链接脚本应更新为完整芯片配置
3. 确认 SRAM 配置是否正确
