---
name: hardware-analysis
description: 分析硬件文档，提取 MCU、引脚、时钟、外设信息。当需要分析硬件配置时使用。
allowed-tools: Read, Glob, Grep, Write
---

# Hardware Analysis

## 功能概述

本 Skill 提供硬件分析功能：
- 读取硬件文档
- 扫描工程文件
- 识别芯片型号
- 一致性检查
- 生成分析文档

## 前置条件

1. 已创建 `docs/analysis/` 目录
2. 已读取 `hardware/硬件资源表.md`

## 读取硬件文档

```bash
cat hardware/硬件资源表.md
```

提取关键信息：
- 芯片型号
- 芯片系列
- 调试器类型
- 串口配置
- 风险限制

## 扫描工程文件

### 扫描启动文件

```bash
find . -name "startup_*.s" | head -5
```

### 扫描链接脚本

```bash
find . -name "*.ld" | head -5
```

### 扫描头文件

```bash
find . -name "gd32*.h" | head -5
```

### 扫描 CMakeLists.txt

```bash
grep -r "GD32" CMakeLists.txt 2>/dev/null
```

### 扫描 Makefile

```bash
grep -r "GD32" Makefile 2>/dev/null
```

### 扫描源码头文件引用

```bash
grep -r "#include.*gd32" src/ inc/ 2>/dev/null
```

## 识别芯片型号

### 识别规则

| 来源 | 文件/方法 | 识别内容 |
|------|----------|----------|
| 硬件探测 | OpenOCD 读取 DBGMCU_IDCODE | 芯片型号、系列、Flash、SRAM（最精确） |
| 启动文件 | `startup_*.s` | 芯片系列（GD32F10x、GD32F30x 等） |
| 链接脚本 | `*.ld` | Flash/SRAM 大小、起始地址 |
| 头文件 | `gd32*.h` | 芯片系列宏定义 |
| CMakeLists.txt | `CMakeLists.txt` | 芯片型号宏（GD32F103C8T6） |
| 源码 | `main.c` | 头文件引用 |

### 识别优先级

1. **硬件探测（OpenOCD）→ 芯片型号/系列/Flash/SRAM**（最高优先级，直接读芯片寄存器）
2. 启动文件名 → 芯片系列
3. 链接脚本 → Flash/SRAM
4. 头文件 → 芯片系列
5. CMakeLists.txt → 芯片型号
6. 源码头文件引用 → 芯片系列

### 硬件探测（在线识别）

通过 OpenOCD 连接芯片 SWD 接口，读取 DBGMCU_IDCODE 寄存器获取 Device ID：

```bash
bash .gd32-agent/probe-chip.sh
```

探测脚本自动读取以下寄存器：
- DBGMCU_IDCODE（0xE0042000 / 0x40015800）→ 芯片型号和系列
- Flash Size Register（0x1FFF7A22 / 0x1FFFF7E0）→ Flash 大小
- Unique ID（0x1FFF7A10 / 0x1FFFF7E8）→ 芯片唯一标识

结果保存在 `.gd32-agent/probe-result.env`，探测失败时不阻塞流程。

## 一致性检查

将 AI 识别结果与硬件文档对比（含硬件探测结果）：

```markdown
| 项目 | 硬件文档 | 硬件探测 | 工程文件 | 结果 |
|------|----------|----------|----------|------|
| 芯片型号 | ? | ? | ? | 一致/冲突 |
| 芯片系列 | ? | ? | ? | 一致/冲突 |
| Flash | ? | ? | ? | 一致/冲突 |
| SRAM | ? | ? | ? | 一致/冲突 |
```

当三个来源存在冲突时，优先级为：**硬件探测 > 硬件文档 > 工程文件推断**。

## 冲突处理

如果硬件文档与 AI 识别结果冲突：
1. **停止执行**
2. **报告冲突详情**
3. **要求用户确认**
4. **用户确认后继续**

## 生成分析文档

创建 `docs/analysis/project-hardware-analysis.md`：

```markdown
# 工程与硬件分析

## 硬件信息
- MCU：GD32F470VET6
- 调试器：DAPLink
- 串口：USART0 / 115200

## 源码扫描
- 工程类型：IDE（Keil/IAR）
- 启动文件：startup_gd32f470xx.s
- 链接脚本：GD32F470VETx_FLASH.ld

## 一致性检查
| 项目 | 硬件文档 | 源码 | 结果 |
|------|----------|------|------|
| 芯片系列 | GD32F4xx | GD32F4xx | 一致 |
```

## 输出文件

- `docs/analysis/project-hardware-analysis.md` - 硬件分析文档

## 安全规则

- 不修改源代码
- 只读取和分析文件
- 冲突时停止执行
