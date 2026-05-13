# GD32 AI Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/network/members)

> 基于 Claude Code 的 GD32 嵌入式自动化开发 Agent

[English](./README_EN.md) | [中文](./README.md)

## 简介

GD32 AI Agent 是一个基于 Claude Code 的自动化开发工具，专为 GD32 嵌入式开发设计。它能够：

- 🔍 **自动识别** - 自动扫描工程，识别芯片型号、库类型、工程结构
- 🔧 **环境配置** - 自动检测 OpenOCD、GDB、GCC 等工具
- 📝 **文档生成** - 自动生成硬件文档、任务文档、测试文档
- 🚀 **编译烧录** - 一键编译、烧录、调试
- 📊 **日志记录** - 带时间戳的完整日志记录
- 🐛 **Bug 追踪** - 详细的 Bug 修复文档和证据收集

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/XDL1234/gd32-ai-openocd-agent.git
cd gd32-ai-openocd-agent
```

### 2. 初始化

在 Claude Code 中输入：

```
/gd32-ai-agent init
```

或

```
初始化这个 GD32 工程
```

### 3. 配置硬件

编辑 `hardware/hardware.md`，填写你的硬件信息：

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

### 4. 开始开发

```
帮我实现 USART0 打印启动日志，并烧录验证
```

## 功能特性

### 自动化流程

```
用户需求 → 环境检查 → 工程扫描 → 文档生成 → 任务规划 → 代码修改 → 编译 → 烧录 → 测试 → 报告
```

### Skills 体系

| Skill | 来源 | 功能 |
|-------|------|------|
| document-skills | [anthropics/skills](https://github.com/anthropics/skills) | 文档处理 |
| superpowers-skills | [obra/superpowers](https://github.com/obra/superpowers) | 任务编排 |
| find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills) | 技能发现 |
| pua-skills | [tanweai/pua](https://github.com/tanweai/pua) | AI 代理压力驱动 |
| gd32-openocd | 自定义 | 编译、烧录、调试 |
| hardware-analysis | 自定义 | 硬件分析 |

### 目录结构

```
your-gd32-project/
├── hardware/
│   └── hardware.md          # 硬件文档
├── workflow/
│   └── development-flow.md  # 开发流程
├── docs/
│   ├── analysis/            # 分析文档
│   ├── tasks/               # 任务文档
│   ├── reviews/             # 审查文档
│   ├── bugs/                # Bug 文档
│   └── testing/             # 测试文档
├── .gd32-agent/
│   ├── openocd.cfg          # OpenOCD 配置
│   ├── check-env.sh         # 环境检查
│   ├── scan-project.sh      # 工程扫描
│   ├── flash.sh             # 烧录脚本
│   ├── serial.sh            # 串口脚本
│   ├── debug.sh             # 调试脚本
│   └── log-with-timestamp.sh # 日志脚本
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

- [用户指南](./docs/user-guide.md) - 详细的使用说明
- [方案设计](./docs/方案设计.md) - 技术方案设计
- [任务审查](./docs/task-review.md) - 任务完成情况
- [需求对比](./docs/需求对比分析.md) - 需求分析

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

欢迎贡献！请查看 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](./LICENSE) 文件。

## 致谢

- [anthropics/skills](https://github.com/anthropics/skills) - 文档处理 Skills
- [obra/superpowers](https://github.com/obra/superpowers) - 任务编排 Skills
- [vercel-labs/skills](https://github.com/vercel-labs/skills) - 技能发现
- [tanweai/pua](https://github.com/tanweai/pua) - AI 代理压力驱动

## 联系方式

- GitHub: [XDL1234](https://github.com/XDL1234)
- Issues: [GitHub Issues](https://github.com/XDL1234/gd32-ai-openocd-agent/issues)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=XDL1234/gd32-ai-openocd-agent&type=Date)](https://star-history.com/#XDL1234/gd32-ai-openocd-agent&Date)
