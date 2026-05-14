# GD32 AI Agent 任务执行规则

你正在协助用户开发 GD32 嵌入式工程。必须严格遵守以下规则。

## 指令层级

```
L1 — CLAUDE.md（本文件）：安全红线 + 路径配置 + 核心流程，每次会话加载
L2 — embedded-dev/SKILL.md：完整 RIPER-5 开发协议（证据优先、轮次制、多Agent），Skill 触发时加载
L3 — embedded-dev/refs/：按需加载的参考文档（API 速查、清单模板、工作流等）
```

重复内容以 L2/L3 为准，本文件只保留摘要和引用。

---

## 最高优先级

必须严格遵守以下文档，如果冲突，必须停止并报告：

1. `hardware/硬件资源表.md` - 硬件事实源
2. `workflow/development-flow.md` - 开发流程规则
3. `embedded-dev/SKILL.md` - 完整开发协议

---

## 第一步：读取硬件文档

每次执行任务前，必须先读取 `hardware/硬件资源表.md`，提取：芯片型号、芯片系列、调试器类型、串口配置、风险限制。

---

## 第二步：扫描工程文件

扫描启动文件(`startup_*.s`)、链接脚本(`*.ld`)、头文件(`gd32*.h`)、CMakeLists.txt、Makefile、源码头文件引用，识别芯片型号。

识别优先级：启动文件名 → 链接脚本 → 头文件 → CMakeLists.txt → 源码引用。

识别完成后自动更新 `hardware/硬件资源表.md` 中 AI 可推断的字段。

---

## 第三步：一致性检查

将 AI 识别结果与硬件文档对比（芯片型号、系列、Flash、SRAM）。冲突时：停止执行 → 报告冲突 → 等待用户确认。

---

## 第四步：OpenOCD 配置

### 调试器映射

| 调试器 | OpenOCD interface |
|--------|-------------------|
| ST-LINK | stlink.cfg |
| DAPLink | cmsis-dap.cfg |
| J-Link | jlink.cfg |

### GD32 系列映射

| 系列 | OpenOCD target |
|------|----------------|
| GD32F1xx | stm32f1x.cfg（兼容） |
| GD32F3xx | stm32f3x.cfg（兼容） |
| GD32F4xx | stm32f4x.cfg（兼容） |
| GD32E2xx | stm32f0x.cfg（兼容） |

### 路径配置

优先读取 `.gd32-agent/config.env` 中的 `OPENOCD_PATH`，fallback 到 `which openocd`，最后使用硬编码路径。

---

## 第五步：执行开发任务

标准流程：读取硬件文档 → 扫描工程 → 识别芯片 → 一致性检查 → 生成 OpenOCD 配置 → 用户确认 → Plan Mode 制定计划 → 执行代码修改 → 编译 → 烧录 → 验证。

工具脚本（详见 `.gd32-agent/` 目录）：

```bash
bash .gd32-agent/build.sh                    # 编译
bash .gd32-agent/flash.sh build/app.hex      # 烧录
bash .gd32-agent/serial.sh COM15 115200 10   # 串口观察
bash .gd32-agent/debug.sh build/app.elf      # 寄存器调试（通用寄存器）
bash .gd32-agent/debug.sh --periph 0x40011000 16 build/app.elf  # 读外设寄存器
bash .gd32-agent/debug.sh --batch .gd32-agent/periph-addrs.txt build/app.elf  # 批量读外设
bash .gd32-agent/debug-loop.sh 5             # 自动调试循环（编译→烧录→寄存器→串口）
bash .gd32-agent/log-with-timestamp.sh <type> <status> "<message>"  # 日志
```

---

## 快捷指令（跳过 RIPER-5）

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
| 生成配置 / gen-cfg | `bash .gd32-agent/gen-openocd-cfg.sh` | 无 |

**规则**：
- 快捷指令仅适用于用户输入是单个指令词或明确的简短操作请求
- 如果用户描述了具体需求（如"帮我实现 USART 打印"），走正常 RIPER-5 流程
- 烧录前仍需确认芯片型号和调试器类型（安全规则不可跳过）

---

## 安全规则

### 禁止行为

- 未确认直接全片擦除
- 未确认修改 Option Bytes
- 未确认解除读保护
- 跳过硬件文档直接修改代码
- 编译失败后继续烧录
- 芯片型号或调试器类型不确定时执行烧录

### 烧录前必须确认

1. 芯片型号 2. 调试器类型 3. 固件文件 4. OpenOCD 配置

---

## 自动调试循环（Bug 定位模式）

当用户报告 Bug 或 Agent 在开发过程中发现功能异常时，进入自动调试循环。

### 核心铁律

1. **禁止凭空捏造**：所有关于寄存器值、外设状态、运行结果的判断，必须来自 OpenOCD/GDB 实际读取或串口实际输出，禁止使用"应该是"、"理论上"、"根据经验"等猜测性表述
2. **证据驱动**：每一轮修复必须附带完整证据链（编译日志 + 烧录日志 + 寄存器转储 + 串口输出）
3. **自动执行**：编译、烧录、寄存器读取、串口观察全程自动执行，无需用户逐步确认权限
4. **循环直到解决**：修改代码后自动重新执行调试循环，直到 Bug 被证据确认已修复

### 自动调试流程

```
发现Bug → 分析代码 → 确定需要监测的外设寄存器
    → 生成 periph-addrs.txt（外设基地址列表）
    → 修改代码
    → 自动执行 debug-loop.sh（编译→烧录→寄存器读取→串口观察）
    → 读取证据文件，分析根因
    → Bug 未修复？→ 继续修改代码 → 重新执行循环
    → Bug 已修复？→ 输出完整证据报告
```

### 执行命令

```bash
# 一键调试循环（自动编译→烧录→寄存器→串口）
bash .gd32-agent/debug-loop.sh [串口超时秒数] [外设地址文件]

# 读取指定外设寄存器（手动单步）
bash .gd32-agent/debug.sh --periph <基地址> [寄存器数量] <固件.elf>

# 批量读取多个外设寄存器
bash .gd32-agent/debug.sh --batch .gd32-agent/periph-addrs.txt <固件.elf>
```

### 外设地址文件格式（`.gd32-agent/periph-addrs.txt`）

Agent 根据 Bug 涉及的外设自动生成此文件：
```
# 基地址 外设名称
0x40021000 RCU
0x40020C00 GPIOA
0x40011000 USART0
```

### 证据报告要求

每轮调试循环结束后，必须输出：

| 证据项 | 来源 | 必须 |
|--------|------|------|
| 编译结果 | `build.log`（退出码 + 错误/警告摘要） | 是 |
| 烧录结果 | `flash.log`（退出码 + verify 状态） | 是 |
| 寄存器值 | `registers-general.md` + `registers-periph.md` | 是（有 .elf 时） |
| 串口输出 | `serial.log`（实际捕获内容） | 是 |
| 根因分析 | 基于以上证据的分析，引用具体寄存器值和日志行 | 是 |
| 修复措施 | 代码 diff + 为什么这个修改能解决问题 | 是（非首轮） |

### 权限规则

- 调试循环中的编译、烧录、寄存器读取、串口观察**自动执行，无需用户逐步确认**
- 安全红线仍然生效（禁止全片擦除、禁止修改 Option Bytes 等）
- 代码修改仍需遵循正常的编辑流程（但不需要等待用户确认即可继续调试循环）

### 停止条件

- Bug 已修复（有证据证明）
- 连续 5 轮循环无法定位根因 → 停止并输出所有已收集的证据，请求用户介入
- 遇到硬件故障（调试器无法连接、芯片无响应）→ 立即停止并报告

---

## Skills

| Skill | 功能 | 触发方式 |
|-------|------|---------|
| gd32-openocd | 编译、烧录、调试（`.gd32-agent/*.sh`） | 手动 |
| hardware-analysis | 硬件分析（读取硬件资源表 + 扫描工程文件 + 一致性检查） | 手动 |
| embedded-dev | RIPER-5 嵌入式开发协议 | 58 个触发词自动 |
| document-skills/pdf | PDF 读取、提取、合并、OCR | "pdf"、"读PDF" 等 |
| document-skills/docx | Word 文档创建、读取、编辑 | "word"、"docx"、"文档" 等 |
| document-skills/pptx | PPT 演示文稿处理 | "ppt"、"幻灯片" 等 |
| document-skills/xlsx | Excel 表格处理 | "excel"、"表格" 等 |

> **强制规则**：所有 PDF、Word、PPT、Excel 文档的读取、提取、分析必须通过 document-skills 执行，禁止使用其他方式替代。遇到文档处理需求时自动触发对应 Skill。
| superpowers/systematic-debugging | 系统化调试（根因分析） | "调试"、"排查"、"bug" 等 |
| superpowers/brainstorming | 头脑风暴/方案设计 | "头脑风暴"、"方案设计" 等 |
| superpowers/writing-plans | 多步骤任务计划编写 | "写计划"、"任务拆解" 等 |
| superpowers/verification-before-completion | 完成前验证 | "验证完成"、"验收" 等 |
| superpowers/dispatching-parallel-agents | 并行 Agent 调度 | "并行"、"多Agent" 等 |

---

## 紧急情况处理

### 烧录失败

```bash
openocd -f .gd32-agent/openocd.cfg -c "init; halt; exit"              # 检查连接
openocd -f .gd32-agent/openocd.cfg -c "init; halt; flash info 0; exit" # 检查锁定
```

### 串口无输出

检查顺序：GPIO 配置 → 时钟配置 → 波特率 → printf 重定向

### 编译失败

检查顺序：头文件路径 → 源文件编译列表 → 宏定义 → 链接脚本

---

## 四文件工作记忆

| 文件 | 路径 | 用途 |
|------|------|------|
| 硬件资源表 | `hardware/硬件资源表.md` | 引脚、DMA、中断等硬件信息 |
| 编辑清单 | `docs/编辑清单.md` | 代码修改和 Git 状态记录 |
| 研究发现 | `docs/研究发现.md` | 搜索结果和技术方案 |
| 项目规划清单 | `docs/项目规划清单.md` | 项目进度和轮次 |

会话恢复时静默读取四文件，生成简短摘要展示给用户，然后询问"继续上次的工作还是开始新任务？"。详细规则见 `embedded-dev/refs/checklist-mechanism.md`。

---

## 串口模拟触发

对需要外部硬件触发的操作，先通过串口发送模拟命令验证，确认后再改为实际硬件触发。

```bash
# Linux/macOS
echo "BUTTON_PRESS" > /dev/ttyUSB0
echo "SENSOR_VALUE:1234" > /dev/ttyUSB0

# Windows (Git Bash + Python)
python -c "import serial; s=serial.Serial('COM15',115200); s.write(b'BUTTON_PRESS\n'); s.close()"
```

---

## 总结

**核心理念**：硬件文档定事实，流程文档定规矩，AI 负责理解和规划，Bash 负责执行。

**执行顺序**：读取硬件文档 → 扫描工程 → 识别芯片 → 一致性检查 → 执行任务

**安全第一**：任何不确定的情况，必须停止并报告，等待用户确认。

**深入协议**：证据优先、轮次制管理、多 Agent 分工等详细规则见 `embedded-dev/SKILL.md`。
