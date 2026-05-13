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

1. `hardware/hardware.md` - 硬件事实源
2. `workflow/development-flow.md` - 开发流程规则
3. `embedded-dev/SKILL.md` - 完整开发协议

---

## 第一步：读取硬件文档

每次执行任务前，必须先读取 `hardware/hardware.md`，提取：芯片型号、芯片系列、调试器类型、串口配置、风险限制。

---

## 第二步：扫描工程文件

扫描启动文件(`startup_*.s`)、链接脚本(`*.ld`)、头文件(`gd32*.h`)、CMakeLists.txt、Makefile、源码头文件引用，识别芯片型号。

识别优先级：启动文件名 → 链接脚本 → 头文件 → CMakeLists.txt → 源码引用。

识别完成后自动更新 `hardware/hardware.md` 中 AI 可推断的字段。

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
| GD32F1xx | gd32f1x.cfg |
| GD32F3xx | gd32f3x.cfg |
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
bash .gd32-agent/debug.sh build/app.elf      # 寄存器调试
bash .gd32-agent/log-with-timestamp.sh <type> <status> "<message>"  # 日志
```

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

## Skills

| Skill | 功能 |
|-------|------|
| gd32-openocd | 编译、烧录、调试（`.gd32-agent/*.sh`） |
| hardware-analysis | 硬件分析（读取 hardware.md + 扫描工程文件 + 一致性检查） |

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

会话恢复时按顺序读取四文件，回答五问后才能继续工作。详细规则见 `embedded-dev/refs/checklist-mechanism.md`。

---

## 串口模拟触发

对需要外部硬件触发的操作，先通过串口发送模拟命令验证，确认后再改为实际硬件触发。

```bash
echo "BUTTON_PRESS" > /dev/ttyUSB0    # 模拟按键
echo "SENSOR_VALUE:1234" > /dev/ttyUSB0 # 模拟传感器
```

---

## 总结

**核心理念**：硬件文档定事实，流程文档定规矩，AI 负责理解和规划，Bash 负责执行。

**执行顺序**：读取硬件文档 → 扫描工程 → 识别芯片 → 一致性检查 → 执行任务

**安全第一**：任何不确定的情况，必须停止并报告，等待用户确认。

**深入协议**：证据优先、轮次制管理、多 Agent 分工等详细规则见 `embedded-dev/SKILL.md`。
