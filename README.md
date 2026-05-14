# GD32 AI Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/network/members)

> 基于 Claude Code 的 GD32 嵌入式自动化开发 Agent

<!-- [English](./README_EN.md) | -->[中文](./README.md)

## 简介

GD32 AI Agent 是一个基于 Claude Code 的自动化开发工具，专为 GD32 嵌入式开发设计。它能够：

- 🔍 **自动识别** - 自动扫描工程，识别芯片型号、库类型、工程结构
- 🔧 **环境配置** - 自动检测 OpenOCD、GDB、GCC 等工具
- 📝 **文档生成** - 自动生成硬件文档、任务文档、测试文档
- 🚀 **编译烧录** - 一键编译、烧录、调试
- 📊 **日志记录** - 带时间戳的完整日志记录
- 🐛 **Bug 追踪** - 详细的 Bug 修复文档和证据收集

## 快速开始

### 1. 克隆 gd32-agent 仓库

```bash
# 克隆到任意位置（如 D:\tools\gd32-agent）
git clone https://github.com/XDL1234/gd32-agent.git
```

### 2. 安装到你的工程目录

```bash
# 进入你的 GD32 工程目录
cd /path/to/your-gd32-project

# 运行安装脚本，将必要文件拷贝到当前工程目录
bash /path/to/gd32-agent/install.sh
```

### 3. 初始化

在你的工程目录下打开 Claude Code，输入：

```
gd32-agent init
```

或

```
初始化这个 GD32 工程
```

### 4. 配置硬件

初始化向导会自动扫描工程并检测调试器和串口，通过选择题完成配置。你也可以手动编辑 `hardware/hardware.md`：

```markdown
## MCU 信息
- 芯片型号：GD32F470VET6
- 芯片系列：GD32F4xx

## 下载调试接口
- LINK 类型：DAPLink
- 接口协议：SWD

## 串口输出
- 串口号：USART0
- TX：PA9
- RX：PA10
- 波特率：115200
```

### 5. 开始开发

```
帮我实现 USART0 打印启动日志，并烧录验证
```

## 功能特性

### 自动化流程

```
用户需求 → 环境检查 → 工程扫描 → 文档生成 → 任务规划 → 代码修改 → 编译 → 烧录 → 测试 → 报告
```

### 四文件工作记忆机制

本项目采用四文件磁盘工作记忆模式，解决会话中断后的"失忆"问题：

| 文件 | 路径 | 用途 |
|------|------|------|
| **硬件资源表** | `hardware/硬件资源表.md` | 记录芯片、引脚、DMA、中断等硬件信息 |
| **编辑清单** | `docs/编辑清单.md` | 记录每次代码修改和 Git 状态 |
| **研究发现** | `docs/研究发现.md` | 记录搜索结果和技术方案 |
| **项目规划清单** | `docs/项目规划清单.md` | 记录项目整体进度和轮次 |

**会话恢复规则**：每次会话开始时，Agent 静默读取四文件并展示简短摘要，然后询问"继续上次的工作还是开始新任务？"

### 证据优先原则

本项目采用证据优先原则，确保代码质量：

- **验证门机制**：每个完成声明必须有验证证据
- **反自欺检查表**：防止使用模糊语言掩盖不确定性
- **禁止模糊词汇**：禁止使用"应该"、"理论上"、"大概"等词汇

| 声明 | 必须的证据 |
|------|-----------|
| "编译通过" | 编译命令输出 + 退出码 0 |
| "功能正常" | 实际运行结果 / 串口日志 / 示波器波形 |
| "引脚配置正确" | 对照数据手册 + 硬件资源表逐项确认 |

### 多 Agent 分工协作

本项目支持三角色分工协作，适用于复杂任务：

| 角色 | 职责 | 允许操作 |
|------|------|----------|
| **Scout** | 收集证据和约束 | 搜索、分析、报告 |
| **Builder** | 实现代码并验证 | 编写代码、编译、烧录 |
| **Verifier** | 审查和验收 | 审查、评估、报告 |

**适用场景**：
- 需要修改 2 个及以上文件
- 预计需要 2 轮以上编译/烧录/调试
- 任务容易发散或需要中途回退
- 用户明确要求"多 Agent"

**工作流程**：
```
用户需求 → [Scout] 收集证据 → [Builder] 实现验证 → [Verifier] 审查验收
```

详细的多 Agent 分工规则见 `embedded-dev/refs/vibe-workflow.md`。

### Skills 体系

| Skill | 来源 | 功能 | 触发方式 |
|-------|------|------|---------|
| embedded-dev | 自定义 | RIPER-5 嵌入式开发协议 | 58 个触发词自动 |
| gd32-openocd | 自定义 | 编译、烧录、调试 | 手动 |
| hardware-analysis | 自定义 | 硬件分析 | 手动 |
| document-skills | Anthropic 官方 | PDF/Word/PPT/Excel 读取与处理 | "pdf"、"word"、"ppt"、"excel" 等 |
| superpowers | obra/superpowers | 系统化调试、头脑风暴、计划编写、并行 Agent | "调试"、"头脑风暴"、"写计划" 等 |

### 指令层级

```
L1 — CLAUDE.md：安全红线 + 路径配置 + 核心流程（每次会话加载）
L2 — embedded-dev/SKILL.md：完整 RIPER-5 开发协议（Skill 触发时加载）
L3 — embedded-dev/refs/：按需加载的参考文档（API 速查、清单模板等）
```

### 目录结构

```
your-gd32-project/
├── hardware/
│   ├── hardware.md          # 硬件文档（事实源）
│   └── 硬件资源表.md        # 硬件资源记录（引脚、DMA、中断）
├── workflow/
│   └── development-flow.md  # 开发流程
├── docs/
│   ├── 编辑清单.md          # 代码修改记录（会话恢复）
│   ├── 研究发现.md          # 搜索结果记录（会话恢复）
│   └── 项目规划清单.md      # 项目进度记录（会话恢复）
├── embedded-dev/
│   ├── SKILL.md             # RIPER-5 完整协议
│   ├── refs/                # 参考文档（API 速查、编码规范等）
│   └── modes/               # 扩展模式（比赛、网表查阅等）
├── .gd32-agent/
│   ├── config.env           # 工具路径配置
│   ├── openocd.cfg          # OpenOCD 配置
│   ├── check-env.sh         # 环境检查
│   ├── scan-project.sh      # 工程扫描
│   ├── build.sh             # 编译脚本
│   ├── flash.sh             # 烧录脚本
│   ├── serial.sh            # 串口脚本
│   ├── debug.sh             # 调试脚本
│   ├── gen-openocd-cfg.sh   # 自动生成 OpenOCD 配置
│   ├── verify-hardware.sh   # 硬件一致性检查
│   ├── detect-serial.sh     # 串口自动检测
│   └── log-with-timestamp.sh # 日志脚本
├── templates/
│   ├── project/gd32f470vet6/ # GD32F470VET6 工程模板
│   └── *.md                  # 四文件模板
└── .claude/
    └── skills/              # Skills 目录
```

## 使用方法

### 环境检查

```bash
bash .gd32-agent/check-env.sh
```

### 工程扫描

```bash
bash .gd32-agent/scan-project.sh
```

### 编译工程

```bash
# CMake 工程
mkdir -p build && cd build && cmake .. && make

# Make 工程
make clean && make

# Keil 工程
UV4 -b project.uvprojx -o build.log
```

### 烧录固件

```bash
bash .gd32-agent/flash.sh build/app.hex
```

### 串口观察

```bash
bash .gd32-agent/serial.sh COM15 115200 10
```

### 寄存器调试

```bash
bash .gd32-agent/debug.sh build/app.elf
```

### 日志记录

```bash
bash .gd32-agent/log-with-timestamp.sh build SUCCESS "编译完成"
bash .gd32-agent/log-with-timestamp.sh flash SUCCESS "烧录完成"
```

## 文档

- [RIPER-5 开发协议](./embedded-dev/SKILL.md) - 完整嵌入式开发协议
- [GD32F4xx API 速查](./embedded-dev/refs/gd32f4xx-stdperiph-api.md) - GD32 标准库 API 参考
- [多 Agent 分工](./embedded-dev/refs/vibe-workflow.md) - Scout/Builder/Verifier 分工协作

## 支持的硬件

### 芯片系列

- GD32F1xx
- GD32F3xx
- GD32F4xx
- GD32E2xx
- GD32VF103

### 调试器

- ST-LINK
- DAPLink
- J-Link

### 工程类型

- CMake
- Make
- Keil MDK
- IAR

## 贡献

欢迎贡献！请提交 Issue 或 Pull Request。

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](./LICENSE) 文件。

## 致谢

- [anthropics/skills](https://github.com/anthropics/skills) - Claude Skills 体系
- [zhengnianli/EmbedSummary](https://github.com/zhengnianli/EmbedSummary) - 嵌入式开源资源汇总

## 联系方式

- GitHub: [XDL1234](https://github.com/XDL1234)
- Issues: [GitHub Issues](https://github.com/XDL1234/gd32-agent/issues)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=XDL1234/gd32-agent&type=Date)](https://star-history.com/#XDL1234/gd32-agent&Date)
