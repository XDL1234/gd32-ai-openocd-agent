# GD32 AI Agent 完整说明文档

> 本文档仅供个人查阅，不提交到 GitHub。
> 最后更新：2026-05-14

---

## 目录

1. [项目概述](#1-项目概述)
2. [安装与初始化](#2-安装与初始化)
3. [指令层级架构](#3-指令层级架构)
4. [Skills 体系总览](#4-skills-体系总览)
5. [embedded-dev Skill 详解](#5-embedded-dev-skill-详解)
6. [gd32-openocd Skill 详解](#6-gd32-openocd-skill-详解)
7. [hardware-analysis Skill 详解](#7-hardware-analysis-skill-详解)
8. [RIPER-5 工作流程详解](#8-riper-5-工作流程详解)
9. [四文件磁盘工作记忆机制](#9-四文件磁盘工作记忆机制)
10. [多 Agent 分工协作](#10-多-agent-分工协作)
11. [扩展模式](#11-扩展模式)
12. [参考文档库 (refs/)](#12-参考文档库-refs)
13. [.gd32-agent 脚本工具集](#13-gd32-agent-脚本工具集)
14. [Hooks 系统](#14-hooks-系统)
15. [辅助工具调用规范](#15-辅助工具调用规范)
16. [Git 备份与回档规则](#16-git-备份与回档规则)
17. [安全规则](#17-安全规则)
18. [会话恢复机制](#18-会话恢复机制)
19. [GD32F470VET6 工程模板](#19-gd32f470vet6-工程模板)
20. [config.env 配置说明](#20-configenv-配置说明)
21. [常见问题与紧急情况处理](#21-常见问题与紧急情况处理)
22. [完整触发词速查表](#22-完整触发词速查表)
23. [快捷指令](#23-快捷指令)
24. [任务分级](#24-任务分级)
25. [跨平台支持](#25-跨平台支持)

---

## 1. 项目概述

GD32 AI Agent 是一个基于 Claude Code 的自动化嵌入式开发工具，专为 GD32 系列芯片开发设计。它通过 Claude Code 的 Skills 体系、自定义 Shell 脚本和结构化开发协议（RIPER-5），实现从需求分析到编译烧录验证的全流程自动化。

### 核心能力

| 能力 | 说明 |
|------|------|
| 自动识别 | 扫描工程文件，自动识别芯片型号、固件库类型、工程结构 |
| 环境配置 | 自动检测 OpenOCD、GDB、GCC 等工具链路径 |
| 文档生成 | 自动生成硬件资源表、编辑清单、研究发现、项目规划清单 |
| 编译烧录 | 一键编译（CMake/Make/Keil/IAR）、烧录（OpenOCD）、调试（GDB） |
| 证据优先 | 所有完成声明必须有编译输出、串口日志等客观证据 |
| 多 Agent | 复杂任务自动拆分为 Scout（侦察）→ Builder（构建）→ Verifier（验证）三角色 |
| 轮次制 | 每轮只解决一个改动点，带 trace_id 追踪，失败可精确回退 |

### 支持的芯片平台

| 平台 | 典型芯片 | 默认推荐框架 | 备选框架 |
|------|---------|-------------|---------|
| **GD32** | GD32F103、GD32F303、GD32F470 | GD32 标准库 | 直接寄存器操作 |
| **STM32** | STM32F103、STM32F407、STM32H743 | 标准外设库（StdPeriph） | HAL/LL 库 |
| **ESP32** | ESP32、ESP32-S3、ESP32-C3 | ESP-IDF | Arduino 框架 |
| **Arduino** | ATmega328P、ATmega2560 | Arduino 框架 | 直接寄存器操作 |
| **RISC-V** | GD32VF103、CH32V307 | 厂商 SDK | 直接寄存器操作 |
| **NXP** | LPC1768、i.MX RT | MCUXpresso SDK | CMSIS |
| **TI MSP430** | MSP430F5529、MSP430G2553 | DriverLib | 直接寄存器操作 |
| **国产芯片** | CH32、AT32、APM32 | 厂商标准库 | HAL 兼容层 |

#### GD32 系列 OpenOCD 兼容性

| 系列 | OpenOCD Target（兼容） | 自动扫描识别 | 状态 |
|------|----------------------|:---:|------|
| GD32F1xx | stm32f1x.cfg | ✅ | 完整支持 |
| GD32F3xx | stm32f3x.cfg | ✅ | 完整支持 |
| GD32F4xx | stm32f4x.cfg | ✅ | 完整支持 |
| GD32E2xx | stm32f0x.cfg | ✅ | 完整支持 |
| GD32VF103 | — | ❌ | RISC-V 架构，需手动配置 OpenOCD |

### 支持的调试器

| 调试器 | OpenOCD interface | 协议 |
|--------|-------------------|------|
| ST-LINK | stlink.cfg | SWD / JTAG |
| DAPLink | cmsis-dap.cfg | SWD |
| J-Link | jlink.cfg | SWD / JTAG |

### 支持的工程类型

- CMake
- Make (ARM GCC Makefile)
- Keil MDK (.uvprojx)
- IAR (.ewp)

---

## 2. 安装与初始化

### 2.1 前置条件

- 已安装 [Claude Code](https://claude.ai/code)（CLI 或桌面版）
- 已安装 ARM GCC 工具链（`arm-none-eabi-gcc`、`arm-none-eabi-gdb`）
- 已安装 OpenOCD（推荐 xpack-openocd 0.12.0+）
- 有一个 GD32 工程目录

### 2.2 安装步骤

#### 第一步：克隆 gd32-agent 仓库

```bash
# 克隆到任意位置（如 D:\tools\gd32-agent）
git clone https://github.com/XDL1234/gd32-agent.git
```

#### 第二步：进入你的 GD32 工程目录，运行安装脚本

```bash
cd /path/to/your-gd32-project
bash /path/to/gd32-agent/install.sh
```

**install.sh 做了什么：**

1. 检查是否在 gd32-agent 仓库目录运行（禁止在仓库目录直接运行）
2. 检查是否已安装（已安装则提示是否覆盖）
3. 检测操作系统（Windows/Linux/macOS）
4. 创建目录结构：
   - `.gd32-agent/logs/` — Agent 脚本和日志
   - `hardware/` — 硬件文档
   - `workflow/` — 开发流程
   - `docs/{analysis,tasks,reviews,bugs,testing}` — 文档目录
   - `.claude/commands/gd32-agent/` — Claude 命令
   - `.claude/skills/` — Skills 目录
5. 复制 `.gd32-agent/` 下所有脚本（check-env.sh、scan-project.sh、build.sh、flash.sh、serial.sh、debug.sh、debug-loop.sh、detect-serial.sh、probe-chip.sh、gd32-chip-db.sh 等）
6. 复制 Claude 命令（`init.md`）
7. 复制 Skills（gd32-openocd、hardware-analysis、document-skills、superpowers-skills）
8. 复制 `embedded-dev/` Skill 目录（RIPER-5 完整协议）
9. 复制 `CLAUDE.md`（如果不存在）
10. 复制四文件模板（硬件资源表.md、编辑清单.md、研究发现.md、项目规划清单.md）
11. 自动检测 OpenOCD 路径并写入 `config.env`
12. 运行环境检查（`check-env.sh`）

#### 第三步：编辑硬件文档

编辑 `hardware/硬件资源表.md`，填写你的硬件信息（表格形式）：

```markdown
## MCU 信息

| 参数 | 值 |
|------|------|
| 芯片型号 | GD32F470VET6 |
| 芯片系列 | GD32F4xx |

## 下载调试接口

| 参数 | 值 |
|------|------|
| LINK 类型 | DAPLink |
| 接口协议 | SWD |

## 串口输出

| 参数 | 值 |
|------|------|
| 串口号 | USART0 |
| TX | PA9 |
| RX | PA10 |
| 波特率 | 115200 |
```

#### 第四步：在 Claude Code 中初始化

打开 Claude Code，输入以下任一指令：

```
gd32-agent init
```

或者直接说：

```
初始化这个 GD32 工程
```

### 2.3 init 指令详细流程

`gd32-agent init` 对应 `.claude/commands/gd32-agent/init.md`，执行以下步骤：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 0 | 会话恢复检测 | 如果存在四文件，执行静默恢复（读取四文件 → 展示简短摘要 → 询问继续还是新任务） |
| 1 | 环境检查 | `bash .gd32-agent/check-env.sh`，检查 OpenOCD、GCC、GDB、Make、Python 等工具 |
| 2 | 工程扫描与自动配置 | `bash .gd32-agent/scan-project.sh` + 交互确认调试器、串口、芯片型号，自动回填 config.env 和 openocd.cfg |
| 2.5 | 芯片硬件探测 | `bash .gd32-agent/probe-chip.sh`，通过 OpenOCD 读取 DBGMCU_IDCODE / Flash / UID，与工程扫描结果交叉验证 |
| 3 | 生成扫描报告 | 输出识别到的芯片型号、系列、固件库类型、工程类型 |
| 4 | 用户确认 | 展示扫描结果，请用户确认或修正 |
| 5 | 创建目录结构 | 确保所有必要目录存在 |
| 6 | 生成文档 | 根据扫描结果生成/更新硬件资源表、开发流程文档等 |
| 7 | 完成报告 | 输出初始化完成报告，列出可执行的操作 |

**步骤 0 静默恢复格式**：

```
📋 会话恢复
- 当前阶段：[从项目规划清单提取]
- 上次工作：[从编辑清单提取最后修改]
- 芯片：[从硬件资源表提取] + [调试器]
- 进度：[已完成/进行中模块]
继续上次的工作还是开始新任务？
```

### 2.4 开始开发

初始化完成后，直接用自然语言告诉 Claude 你要做什么：

```
帮我实现 USART0 打印启动日志，并烧录验证
```

Claude 会自动按照 RIPER-5 协议执行完整开发流程。

---

## 3. 指令层级架构

本 Agent 采用三层指令层级，越高层级权限越大：

```
L1 — CLAUDE.md（顶层）
 │   每次会话自动加载
 │   内容：安全红线 + 路径配置 + 核心流程 + Skills 入口
 │   约 150 行，精简摘要
 │
 ├── L2 — embedded-dev/SKILL.md（中间层）
 │     Skill 触发时加载
 │     内容：完整 RIPER-5 开发协议
 │     包含：芯片识别、五个模式详情、辅助工具规范、代码处理指南
 │     约 520 行
 │
 └── L3 — embedded-dev/refs/（底层）
       按需加载的参考文档（17 个文件）
       内容：API 速查、清单模板、工作流、故障排查等
       总计约 5000+ 行
```

**冲突处理规则**：
- L1 与 L2 冲突 → 以 L2 为准（L1 只是摘要）
- L2 与 L3 冲突 → 以 L2 为准
- 任何层级与 `hardware/硬件资源表.md` 冲突 → 停止执行，报告用户

---

## 4. Skills 体系总览

### 什么是 Skill

Skill 是 Claude Code 的扩展能力模块。每个 Skill 是一个包含 `SKILL.md` 的目录，放在 `.claude/skills/` 或项目根目录下。SKILL.md 使用 YAML frontmatter 定义元数据（名称、描述、触发词、钩子），正文定义执行规则。

当用户消息中包含触发词时，Claude 自动加载对应 Skill 的完整规则。

### 本项目的 Skills

| Skill | 位置 | 触发方式 | 功能 |
|-------|------|---------|------|
| **embedded-dev** | `embedded-dev/SKILL.md` | 58 个触发词自动触发 | RIPER-5 完整开发协议 |
| **gd32-openocd** | `.claude/skills/gd32-openocd/SKILL.md` | 手动触发（编译/烧录/调试相关） | 编译、烧录、调试、串口 |
| **hardware-analysis** | `.claude/skills/hardware-analysis/SKILL.md` | 手动触发（硬件分析相关） | 硬件文档读取 + 工程扫描 + 一致性检查 |
| **document-skills** | `.claude/skills/document-skills/` | "pdf"、"word"、"ppt"、"excel" 等 | PDF/Word/PPT/Excel 文档读取与处理 |
| **superpowers-skills** | `.claude/skills/superpowers-skills/` | "调试"、"头脑风暴"、"写计划" 等 | 系统化调试、头脑风暴、计划编写、并行 Agent |

> **强制规则**：所有 PDF、Word、PPT、Excel 文档的读取、提取、分析必须通过 document-skills 执行，禁止使用其他方式替代。

#### document-skills 子 Skill

| 子 Skill | 触发词 | 功能 |
|----------|--------|------|
| pdf | "pdf"、"读PDF" | PDF 读取、提取、合并、OCR |
| docx | "word"、"docx"、"文档" | Word 文档创建、读取、编辑 |
| pptx | "ppt"、"幻灯片" | PPT 演示文稿处理 |
| xlsx | "excel"、"表格" | Excel 表格处理 |

#### superpowers-skills 子 Skill

| 子 Skill | 触发词 | 功能 |
|----------|--------|------|
| systematic-debugging | "调试"、"排查"、"bug" | 系统化根因分析调试 |
| brainstorming | "头脑风暴"、"方案设计" | 头脑风暴 / 方案设计 |
| writing-plans | "写计划"、"任务拆解" | 多步骤任务计划编写 |
| verification-before-completion | "验证完成"、"验收" | 完成前验证 |
| dispatching-parallel-agents | "并行"、"多Agent" | 并行 Agent 调度 |

### Skill 文件结构

```yaml
---
name: skill-name
description: "描述"
triggers:
  - "触发词1"
  - "触发词2"
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "用户提交消息时执行的命令"
  PreToolUse:
    - matcher: "Write|Edit|Bash"
      hooks:
        - type: command
          command: "工具执行前运行的命令"
  PostToolUse:
    - matcher: "Write|Edit|Bash"
      hooks:
        - type: command
          command: "工具执行后运行的命令"
---
# Skill 正文（执行规则）
```

---

## 5. embedded-dev Skill 详解

### 5.1 基本信息

- **文件位置**：`embedded-dev/SKILL.md`
- **名称**：embedded-dev
- **描述**：RIPER-5 嵌入式芯片开发协议
- **触发词数量**：58 个（见[第22节完整列表](#22-完整触发词速查表)）

### 5.2 58 个触发词完整列表

```
嵌入式, 单片机, STM32, GD32, ESP32, Arduino, RISC-V, 固件, 外设,
中断, GPIO, UART, SPI, I2C, DMA, 定时器, ADC, PWM, HAL, StdPeriph,
ESP-IDF, Keil, 寄存器, MCU, 芯片开发, firmware, embedded, microcontroller,
CAN, USB, RTOS, FreeRTOS, Bootloader, 低功耗, 看门狗, 烧录, JTAG, SWD,
驱动移植, 查手册, 查数据手册, datasheet, 启用比赛模式, 逐飞, seekfree,
英飞凌库, 网表, netlist, 读网表, 查网表, 检查工具, 检查mcp, 测试工具,
mcp检查, 工具诊断, healthcheck, check tools, 检查所有mcp工具
```

**这意味着**：当你在 Claude Code 中提到上述任何一个词（如"帮我配置 GPIO"、"GD32 的 UART 怎么初始化"、"烧录到板子上"），Claude 会自动加载 embedded-dev Skill 的完整 RIPER-5 协议。

### 5.3 核心能力

1. **RIPER-5 五阶段开发流程**（见[第8节](#8-riper-5-工作流程详解)）
2. **四文件磁盘工作记忆**（见[第9节](#9-四文件磁盘工作记忆机制)）
3. **多 Agent 分工协作**（见[第10节](#10-多-agent-分工协作)）
4. **证据优先原则**（见[第8.5节 REVIEW 模式](#85-模式5review审查)）
5. **Git 自动存档与回档**（见[第16节](#16-git-备份与回档规则)）
6. **5 种扩展模式**（见[第11节](#11-扩展模式)）
7. **辅助工具调用规范**（见[第15节](#15-辅助工具调用规范)）

### 5.4 Vibe 执行壳

embedded-dev Skill 融合了 `how-to-vibecoding` 的方法论，但保留了嵌入式专用规则：

1. **不承担全局路由职责**：只有主交付物是固件/硬件/驱动时才持有执行权
2. **主卡片负责路由与门控**：长任务模板、角色分工在 `refs/vibe-workflow.md`
3. **结论必须晚于证据**：没有日志/编译输出/测试结果时禁止宣称完成
4. **跨多文件默认走轮次制**：每轮一个改动点
5. **并行时强制单写者**：Scout 和 Verifier 只读，同时只允许一个 Builder 写入
6. **交接必须压缩上下文**：跨轮次或跨 Agent 只传结构化摘要

### 5.5 语言设置

- 常规回复：中文
- 模式声明（`[MODE: RESEARCH]`）：英文
- 技术协议术语：英文
- 代码注释：中文
- 默认禁用 emoji

---

## 6. gd32-openocd Skill 详解

### 6.1 基本信息

- **文件位置**：`.claude/skills/gd32-openocd/SKILL.md`
- **名称**：gd32-openocd
- **功能**：编译、烧录、调试、串口监控

### 6.2 编译功能

根据工程类型自动选择编译方式：

| 工程类型 | 编译命令 |
|---------|---------|
| CMake | `mkdir -p build && cd build && cmake .. && make` |
| Make | `make clean && make` |
| Keil | `UV4 -b project.uvprojx -o build.log` |
| IAR | `iarbuild project.ewp -build Release` |

统一调用：`bash .gd32-agent/build.sh`

### 6.3 烧录功能

使用 OpenOCD 烧录固件：

```bash
bash .gd32-agent/flash.sh build/app.hex
```

烧录前自动检查：
1. OpenOCD 配置文件是否存在
2. 固件文件是否存在
3. 调试器连接是否正常

### 6.4 串口监控

```bash
bash .gd32-agent/serial.sh COM15 115200 10
# 参数：端口 波特率 超时秒数
```

### 6.5 寄存器调试

debug.sh 支持 3 种模式：

#### 模式 1：通用寄存器转储（默认）

```bash
bash .gd32-agent/debug.sh build/app.elf
```

使用 GDB + OpenOCD 连接目标，暂停 CPU 后读取所有通用寄存器（r0-r15、xPSR、MSP、PSP 等），输出到 Markdown 格式文件。

#### 模式 2：指定外设寄存器读取

```bash
bash .gd32-agent/debug.sh --periph 0x40011000 16 build/app.elf
# 参数：--periph <基地址> [寄存器数量，默认8] <固件.elf>
```

使用 OpenOCD 的 `mdw`（Memory Display Word）命令直接读取外设寄存器。例如读取 USART0（基地址 0x40011000）的前 16 个寄存器。

#### 模式 3：批量读取多个外设

```bash
bash .gd32-agent/debug.sh --batch .gd32-agent/periph-addrs.txt build/app.elf
```

从地址文件中读取多个外设的寄存器，地址文件格式：

```
# 基地址 外设名称
0x40021000 RCU
0x40020C00 GPIOA
0x40011000 USART0
```

### 6.6 自动调试循环（Bug 定位模式）

当用户报告 Bug 或 Agent 发现功能异常时，进入自动调试循环。

#### 核心铁律

1. **禁止凭空捏造**：所有关于寄存器值、外设状态、运行结果的判断，必须来自 OpenOCD/GDB 实际读取或串口实际输出，禁止使用"应该是"、"理论上"、"根据经验"等猜测性表述
2. **证据驱动**：每一轮修复必须附带完整证据链（编译日志 + 烧录日志 + 寄存器转储 + 串口输出）
3. **自动执行**：编译、烧录、寄存器读取、串口观察全程自动执行，无需用户逐步确认权限
4. **循环直到解决**：修改代码后自动重新执行调试循环，直到 Bug 被证据确认已修复

#### 自动调试流程

```
发现Bug → 分析代码 → 确定需要监测的外设寄存器
    → 生成 periph-addrs.txt（外设基地址列表）
    → 修改代码
    → 自动执行 debug-loop.sh（编译→烧录→寄存器读取→串口观察）
    → 读取证据文件，分析根因
    → Bug 未修复？→ 继续修改代码 → 重新执行循环
    → Bug 已修复？→ 输出完整证据报告
```

#### 执行命令

```bash
# 一键调试循环（自动编译→烧录→寄存器→串口）
bash .gd32-agent/debug-loop.sh [串口超时秒数] [外设地址文件]

# 默认使用 config.env 中的配置
bash .gd32-agent/debug-loop.sh
```

#### 证据报告要求

| 证据项 | 来源 | 必须 |
|--------|------|------|
| 编译结果 | `build.log`（退出码 + 错误/警告摘要） | 是 |
| 烧录结果 | `flash.log`（退出码 + verify 状态） | 是 |
| 寄存器值 | `registers-general.md` + `registers-periph.md` | 是（有 .elf 时） |
| 串口输出 | `serial.log`（实际捕获内容） | 是 |
| 根因分析 | 基于以上证据的分析，引用具体寄存器值和日志行 | 是 |
| 修复措施 | 代码 diff + 为什么这个修改能解决问题 | 是（非首轮） |

#### 停止条件

- Bug 已修复（有证据证明）
- 连续 5 轮循环无法定位根因 → 停止并输出所有已收集的证据，请求用户介入
- 遇到硬件故障（调试器无法连接、芯片无响应）→ 立即停止并报告

---

## 7. hardware-analysis Skill 详解

### 7.1 基本信息

- **文件位置**：`.claude/skills/hardware-analysis/SKILL.md`
- **名称**：hardware-analysis
- **功能**：硬件文档读取 + 工程文件扫描 + 一致性检查 + 分析报告生成

### 7.2 工作流程

```
读取 hardware/硬件资源表.md
        ↓
扫描工程文件（启动文件、链接脚本、头文件、CMakeLists.txt）
        ↓
识别芯片型号和固件库
        ↓
一致性检查（扫描结果 vs 硬件文档）
        ↓
生成硬件分析文档
```

### 7.3 芯片识别优先级

1. **硬件探测（OpenOCD 读取 DBGMCU_IDCODE）**— 最高优先级，直接读芯片寄存器
2. 启动文件名（`startup_gd32f470.s` → GD32F470）
3. 链接脚本（`gd32f470vet6_flash.ld` → GD32F470VET6）
4. 头文件（`gd32f4xx.h` → GD32F4xx 系列）
5. CMakeLists.txt 中的定义
6. 源码中的头文件引用

### 7.4 固件库识别

| 检测特征 | 固件库类型 |
|---------|-----------|
| `gd32f4xx.h` / `rcu_periph_clock_enable` / `gpio_mode_set` | GD32 标准库 |
| `stm32f10x.h` / `GPIO_Init` | STM32 StdPeriph |
| `stm32xxxx_hal.h` / `HAL_GPIO_Init` | STM32 HAL |
| `esp_system.h` / `gpio_set_level` | ESP-IDF |
| `Arduino.h` / `digitalWrite` | Arduino |

---

## 8. RIPER-5 工作流程详解

RIPER-5 是 embedded-dev Skill 的核心开发协议，包含 5 个模式，按顺序执行：

```
RESEARCH → INNOVATE → PLAN → EXECUTE → REVIEW
  研究        创新       计划     执行       审查
```

每个回复开头必须声明当前模式：`[MODE: MODE_NAME]`

### 8.1 模式1：RESEARCH（研究）

**目的**：信息收集和深入理解
**允许**：读取文件、询问硬件规格、理解代码结构、识别固件库
**禁止**：实施更改、规划、给出最终决策方案

**执行步骤**：

| 步骤 | 操作 | 优先级 |
|------|------|--------|
| 1 | 搜索现有资料和开源方案 | 最高 |
| 2 | 识别芯片平台和固件库 | 高 |
| 3 | 分析任务相关代码 | 高 |
| 4 | 检查外设配置和硬件交互 | 中 |
| 5 | 审查时钟设置和时序 | 中 |
| 6 | 记录 API 模式 | 中 |
| 7 | 引脚规划与冲突检测（关键） | 最高 |
| 8 | 生成/更新硬件资源表 | 高 |
| 9 | 记录候选方案 | 中 |

**步骤1 搜索优先级**：
1. 查阅离线索引 `refs/embed-libs-index.md`
2. 离线未覆盖 → `gh api repos/zhengnianli/EmbedSummary/readme`
3. 仍无结果 → `gh` CLI + grok-search 扩大搜索

**步骤7 引脚规划流程**：
1. 先触发网表检测（如果项目有网表文件，优先从网表提取引脚）
2. 列出所有需要的外设
3. 用 grok-search 搜索官方 pinout 文档
4. 检查调试口/STRAP 引脚
5. 检测引脚冲突
6. 参考 `refs/pin-planning.md` 生成推荐分配
7. **禁止未查手册直接用"默认引脚"**

**输出格式**：`[MODE: RESEARCH]` + "已确认事实 / 证据来源 / 未确认问题"

### 8.2 模式2：INNOVATE（创新）

**目的**：头脑风暴潜在方案，优先评估和复用现有开源方案
**允许**：讨论多种方案、评估优缺点
**禁止**：具体规划、实现细节、代码编写

**执行步骤**：

1. **评估 RESEARCH 找到的现有方案**（最高优先级）
   - 用 `gh search repos` / grok-search 筛选对比
   - 参考 `refs/driver-porting.md` 评估可移植性
   - 前 3 名进入详细对比
   - 无合适方案 → 进入"自行实现"决策门
2. 基于研究创建方案（中断/轮询/DMA、自行实现 vs 移植）
3. 评估 CPU 负载、延迟、资源使用
4. 确保与固件库兼容

**八荣八耻原则**：以创造接口为耻，以复用现有为荣

### 8.3 模式3：PLAN（计划）

**目的**：创建详细技术规格，标记每步是否需要交互审查
**允许**：详细计划（文件路径、函数签名、寄存器配置）
**禁止**：任何实现或代码编写

**审查标记规则**：

| 情况 | review 标记 |
|------|------------|
| 编写/修改代码 | `review:true` |
| 创建/编辑/删除文件 | `review:true` |
| 关键硬件配置（中断/时钟/DMA） | `review:true` |
| 纯问答、概念解释 | `review:false` |
| 内部计算并报告结果 | `review:false` |

**必须输出编号清单**：

```
实施清单：
1. [具体操作1, verify:<验证标准>, review:true]
2. [具体操作2, verify:<验证标准>, review:false]
...
n. [最终操作, verify:<验证标准>, review:true]
```

**零占位符规则**：清单中禁止出现"后续实现"、"待定"、"TBD"、"TODO"、"同上"、省略号等。每步必须包含具体文件路径、操作内容、验证标准。

### 8.4 模式4：EXECUTE（执行）

**目的**：严格按计划执行，按轮次制交付证据
**允许**：仅实现计划中明确的内容
**禁止**：未报告偏差、计划外改进

**轮次制规则**：
1. 执行前声明：当前轮次、`trace_id`、目标、验证标准、停止条件
2. 每轮只推进一个改动点
3. 每轮结束交付证据包和 3 句交接摘要
4. 碰到红线时立即停止（新增依赖、改动超 5 文件、连续两轮无法确认根因）

**review:true 流程**：
```
展示代码变更 → 输出审查门 → 等待用户回复 → 用户通过 → Git 存档 → 记录到编辑清单
```

**review:false 流程**：
```
展示执行结果 → 请求确认 → 用户确认 → Git 存档
```

**代码质量标准**：
- 对 ISR 共享变量使用 `volatile`
- 必要时使用原子操作
- 谨慎处理临界区
- 遵循库特定编程模式

### 8.5 模式5：REVIEW（审查）

**目的**：全面验证结果与需求的一致性

**三步审查流程**：

#### Step 1: 验证门（Iron Law — 证据先于声明）

对每个完成声明执行 5 步验证：
1. **IDENTIFY**：什么命令/操作能证明这个声明？
2. **RUN**：实际执行该命令
3. **READ**：完整读取输出
4. **VERIFY**：输出是否确认声明？
5. **ONLY THEN**：发出完成声明

| 声明 | 必须的证据 |
|------|-----------|
| "编译通过" | 编译命令输出 + 退出码 0 + 无 warning |
| "功能正常" | 实际运行结果 / 串口日志 / 示波器波形 |
| "引脚配置正确" | 对照数据手册 + 硬件资源表逐项确认 |
| "中断工作正常" | 中断触发证据（GPIO 翻转/串口计数/断点命中） |
| "DMA 传输完成" | DMA 完成标志位 + 目标缓冲区数据正确 |
| "Bug 已修复" | 修复前后的寄存器对比 + 串口输出对比 + 编译烧录证据 |
| "外设配置正确" | OpenOCD 读取外设寄存器值 + 与数据手册期望值逐位对比 |
| "寄存器值正确" | debug.sh 读取的实际值 + 期望值 + 逐位分析 |

#### Step 2: 硬件合规审查

- 逐行比较最终计划与实现
- 核对代码与硬件资源表一致性
- 对照硬件规格验证
- 检查竞态条件、时序问题
- 验证 `volatile` 和原子操作
- 验证内存和资源使用

#### Step 3: 代码质量审查

- 库特定模式一致性
- 命名规范、代码结构
- 临界区保护是否完整

**反自欺检查表（关键）**：

| 你在想什么 | 现实 | 正确做法 |
|-----------|------|---------|
| "编译通过了，应该没问题" | 编译通过 ≠ 功能正确 | 回到验证门 |
| "这个寄存器配置应该对的" | "应该"不是证据 | 打开数据手册逐位确认 |
| "我确定引脚没冲突" | 你的记忆不如文件可靠 | 打开硬件资源表逐条核对 |
| "差不多可以了" | "差不多"是 bug 的温床 | 要么完全正确，要么标记未完成 |

**禁止词汇**：在 REVIEW 输出中禁止使用"应该"、"理论上"、"大概"、"基本上"来声明完成。只允许"已验证"或"未验证"。

**结论格式**：
```
[已验证] 实现完美匹配最终计划。验证证据：[列出具体证据]
```
或
```
[未验证] 实现与最终计划存在偏差：[描述]。待验证项：[列出]
```

---

## 9. 四文件磁盘工作记忆机制

### 9.1 概述

四文件体系是解决 Claude 会话中断后"失忆"问题的核心机制。所有事实、计划、进度和硬件约束都持久化到磁盘文件中。

### 9.2 四个文件

| 文件 | 路径 | 用途 | 更新时机 |
|------|------|------|---------|
| **硬件资源表** | `hardware/硬件资源表.md` | 芯片型号、引脚分配、DMA 通道、中断优先级、时钟配置 | RESEARCH 阶段识别硬件后、每次引脚/DMA/中断变更时 |
| **编辑清单** | `docs/编辑清单.md` | 每次代码修改记录、Git commit hash、审查结果 | EXECUTE 阶段每步完成后、Git 存档后 |
| **研究发现** | `docs/研究发现.md` | 搜索结果摘要、候选方案、技术发现 | 每执行 2 次搜索/查询后 |
| **项目规划清单** | `docs/项目规划清单.md` | 项目整体进度、轮次记录、trace_id、验证结果 | PLAN 阶段制定计划后、每轮结束后 |

### 9.3 硬约束

1. 每次会话开始或上下文压缩后，必须先完成四文件启动检查
2. 启用长任务治理时，`项目规划清单.md` 和 `编辑清单.md` 必须记录 `trace_id`、轮次、验证标准和结果
3. 每执行 2 次搜索/查询操作后，必须把发现写入 `研究发现.md`
4. EXECUTE 阶段同一根因连续失败 3 次时，停止重试，写入失败记录并回到 RESEARCH
5. 外部搜索结果只能以摘要形式进入 `研究发现.md`，禁止直接粘贴进规划清单

### 9.4 静默恢复机制

每次会话开始时（如果四文件存在），执行静默恢复而非冗长的重启测试：

1. **静默读取所有存在的文件**，提取关键信息
2. **展示简短摘要**：

```
📋 会话恢复
- 当前阶段：[从项目规划清单提取]
- 上次工作：[从编辑清单提取最后修改]
- 芯片：[从硬件资源表提取] + [调试器]
- 进度：[已完成/进行中模块]
继续上次的工作还是开始新任务？
```

3. **等待用户选择**：
   - "继续" → 从上次阶段继续
   - "新任务" → 进入新的 RIPER-5 流程

### 9.5 文件模板位置

四文件的格式模板在 `templates/` 目录：
- `templates/硬件资源表.md`
- `templates/编辑清单.md`
- `templates/研究发现.md`
- `templates/项目规划清单.md`

详细格式规范见 `embedded-dev/refs/checklist-templates.md`。

---

## 10. 多 Agent 分工协作

### 10.1 触发条件

当任务满足以下任一条件时，自动启用多 Agent 模式：

- 需要修改 2 个及以上文件
- 预计需要 2 轮以上编译/烧录/调试迭代
- 需要在多个会话/角色之间交接
- 任务容易发散或需要随时回退
- 用户明确要求"多 Agent"

### 10.2 三角色

| 角色 | 职责 | 允许操作 | 禁止操作 |
|------|------|---------|---------|
| **Scout**（侦察） | 收集证据和约束 | 搜索、分析、报告 | 写代码、编译、烧录 |
| **Builder**（构建） | 实现代码并验证 | 编写代码、编译、烧录 | 搜索新方案、自行验收 |
| **Verifier**（验证） | 审查和验收 | 审查、评估、报告 | 修改代码、实现功能 |

### 10.3 核心规则

1. **禁止自我验收**：同一角色不能既实现又验收自己的实现
2. **单写者原则**：只读任务可并行，同一时刻只允许一个 Builder 写入
3. **trace_id 追踪**：每轮必须带 trace_id、目标、验证标准、停止条件、证据包
4. **交接压缩**：跨角色交接只传：目标、约束、候选文件、证据、下一步

### 10.4 工作流程

```
用户需求
   ↓
[Scout] 收集证据
   │ 输出：约束列表、候选方案、引脚规划、风险评估
   ↓
[Builder] 最小实现
   │ 输出：代码变更、编译结果、烧录结果、串口日志
   ↓
[Verifier] 审查验收
   │ 输出：验证报告（已验证/未验证）、偏差列表
   ↓
通过 → 下一轮 / 完成
未通过 → 回到 Builder 或 Scout
```

详细工作流程见 `docs/multi-agent-workflow.md` 和 `embedded-dev/refs/vibe-workflow.md`。

---

## 11. 扩展模式

embedded-dev Skill 支持 5 种扩展模式，分为"替代型"和"辅助型"两类。

### 11.1 替代型模式（替代 RIPER-5 阶段流程）

#### 比赛模式（Competition Mode）

| 项目 | 内容 |
|------|------|
| **触发词** | `启用比赛模式` |
| **规则文件** | `embedded-dev/modes/competition.md` |
| **功能** | 多角色并行团队开发，适用于嵌入式竞赛 |

**4 个角色**：

| 角色 | 职责 | 产出 |
|------|------|------|
| **ARCH**（架构师） | 硬件选型、引脚规划、模块划分、接口定义 | 架构文档、引脚分配表、模块接口规范 |
| **DRV**（驱动工程师） | 外设驱动编写、BSP 层实现 | 驱动代码、驱动测试结果 |
| **ALG**（算法工程师） | 控制算法、信号处理、数据融合 | 算法模块、参数调优记录 |
| **QA**（质量保证） | 集成测试、性能验证、稳定性测试 | 测试报告、Bug 列表 |

**4 个阶段**：

```
阶段 1: 硬件规划（ARCH 主导）
   ↓
阶段 2: 并行开发（DRV + ALG 并行，ARCH 协调）
   ↓
阶段 3: QA 验证（QA 主导，逐模块测试）
   ↓
阶段 4: 系统集成（全员参与）
```

**Git 检查点**：

| 检查点 | 时机 | 命名规则 |
|--------|------|---------|
| CP-0 | 竞赛开始 | `[CP-0] 竞赛启动` |
| CP-1 | 硬件规划完成 | `[CP-1] 硬件规划完成` |
| CP-2 | 单模块测试通过 | `[CP-2] <模块>测试通过` |
| CP-3 | 集成测试通过 | `[CP-3] 集成测试通过` |
| CP-4 | 竞赛提交 | `[CP-4] 最终提交` |

### 11.2 辅助型模式（不替代 RIPER-5，随时可触发）

#### 数据手册查阅模式（Datasheet Lookup）

| 项目 | 内容 |
|------|------|
| **触发词** | `查手册` / `查数据手册` / `datasheet` |
| **规则文件** | `embedded-dev/modes/datasheet-lookup.md` |
| **功能** | 搜索数据手册 → 下载 PDF → MCP 解析 → 参数提取 → 代码注释 |

**5 阶段流程**：

1. **LOCATE**：确定目标手册（芯片型号 + 文档类型）
2. **OBTAIN**：获取 PDF（gh CLI → grok-search → Playwright 下载）
3. **PARSE**：用 /pdf Skill 提取 MCP 解析内容
4. **EXTRACT**：提取关键参数（引脚复用表、电气特性、时钟树、寄存器描述）
5. **ANNOTATE**：将参数写入代码注释和硬件资源表

**PDF 存档规则**：保存到 `docs/datasheets/`，命名 `<model>_<doctype>.pdf`

**代码注释格式**：
```c
// @ref GD32F470VET6_Datasheet, Table 5-15, Page 68
// PA9 → AF7 (USART0_TX)
```

**可信源**：st.com, ti.com, nxp.com, microchip.com, espressif.com, gd32mcu.com

#### 逐飞开源库管理模式（Seekfree Library）

| 项目 | 内容 |
|------|------|
| **触发词** | `逐飞` / `seekfree` / `英飞凌库` |
| **规则文件** | `embedded-dev/modes/seekfree-lib.md` |
| **功能** | 搜索 → 下载 → 本地索引 → 移植逐飞开源库 |

**5 步流程**：

1. **识别芯片**：确定当前项目的芯片平台
2. **检查本地索引**：查看 `逐飞库索引.md` 是否已有缓存
3. **询问用户**：确认是否从 Gitee 下载
4. **下载库**：`git clone https://gitee.com/seekfree/<repo>.git`
5. **使用库**：将库文件集成到工程

**芯片映射**：

| 芯片 | Gitee 仓库 |
|------|-----------|
| TC264 | seekfree/TC264_Library |
| TC377 | seekfree/TC377_Library |
| RT1064 | seekfree/RT1064_Library |
| MM32F327X | seekfree/MM32F327X_Library |
| CH32V307 | seekfree/CH32V307_Library |

**典型目录结构**：
```
libraries/seekfree_libraries/
├── zf_driver/    # 外设驱动（gpio, uart, spi, i2c, adc, pwm, timer）
├── zf_device/    # 设备驱动（ips屏幕, 摄像头, 编码器, 陀螺仪）
└── zf_common/    # 工具库（fifo, soft_iic, printf）
```

#### 网表查阅模式（Netlist Lookup）

| 项目 | 内容 |
|------|------|
| **触发词** | `网表` / `netlist` / `读网表` / `查网表` |
| **规则文件** | `embedded-dev/modes/netlist-lookup.md` |
| **功能** | 检测网表 → 解析格式 → 提取 MCU 引脚 → 比对资源表 → 应用到代码 |

**5 阶段流程**：

1. **DETECT**：在项目中搜索网表文件（`*.net`, `*.kicad_net`, `*.asc` 等）
2. **PARSE**：识别格式并解析
3. **EXTRACT**：提取 MCU 所有引脚连接（引脚号 → 网络名 → 对端器件.引脚）
4. **COMPARE**：与硬件资源表比对，发现不一致
5. **APPLY**：将网表引脚分配应用到代码中

**支持的网表格式**：

| 格式 | 扩展名 | EDA 工具 |
|------|--------|---------|
| Protel/Altium | `.net` | Altium Designer |
| KiCad | `.kicad_net` | KiCad |
| Pads | `.asc` | Pads |
| Spice | `.cir` / `.spice` | 各种 SPICE 工具 |
| Allegro | `.dat` | Cadence Allegro |

**9 条核心规则**（摘要）：
1. 网表是引脚分配的唯一真相来源（Single Source of Truth）
2. 约束验证永远不跳过（调试口、STRAP 引脚等）
3. 网表与硬件资源表冲突时以网表为准
4. 无网表时退化为手动规划

**代码注释格式**：
```c
// @netlist schematic_v2.net, 网络名: USART0_TX, 对端: CN1-3
gpio_mode_set(GPIOA, GPIO_MODE_AF, GPIO_PUPD_NONE, GPIO_PIN_9);
```

**自动触发**：在 RESEARCH 阶段步骤 7（引脚规划）自动检测网表文件，如果存在则优先使用。

#### MCP 工具健康检查模式（MCP Healthcheck）

| 项目 | 内容 |
|------|------|
| **触发词** | `检查工具` / `检查mcp` / `测试工具` / `mcp检查` / `工具诊断` / `healthcheck` / `check tools` / `检查所有mcp工具` |
| **规则文件** | `embedded-dev/modes/mcp-healthcheck.md` |
| **功能** | 逐一测试所有 MCP 工具 → 诊断问题 → 尝试修复 → 生成报告 |

**测试的 7 组工具**：

| 工具组 | 测试方法 | 健康标准 |
|--------|---------|---------|
| Context7 MCP | `resolve-library-id` + `query-docs` | 返回有效文档 |
| Grok-Search CLI | `grok-search "test"` | 返回搜索结果 |
| Document Skills /pdf | `pypdf` 库检测 | 能解析 PDF |
| Document Skills /xlsx | `openpyxl` 库检测 | 能解析 Excel |
| Sequential Thinking MCP | 发送测试推理链 | 返回推理结果 |
| Embedded Debugger MCP | 检测配置 | 配置存在即正常 |
| Serial MCP | 检测端口配置 | 配置存在即正常 |

**4 步流程**：
1. **COLLECT**：收集所有可用工具列表
2. **TEST**：并行测试每个工具
3. **DIAGNOSE**：诊断失败原因，尝试自动修复
4. **REPORT**：生成表格报告（工具名/状态/延迟/备注）

---

## 12. 参考文档库 (refs/)

`embedded-dev/refs/` 目录下有 17 个参考文档，按需加载（L3 层级）：

| 文件 | 大小 | 内容 | 加载时机 |
|------|------|------|---------|
| **gd32f4xx-stdperiph-api.md** | 大 | GD32F4xx 标准库完整 API 速查（RCU/GPIO/USART/SPI/I2C/DMA/TIMER/ADC/NVIC/EXTI）、外设总线映射、GPIO AF 表、GD32↔STM32 对照表 | RESEARCH 阶段识别为 GD32 后、EXECUTE 阶段编写代码时 |
| **stm32-stdperiph-api.md** | 大 | STM32 标准外设库完整 API 速查 | 识别为 STM32 StdPeriph 时 |
| **stm32-hal-api.md** | 大 | STM32 HAL 库完整 API 速查 | 识别为 STM32 HAL 时 |
| **checklist-mechanism.md** | 中 | 四文件体系详细规则：五问重启测试、轮次记录格式、失败协议、安全边界 | 会话恢复时 |
| **checklist-templates.md** | 中 | 四文件格式模板（硬件资源表/编辑清单/研究发现/项目规划清单） | 创建四文件时 |
| **vibe-workflow.md** | 中 | 长任务治理、证据包格式、Scout/Builder/Verifier 交接格式、轮次控制 | 多 Agent 模式时 |
| **coding-standards.md** | 中 | 模块化编程规范、命名规范、代码块格式、禁止行为清单、通用初始化四步法 | EXECUTE 阶段编写代码时 |
| **pin-planning.md** | 中 | 引脚规划完整流程、冲突检测矩阵、常见芯片引脚约束速查 | RESEARCH 阶段步骤 7 |
| **driver-porting.md** | 中 | 驱动库移植优先原则、搜索优先级、移植评估标准、移植步骤、回退条件 | INNOVATE 阶段评估方案时 |
| **embed-libs-index.md** | 中 | 嵌入式开源库离线索引（RTOS/按键/定时器/日志/Shell/Flash/JSON/调试/状态机/通信/GUI/驱动分类） | RESEARCH 阶段步骤 1 |
| **troubleshooting.md** | 中 | 故障诊断表格（通信/外设/中断/启动/存储分类）、平台特定排查、调试技巧速查 | EXECUTE 阶段遇到问题时 |
| **systematic-debugging.md** | 中 | 四阶段根因分析方法 | REVIEW 阶段复杂调试时 |
| **platform-migration.md** | 中 | 跨平台迁移检查清单、平台差异速查表、常见迁移场景 | 跨平台移植时 |
| **imu-gyroscope-checklist.md** | 小 | IMU/陀螺仪姿态解算检查清单（轴匹配/量程/DLPF/滤波系数） | 涉及 MPU6050/ICM20602/BMI088 时 |
| **mahony-ahrs-reference.md** | 中 | Mahony AHRS 算法完整实现、参数调优、信号预处理 | 需要高精度 3D 姿态解算时 |
| **mcp-tools.md** | 中 | 所有 MCP 工具的详细调用方式、降级矩阵、恢复原则、命令示例 | 需要调用 MCP 工具时 |
| **task-template.md** | 小 | 任务文件创建模板 | 创建新任务时 |

### API 查询优先级

```
需要查 GD32 API → refs/gd32f4xx-stdperiph-api.md（本地）
                   → Context7 MCP（在线）
                   → grok-search（兜底）

需要查 STM32 StdPeriph API → refs/stm32-stdperiph-api.md（本地）
                              → Context7 MCP
                              → grok-search

需要查 STM32 HAL API → refs/stm32-hal-api.md（本地）
                        → Context7 MCP
                        → grok-search
```

**本地离线文件优先级高于 Context7 MCP**。

---

## 13. .gd32-agent 脚本工具集

`.gd32-agent/` 目录下的所有 Shell 脚本：

### 13.1 config.env — 配置文件

```bash
# GD32 Agent 工具路径配置
OPENOCD_PATH="/path/to/openocd"
GDB_PATH="arm-none-eabi-gdb"

# 串口配置（按平台填写）
# Windows: COM3, COM15 等
# Linux: /dev/ttyUSB0, /dev/ttyACM0 等
# macOS: /dev/tty.usbserial-*, /dev/tty.usbmodem-* 等
SERIAL_PORT="COM15"
SERIAL_BAUDRATE="115200"
```

所有脚本统一从此文件读取配置。路径查找 fallback 链：
```
config.env 中的 OPENOCD_PATH → which openocd → 硬编码路径
```

### 13.2 check-env.sh — 环境检查

```bash
bash .gd32-agent/check-env.sh
```

检查项目：
- OpenOCD 是否已安装及版本
- ARM GCC 工具链（arm-none-eabi-gcc、arm-none-eabi-gdb、arm-none-eabi-objcopy、arm-none-eabi-size）
- Make 工具
- Python（串口工具依赖）
- 串口工具（pyserial）

### 13.3 scan-project.sh — 工程扫描

```bash
bash .gd32-agent/scan-project.sh
```

扫描内容：
- 启动文件（`startup_*.s`）
- 链接脚本（`*.ld`）
- 头文件（`gd32*.h`、`stm32*.h`）
- 构建系统（CMakeLists.txt、Makefile、*.uvprojx、*.ewp）
- 源码中的固件库引用

输出：芯片型号、芯片系列、固件库类型、工程类型

### 13.4 probe-chip.sh — 芯片硬件探测脚本

```bash
bash .gd32-agent/probe-chip.sh                    # 自动探测
bash .gd32-agent/probe-chip.sh --interface daplink # 指定调试器类型
bash .gd32-agent/probe-chip.sh -v                  # 详细输出
bash .gd32-agent/probe-chip.sh -t 15               # 自定义超时
```

通过 OpenOCD 直接连接芯片 SWD 接口，一次性读取：
- DBGMCU_IDCODE（0xE0042000 / 0x40015800）→ 芯片型号和系列
- Flash Size Register（0x1FFF7A22 / 0x1FFFF7E0）→ Flash 大小
- Unique ID（0x1FFF7A10 / 0x1FFFF7E8）→ 芯片唯一标识

自动生成最小探测配置，按优先级尝试 DAPLink → ST-Link → J-Link。结果保存在 `.gd32-agent/probe-result.env`。

容错设计：OpenOCD 未安装或调试器未连接时不阻塞流程，始终返回退出码 0。

### 13.5 build.sh — 编译脚本

```bash
bash .gd32-agent/build.sh
```

自动检测工程类型并执行对应编译命令。从 `config.env` 读取工具链路径。

### 13.5 flash.sh — 烧录脚本

```bash
bash .gd32-agent/flash.sh build/app.hex
```

使用 OpenOCD 烧录固件。自动读取 `openocd.cfg` 配置和 `config.env` 中的 OpenOCD 路径。

### 13.6 serial.sh — 串口监控脚本

```bash
# 指定参数
bash .gd32-agent/serial.sh COM15 115200 10
# 参数：端口号  波特率  超时秒数

# 使用 config.env 默认配置
bash .gd32-agent/serial.sh
```

跨平台兼容：
- Python 检测：优先使用 `python3`，fallback 到 `python`
- 超时机制：优先使用 `timeout` → `gtimeout`（macOS coreutils）→ Python subprocess fallback
- 默认端口：Linux→`/dev/ttyUSB0`，macOS→`/dev/tty.usbserial`，Windows→`COM3`

使用 Python pyserial 的 miniterm 进行串口监控。

### 13.7 debug.sh — 寄存器调试脚本

```bash
# 模式 1：通用寄存器转储（默认）
bash .gd32-agent/debug.sh build/app.elf

# 模式 2：读取指定外设寄存器（如 USART0 基地址，读 16 个寄存器）
bash .gd32-agent/debug.sh --periph 0x40011000 16 build/app.elf

# 模式 3：批量读取多个外设寄存器
bash .gd32-agent/debug.sh --batch .gd32-agent/periph-addrs.txt build/app.elf
```

使用 OpenOCD 的 `mdw`（Memory Display Word）命令直接读取外设寄存器，支持通用寄存器、指定外设、批量外设三种模式。输出保存为 Markdown 格式。

### 13.8 gen-openocd-cfg.sh — 自动生成 OpenOCD 配置

```bash
bash .gd32-agent/gen-openocd-cfg.sh
```

读取 `hardware/硬件资源表.md`，根据调试器类型和芯片系列自动生成 `.gd32-agent/openocd.cfg`。

**映射规则**：

| 调试器 | interface 配置 |
|--------|---------------|
| ST-LINK | `interface/stlink.cfg` |
| DAPLink | `interface/cmsis-dap.cfg` |
| J-Link | `interface/jlink.cfg` |

| 芯片系列 | target 配置 |
|----------|-------------|
| GD32F1xx | `target/stm32f1x.cfg` |
| GD32F3xx | `target/stm32f3x.cfg` |
| GD32F4xx | `target/stm32f4x.cfg` |
| GD32E2xx | `target/stm32f0x.cfg` |

### 13.9 verify-hardware.sh — 硬件一致性检查

```bash
bash .gd32-agent/verify-hardware.sh
```

扫描工程中的启动文件、链接脚本、头文件，提取芯片信息，与 `hardware/硬件资源表.md` 对比，输出一致性报告。

### 13.10 log-with-timestamp.sh — 日志记录

```bash
bash .gd32-agent/log-with-timestamp.sh <type> <status> "<message>"
# 示例：
bash .gd32-agent/log-with-timestamp.sh build SUCCESS "编译完成"
bash .gd32-agent/log-with-timestamp.sh flash SUCCESS "烧录完成"
bash .gd32-agent/log-with-timestamp.sh flash FAIL "烧录失败：连接超时"
```

日志保存在 `.gd32-agent/logs/` 目录，带时间戳。

### 13.11 detect-serial.sh — 串口自动检测

```bash
bash .gd32-agent/detect-serial.sh
```

自动检测系统可用串口设备：
- **Windows**：扫描 COM1-COM20，使用 `mode` 命令测试可用性
- **Linux**：扫描 `/dev/ttyUSB*`、`/dev/ttyACM*`
- **macOS**：扫描 `/dev/tty.usbserial*`、`/dev/tty.usbmodem*`

输出 `DETECTED_PORT=<端口名>` 格式，供其他脚本自动引用。

### 13.12 debug-loop.sh — 自动调试循环

```bash
# 一键执行：编译 → 烧录 → 寄存器读取 → 串口观察
bash .gd32-agent/debug-loop.sh

# 指定串口超时（默认 5 秒）
bash .gd32-agent/debug-loop.sh 10

# 指定外设地址文件
bash .gd32-agent/debug-loop.sh 5 .gd32-agent/periph-addrs.txt
```

自动执行 4 步循环：
1. **编译**：调用 `build.sh`，失败则退出（exit 1）
2. **烧录**：调用 `flash.sh`，失败则退出（exit 2）
3. **寄存器读取**：调用 `debug.sh` 读取通用寄存器 + 外设寄存器（如有地址文件）
4. **串口观察**：调用 `serial.sh` 捕获指定时间的串口输出

证据文件保存在 `.gd32-agent/logs/debug-<时间戳>/` 目录：
- `build.log` — 编译输出
- `flash.log` — 烧录输出
- `registers-general.md` — 通用寄存器转储
- `registers-periph.md` — 外设寄存器转储
- `serial.log` — 串口输出
- `summary.env` — 各步骤退出码汇总

### 13.13 openocd.cfg — OpenOCD 配置文件

由 `gen-openocd-cfg.sh` 自动生成，或用户手动编辑。典型内容：

```tcl
source [find interface/cmsis-dap.cfg]
transport select swd
adapter speed 4000
source [find target/stm32f4x.cfg]
```

---

## 14. Hooks 系统

Hooks 是 Claude Code Skills 的事件钩子机制，在特定事件发生时自动执行 Shell 命令。embedded-dev Skill 定义了 3 类 Hooks。

### 14.1 UserPromptSubmit Hook

**触发时机**：用户提交消息时
**执行内容**：检查四文件是否存在，提醒 Claude 读取最新内容

```bash
for f in 项目规划清单.md 编辑清单.md 硬件资源表.md 研究发现.md; do
  test -f "$f" && echo "[embedded-dev] 检测到 $f，请确保已读取最新内容。" || true
done
```

### 14.2 PreToolUse Hook

**触发时机**：Claude 执行 Write、Edit、Bash 工具之前
**匹配器**：`Write|Edit|Bash`
**执行内容**：显示项目规划清单（前20行）+ 硬件资源表（芯片信息段）+ 研究发现（最近发现段）

这确保 Claude 在每次修改代码前都能看到最新的项目状态和硬件约束，避免与已有规划冲突。

### 14.3 PostToolUse Hook

**触发时机**：Claude 执行 Write、Edit、Bash 工具之后
**匹配器**：`Write|Edit|Bash`
**执行内容**：提醒更新编辑清单、硬件资源表（如有引脚变更）、研究发现（如有新发现）

```bash
test -f 编辑清单.md && echo '[embedded-dev] 代码已修改，请更新 编辑清单.md、硬件资源表.md（如有引脚变更）、研究发现.md（如有新发现）。' || true
```

### 14.4 Hooks 的环境依赖

Hooks 使用 POSIX shell 语法（test、head、sed、for/do），需要在 bash/zsh 环境下执行。Claude Code 默认使用 bash shell，因此在 Windows 上需要有 Git Bash 或 MSYS2 环境。

---

## 15. 辅助工具调用规范

### 15.1 工具优先级总表

| 类型 | 工具 | 适用场景 | 备用方案 |
|------|------|---------|---------|
| MCP | **Context7** | 固件库 API、函数签名、初始化顺序 | 本地 refs / grok-search |
| MCP | **grok-search** | 联网检索：驱动、报错、竞赛经验、数据手册入口 | Claude WebSearch / 手动搜索 |
| Skill | **Document Skills** | PDF/XLSX/DOCX/PPTX 文档读取提取 | Claude Read / grok-search |
| MCP | **Sequential Thinking** | 引脚冲突、DMA 分配、中断优先级等复杂推理 | 人工推理 + WebSearch |
| MCP | **Embedded Debugger** | 实时硬件调试、烧录、串口交互 | 串口日志 / 断言 / 手工烧录 |
| CLI | **gh** | GitHub 仓库搜索、代码搜索、读取源文件 | grok-search + `site:github.com` |

### 15.2 工具路由原则

```
1. 一般联网搜索：本地 refs → grok-search → gh / WebSearch / 官方站点
2. STM32/GD32 API：本地离线 refs → Context7 → grok-search
3. 数据手册/pinout：网表模式 → grok-search 搜官方入口 → Document Skills 提取
4. REVIEW 质量检查：必要时调用 /simplify
5. 复杂跨文件分析：必要时调用 /codex
```

### 15.3 八荣八耻原则

```
以瞎猜接口为耻，以认真查询为荣
以创造接口为耻，以复用现有为荣
```

遇到 API 不确定时，必须先查文档再写代码，禁止凭训练知识猜测。

### 15.4 优先参考仓库

| 仓库 | 说明 | 使用方式 |
|------|------|---------|
| [EmbedSummary](https://github.com/zhengnianli/EmbedSummary) | 精品嵌入式资源汇总（5000+ stars） | `gh api repos/zhengnianli/EmbedSummary/readme` |

查找流程：
```
需要开源库 → 先查 refs/embed-libs-index.md（离线）
            → 无则查 EmbedSummary README
            → 仍无则用 gh search repos 或 grok-search
```

---

## 16. Git 备份与回档规则

### 16.1 触发词识别

| 类型 | 触发词 |
|------|--------|
| 回档 | `回档` / `回退` / `退回上一步` / `撤销上一步` |
| 存档 | `存档` / `保存进度` / `备份` |

### 16.2 自动存档

EXECUTE 阶段每完成一个实施清单项并获得用户确认后，自动执行：

```bash
git add -A
git commit -m "[AUTO-SNAPSHOT] 步骤N: <任务摘要>"
git push   # 有远端时自动推送
```

- 无文件变更时跳过提交，在编辑清单记录"无变更，未提交"
- 无远端时仅本地提交

### 16.3 回档策略

- "上一步"默认指最近一次自动存档（`HEAD~1`）
- **回档前先保护**：`git stash push -m "pre-rollback-<日期时间>"`
- **默认保守回退**：`git revert --no-edit HEAD`
- **强制回退**：仅用户明确要求时 → `git reset --hard HEAD~1`
- 回档完成后必须更新 `编辑清单.md`（记录回档前后 commit hash 与原因）

### 16.4 强制规则

1. 用户出现回档指令时，优先执行 Git 回档，禁止手工改代码"假回退"
2. 检测到远端 `origin` 时，提交后自动 `git push`
3. 回档完成后必须同步更新编辑清单

---

## 17. 安全规则

### 17.1 绝对禁止行为

| 禁止行为 | 原因 |
|---------|------|
| 未确认直接全片擦除 | 可能损坏 OTP 区域或 BootLoader |
| 未确认修改 Option Bytes | 可能永久锁死芯片 |
| 未确认解除读保护 | 会触发全片擦除 |
| 跳过硬件文档直接修改代码 | 可能导致硬件损坏 |
| 编译失败后继续烧录 | 烧录错误固件 |
| 芯片型号不确定时执行烧录 | 可能烧录不兼容的固件 |
| 调试器类型不确定时执行烧录 | 通信失败或损坏 |

### 17.2 烧录前必须确认

1. 芯片型号
2. 调试器类型
3. 固件文件路径
4. OpenOCD 配置

### 17.3 EXECUTE 红线

以下情况必须立即停止并回 PLAN 或请求用户裁决：
- 需要新增依赖
- 改动超过 5 个文件
- 修改根目录配置
- 连续两轮无法确认根因

---

## 18. 会话恢复机制

### 18.1 触发条件

以下任一情况触发会话恢复：
- 新会话开始时检测到四文件（项目规划清单、编辑清单、硬件资源表、研究发现）存在
- `gd32-agent init` 的步骤 0

### 18.2 恢复流程

1. **检测四文件**：检查四文件是否存在
2. **静默读取四文件**：依次读取每个文件的关键信息
3. **展示简短摘要**：一次性展示当前阶段、上次工作、芯片信息、进度
4. **等待用户选择**：继续上次工作 or 开始新任务

### 18.3 静默恢复格式

```
📋 会话恢复
- 当前阶段：[从项目规划清单提取]
- 上次工作：[从编辑清单提取最后修改]
- 芯片：[从硬件资源表提取] + [调试器]
- 进度：[已完成/进行中模块]
继续上次的工作还是开始新任务？
```

与旧版"五问重启测试"相比，静默恢复更简洁高效：Agent 自行读取所有信息，只向用户展示摘要并询问一个问题。

---

## 19. GD32F470VET6 工程模板

### 19.1 位置

`templates/project/gd32f470vet6/`

### 19.2 目录结构

```
templates/project/gd32f470vet6/
├── Makefile                    # ARM GCC Makefile
├── gd32f470vet6_flash.ld       # 链接脚本（512K Flash, 256K SRAM）
├── src/
│   ├── main.c                  # 最小 main（LED 闪烁 + USART0 printf）
│   ├── system_gd32f4xx.c       # 系统初始化（200MHz 时钟配置）
│   ├── gd32f4xx_it.c           # 中断处理（SysTick + 空处理）
│   └── retarget.c              # printf 重定向到 USART0
├── inc/
│   ├── gd32f4xx_it.h           # 中断处理头文件
│   └── systick.h               # SysTick 延时函数声明
└── README.md                   # 使用说明
```

### 19.3 芯片参数

| 参数 | 值 |
|------|-----|
| 内核 | ARM Cortex-M4 |
| 主频 | 200MHz |
| Flash | 512KB |
| SRAM | 256KB |
| 封装 | LQFP100 |

### 19.4 使用方法

1. 将模板复制到工程目录
2. 添加 GD32 标准库源码到 `Drivers/` 或 `Library/`
3. 修改 Makefile 中的标准库路径
4. `make` 编译

注意：模板不包含 GD32 标准库源码（用户需自行添加）。

---

## 20. config.env 配置说明

### 20.1 文件位置

`.gd32-agent/config.env`

### 20.2 配置项

```bash
# OpenOCD 路径（烧录/调试必需）
OPENOCD_PATH="/path/to/openocd"

# GDB 路径（调试用）
GDB_PATH="arm-none-eabi-gdb"

# 默认串口配置
# Windows: COM3, COM15 等
# Linux: /dev/ttyUSB0, /dev/ttyACM0 等
# macOS: /dev/tty.usbserial-*, /dev/tty.usbmodem-* 等
SERIAL_PORT="COM15"
SERIAL_BAUDRATE="115200"
```

### 20.3 路径查找 Fallback 链

所有脚本统一按以下顺序查找 OpenOCD：

```
1. config.env 中的 OPENOCD_PATH  （最高优先级）
2. which openocd                   （系统 PATH）
3. 硬编码路径                       （最后兜底）
   Linux:   /usr/bin/openocd, /usr/local/bin/openocd, /opt/openocd/bin/openocd
   macOS:   brew --prefix 下的 openocd
   Windows: D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe
```

### 20.4 安装时自动检测

`install.sh` 在安装时会自动检测 OpenOCD 路径并写入 `config.env`：
- 先检查 `which openocd`
- 再检查各平台常见路径：
  - **Linux**：`/usr/bin/openocd`、`/usr/local/bin/openocd`、`/opt/openocd/bin/openocd`
  - **Windows**：`D:\openocd\...`、`C:\openocd\...`、`%LOCALAPPDATA%\xPacks\openocd\...`
  - **macOS**：通过 Homebrew 安装的 openocd

---

## 21. 常见问题与紧急情况处理

### 21.1 烧录失败

```bash
# 检查连接
openocd -f .gd32-agent/openocd.cfg -c "init; halt; exit"

# 检查 Flash 是否被锁定
openocd -f .gd32-agent/openocd.cfg -c "init; halt; flash info 0; exit"
```

### 21.2 串口无输出

检查顺序：
1. GPIO 配置（TX/RX 引脚、AF 复用功能）
2. 时钟配置（RCU 是否使能了 USART 和 GPIO 时钟）
3. 波特率（与 `hardware/硬件资源表.md` 中配置一致）
4. printf 重定向（`retarget.c` 中的 `fputc` 函数）

### 21.3 编译失败

检查顺序：
1. 头文件路径（`-I` 参数）
2. 源文件编译列表（是否遗漏了 `.c` 文件）
3. 宏定义（`-D` 参数，如 `-DGD32F470`）
4. 链接脚本路径

### 21.4 调试器连接失败

检查顺序：
1. 调试器驱动是否安装
2. SWD 线是否连接正确（SWDIO、SWCLK、GND）
3. 目标板是否供电
4. OpenOCD 配置中的 interface 和 target 是否正确

### 21.5 EXECUTE 阶段同一问题连续失败

根据协议规则：
- 同一根因连续失败 3 次 → 停止重试
- 写入失败记录到研究发现
- 回到 RESEARCH 阶段重新分析

---

## 22. 完整触发词速查表

### embedded-dev Skill（58 个触发词）

按类别分组：

**芯片平台**：
```
嵌入式, 单片机, STM32, GD32, ESP32, Arduino, RISC-V, MCU, 芯片开发,
firmware, embedded, microcontroller
```

**外设**：
```
固件, 外设, 中断, GPIO, UART, SPI, I2C, DMA, 定时器, ADC, PWM,
CAN, USB, 寄存器
```

**框架/工具**：
```
HAL, StdPeriph, ESP-IDF, Keil, RTOS, FreeRTOS, Bootloader
```

**功能特性**：
```
低功耗, 看门狗, 烧录, JTAG, SWD, 驱动移植
```

**数据手册查阅**：
```
查手册, 查数据手册, datasheet
```

**比赛模式**：
```
启用比赛模式
```

**逐飞库**：
```
逐飞, seekfree, 英飞凌库
```

**网表查阅**：
```
网表, netlist, 读网表, 查网表
```

**MCP 工具检查**：
```
检查工具, 检查mcp, 测试工具, mcp检查, 工具诊断, healthcheck,
check tools, 检查所有mcp工具
```

### 扩展模式触发词速查

| 模式 | 触发词 | 类型 |
|------|--------|------|
| 比赛模式 | `启用比赛模式` | 替代型 |
| 数据手册查阅 | `查手册` / `查数据手册` / `datasheet` | 辅助型 |
| 逐飞库管理 | `逐飞` / `seekfree` / `英飞凌库` | 辅助型 |
| 网表查阅 | `网表` / `netlist` / `读网表` / `查网表` | 辅助型 |
| MCP 健康检查 | `检查工具` / `检查mcp` / `测试工具` / `mcp检查` / `工具诊断` / `healthcheck` / `check tools` / `检查所有mcp工具` | 辅助型 |

---

## 23. 快捷指令

以下单词/短语触发时，直接执行对应操作，无需走完整 RIPER-5 流程：

| 用户说 | Agent 执行 | 前置条件 |
|--------|-----------|---------|
| 编译 / build | `bash .gd32-agent/build.sh` | 无 |
| 烧录 / flash | build.sh → flash.sh | 编译成功 |
| 串口 / serial | `bash .gd32-agent/serial.sh` | 无 |
| 调试 / debug | `bash .gd32-agent/debug.sh` | 有 .elf 文件 |
| 调试循环 / debug-loop | `bash .gd32-agent/debug-loop.sh` | 无 |
| 全流程 / run | build → flash → serial | 无 |
| 环境检查 / check-env | `bash .gd32-agent/check-env.sh` | 无 |
| 扫描 / scan | `bash .gd32-agent/scan-project.sh` | 无 |
| 探测 / probe | `bash .gd32-agent/probe-chip.sh` | OpenOCD 已安装 |
| 生成配置 / gen-cfg | `bash .gd32-agent/gen-openocd-cfg.sh` | 无 |

**规则**：
- 快捷指令仅适用于用户输入是单个指令词或明确的简短操作请求
- 如果用户描述了具体需求（如"帮我实现 USART 打印"），走正常 RIPER-5 流程
- 烧录前仍需确认芯片型号和调试器类型（安全规则不可跳过）

---

## 24. 任务分级

根据任务复杂度分为 4 个等级，执行深度递增：

| 等级 | 典型任务 | 执行方式 |
|------|---------|---------|
| **Micro** | 改个字符串、加条注释、查看文件 | 直接执行，无需 RIPER-5 |
| **Small** | 修改单个函数、配置一个外设 | RESEARCH + EXECUTE（跳过 INNOVATE/PLAN） |
| **Medium** | 实现一个功能模块、修复复杂 Bug | 完整 RIPER-5 流程 |
| **Large** | 多模块联动、架构重构、竞赛项目 | 完整 RIPER-5 + 多 Agent + 轮次制 |

**判定规则**：
- 涉及 1 个文件、改动 < 10 行 → Micro
- 涉及 1-2 个文件、改动 < 50 行 → Small
- 涉及 2-5 个文件、需要调试验证 → Medium
- 涉及 5+ 文件、或需要 2 轮以上迭代 → Large

---

## 25. 跨平台支持

### 25.1 操作系统兼容性

| 功能 | Windows (Git Bash) | Linux | macOS |
|------|:---:|:---:|:---:|
| 安装 (`install.sh`) | ✅ | ✅ | ✅ |
| 环境检查 (`check-env.sh`) | ✅ | ✅ | ✅ |
| 工程扫描 (`scan-project.sh`) | ✅ | ✅ | ✅ |
| 编译 (`build.sh`) | ✅ | ✅ | ✅ |
| 烧录 (`flash.sh`) | ✅ | ✅ | ✅ |
| 串口观察 (`serial.sh`) | ✅ | ✅ | ✅ |
| 寄存器调试 (`debug.sh`) | ✅ | ✅ | ✅ |
| 自动调试循环 (`debug-loop.sh`) | ✅ | ✅ | ✅ |
| 芯片硬件探测 (`probe-chip.sh`) | ✅ | ✅ | ✅ |
| 串口检测 (`detect-serial.sh`) | ✅ | ✅ | ✅ |
| Keil MDK 编译 | ✅ | ❌ | ❌ |
| IAR 编译 | ✅ | ❌ | ❌ |

### 25.2 平台差异速查

| 配置项 | Windows | Linux | macOS |
|--------|---------|-------|-------|
| Shell 环境 | Git Bash / MSYS2 | bash / zsh | zsh / bash |
| 串口设备名 | `COM3`, `COM15` | `/dev/ttyUSB0`, `/dev/ttyACM0` | `/dev/tty.usbserial-*` |
| OpenOCD 路径 | `D:/openocd/.../openocd.exe` | `/usr/bin/openocd` | `brew --prefix`/`openocd` |
| Python 命令 | `python` 或 `python3` | `python3` | `python3` |
| 串口权限 | 无需额外配置 | 需加入 `dialout` 组 | 通常无需配置 |
| timeout 命令 | Git Bash 自带 | 系统自带 | 需 `brew install coreutils`（gtimeout） |
| sed -i 语法 | `sed -i "..."` | `sed -i "..."` | `sed -i '' "..."` |

### 25.3 跨平台兼容性实现

所有 `.gd32-agent/*.sh` 脚本已做跨平台适配：

1. **OpenOCD 路径搜索**：优先 config.env → `which openocd` → 各平台硬编码路径
2. **Python 检测**：`python3` → `python` fallback
3. **超时机制**：`timeout` → `gtimeout` → Python subprocess fallback
4. **正则表达式**：使用 ERE（`grep -oE`）而非 PCRE（`grep -oP`，macOS 不支持）
5. **sed 兼容**：`install.sh` 使用 `portable_sed_i()` 函数自动适配
6. **串口检测**：根据 `uname -s` 输出自动选择平台特定设备路径

---

## 附录 A：目录结构总览

安装后的完整工程目录结构：

```
your-gd32-project/
├── CLAUDE.md                           # L1：Agent 顶层规则（~150行）
├── hardware/
│   └── 硬件资源表.md                   # 硬件事实源 + 四文件之一（芯片、调试器、引脚、DMA、中断）
├── workflow/
│   └── development-flow.md             # 开发流程规则
├── docs/
│   ├── 编辑清单.md                     # 四文件之一：代码修改记录
│   ├── 研究发现.md                     # 四文件之一：搜索结果记录
│   ├── 项目规划清单.md                 # 四文件之一：项目进度记录
│   ├── multi-agent-workflow.md         # 多 Agent 工作流程
│   └── user-guide.md                   # 用户指南
├── embedded-dev/                       # L2：RIPER-5 完整协议
│   ├── SKILL.md                        # 主协议文件（~520行）
│   ├── refs/                           # L3：17个参考文档
│   │   ├── gd32f4xx-stdperiph-api.md   # GD32F4xx API 速查
│   │   ├── stm32-stdperiph-api.md      # STM32 StdPeriph API 速查
│   │   ├── stm32-hal-api.md            # STM32 HAL API 速查
│   │   ├── checklist-mechanism.md      # 四文件体系详细规则
│   │   ├── checklist-templates.md      # 四文件格式模板
│   │   ├── vibe-workflow.md            # 长任务治理/多Agent交接
│   │   ├── coding-standards.md         # 编码规范
│   │   ├── pin-planning.md             # 引脚规划流程
│   │   ├── driver-porting.md           # 驱动移植原则
│   │   ├── embed-libs-index.md         # 嵌入式开源库索引
│   │   ├── troubleshooting.md          # 故障排查表
│   │   ├── systematic-debugging.md     # 根因分析方法
│   │   ├── platform-migration.md       # 跨平台迁移指南
│   │   ├── imu-gyroscope-checklist.md  # IMU 检查清单
│   │   ├── mahony-ahrs-reference.md    # Mahony AHRS 算法参考
│   │   ├── mcp-tools.md               # MCP 工具详细用法
│   │   └── task-template.md            # 任务文件模板
│   └── modes/                          # 5个扩展模式
│       ├── competition.md              # 比赛模式
│       ├── datasheet-lookup.md         # 数据手册查阅
│       ├── seekfree-lib.md             # 逐飞库管理
│       ├── netlist-lookup.md           # 网表查阅
│       └── mcp-healthcheck.md          # MCP 健康检查
├── .gd32-agent/                        # Agent 脚本工具集
│   ├── config.env                      # 工具路径配置
│   ├── openocd.cfg                     # OpenOCD 配置
│   ├── check-env.sh                    # 环境检查
│   ├── scan-project.sh                 # 工程扫描
│   ├── build.sh                        # 编译脚本
│   ├── flash.sh                        # 烧录脚本
│   ├── serial.sh                       # 串口脚本（跨平台）
│   ├── debug.sh                        # 寄存器调试（通用/外设/批量模式）
│   ├── debug-loop.sh                   # 自动调试循环（编译→烧录→寄存器→串口）
│   ├── probe-chip.sh                   # 芯片硬件探测（通过 OpenOCD 读取 DBGMCU_IDCODE）
│   ├── gd32-chip-db.sh                 # GD32 芯片 ID 数据库
│   ├── detect-serial.sh                # 串口自动检测（跨平台）
│   ├── gen-openocd-cfg.sh              # 自动生成 OpenOCD 配置
│   ├── verify-hardware.sh              # 硬件一致性检查
│   ├── log-with-timestamp.sh           # 日志脚本
│   └── logs/                           # 日志目录
├── .claude/
│   ├── commands/gd32-agent/
│   │   └── init.md                     # init 命令定义
│   └── skills/
│       ├── gd32-openocd/SKILL.md       # 编译烧录调试 Skill
│       ├── hardware-analysis/SKILL.md  # 硬件分析 Skill
│       ├── document-skills/            # PDF/Word/PPT/Excel 文档处理
│       │   ├── pdf/SKILL.md
│       │   ├── docx/SKILL.md
│       │   ├── pptx/SKILL.md
│       │   └── xlsx/SKILL.md
│       └── superpowers-skills/         # 系统化调试/头脑风暴/计划/并行Agent
│           ├── systematic-debugging/SKILL.md
│           ├── brainstorming/SKILL.md
│           ├── writing-plans/SKILL.md
│           ├── verification-before-completion/SKILL.md
│           └── dispatching-parallel-agents/SKILL.md
└── templates/
    ├── 硬件资源表.md                   # 四文件模板
    ├── 编辑清单.md
    ├── 研究发现.md
    ├── 项目规划清单.md
    └── project/gd32f470vet6/           # GD32F470VET6 工程模板
        ├── Makefile
        ├── gd32f470vet6_flash.ld
        ├── src/
        │   ├── main.c
        │   ├── system_gd32f4xx.c
        │   ├── gd32f4xx_it.c
        │   └── retarget.c
        ├── inc/
        │   ├── gd32f4xx_it.h
        │   └── systick.h
        └── README.md
```

---

## 附录 B：快速参考卡片

### 日常开发命令

```bash
# 初始化
gd32-agent init

# 环境检查
bash .gd32-agent/check-env.sh

# 工程扫描
bash .gd32-agent/scan-project.sh

# 芯片硬件探测（通过 OpenOCD 读取芯片 ID）
bash .gd32-agent/probe-chip.sh

# 编译
bash .gd32-agent/build.sh

# 烧录
bash .gd32-agent/flash.sh build/app.hex

# 串口监控（使用 config.env 默认配置）
bash .gd32-agent/serial.sh

# 串口监控（指定参数）
bash .gd32-agent/serial.sh COM15 115200 10

# 通用寄存器调试
bash .gd32-agent/debug.sh build/app.elf

# 外设寄存器调试
bash .gd32-agent/debug.sh --periph 0x40011000 16 build/app.elf

# 批量外设寄存器调试
bash .gd32-agent/debug.sh --batch .gd32-agent/periph-addrs.txt build/app.elf

# 自动调试循环（编译→烧录→寄存器→串口）
bash .gd32-agent/debug-loop.sh

# 串口自动检测
bash .gd32-agent/detect-serial.sh

# 日志
bash .gd32-agent/log-with-timestamp.sh build SUCCESS "编译完成"
```

### 快捷指令（跳过 RIPER-5）

在 Claude Code 中输入以下单词/短语，直接执行对应操作：

| 用户说 | Agent 执行 |
|--------|-----------|
| 编译 / build | `bash .gd32-agent/build.sh` |
| 烧录 / flash | build.sh → flash.sh |
| 串口 / serial | `bash .gd32-agent/serial.sh` |
| 调试 / debug | `bash .gd32-agent/debug.sh` |
| 调试循环 / debug-loop | `bash .gd32-agent/debug-loop.sh` |
| 全流程 / run | build → flash → serial |
| 环境检查 / check-env | `bash .gd32-agent/check-env.sh` |
| 扫描 / scan | `bash .gd32-agent/scan-project.sh` |
| 生成配置 / gen-cfg | `bash .gd32-agent/gen-openocd-cfg.sh` |

### 触发 embedded-dev Skill 的最简方式

只要在 Claude Code 中提到以下任一关键词，即可自动加载 RIPER-5 协议：

```
GD32、GPIO、UART、SPI、I2C、DMA、烧录、编译、中断、定时器、ADC、PWM
```

### 触发扩展模式

```
启用比赛模式     → 竞赛开发模式（4角色并行）
查手册           → 数据手册查阅
逐飞             → 逐飞开源库管理
网表             → EDA 网表引脚提取
检查工具         → MCP 工具健康检查
```

### 回档与存档

```
回档 / 回退 / 退回上一步     → Git 保守回退（revert）
存档 / 保存进度 / 备份       → Git 快照提交
```

---

## 附录 C：权限配置

`.claude/settings.local.json` 中预配置了以下允许的命令：

```json
{
  "permissions": {
    "allow": [
      "Bash(openocd *)",
      "Bash(where openocd *)",
      "Bash(bash .gd32-agent/*.sh *)",
      "Bash(make *)",
      "Bash(arm-none-eabi-gcc *)",
      "Bash(arm-none-eabi-gdb *)",
      "Bash(arm-none-eabi-objcopy *)",
      "Bash(arm-none-eabi-size *)",
      "Bash(python -m serial.tools.miniterm *)",
      "Bash(git add *)",
      "Bash(git rm *)",
      "Bash(git commit -m ' *)",
      "Bash(git status *)",
      "Bash(git push *)"
    ]
  }
}
```

这意味着以上命令 Claude 可以自动执行，不需要每次询问用户确认。

---

*文档结束。本文档覆盖了 GD32 AI Agent 的全部功能、Skills（含 document-skills 和 superpowers-skills）、工作流程、触发词、脚本工具（含自动调试循环）、安全规则、跨平台支持和配置说明。*
