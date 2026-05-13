# GD32 AI Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/XDL1234/gd32-ai-openocd-agent.svg)](https://github.com/XDL1234/gd32-ai-openocd-agent/network/members)

> Claude Code based GD32 embedded automation development Agent

[English](./README_EN.md) | [中文](./README.md)

## Introduction

GD32 AI Agent is an automation development tool based on Claude Code, specifically designed for GD32 embedded development. It can:

- 🔍 **Auto Detection** - Automatically scan projects, identify chip model, library type, project structure
- 🔧 **Environment Setup** - Auto-detect OpenOCD, GDB, GCC and other tools
- 📝 **Document Generation** - Auto-generate hardware docs, task docs, test docs
- 🚀 **Build & Flash** - One-click build, flash, debug
- 📊 **Logging** - Complete logging with timestamps
- 🐛 **Bug Tracking** - Detailed bug fix documentation and evidence collection

## Quick Start

### 1. Clone Project

```bash
git clone https://github.com/XDL1234/gd32-ai-openocd-agent.git
cd gd32-ai-openocd-agent
```

### 2. Initialize

In Claude Code, type:

```
/gd32-ai-agent init
```

or

```
Initialize this GD32 project
```

### 3. Configure Hardware

Edit `hardware/hardware.md`, fill in your hardware information:

```markdown
## MCU Information
- Chip Model: GD32F470VET6
- Chip Series: GD32F4xx

## Debug Interface
- LINK Type: DAPLink
- Protocol: SWD

## Serial Output
- Serial Port: USART0
- TX: PA9
- RX: PA10
- Baudrate: 115200
```

### 4. Start Development

```
Help me implement USART0 boot log printing, and verify with flash
```

## Features

### Automation Flow

```
User Requirement → Environment Check → Project Scan → Document Generation → Task Planning → Code Modification → Build → Flash → Test → Report
```

### Skills System

| Skill | Source | Function |
|-------|--------|----------|
| document-skills | [anthropics/skills](https://github.com/anthropics/skills) | Document Processing |
| superpowers-skills | [obra/superpowers](https://github.com/obra/superpowers) | Task Orchestration |
| find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills) | Skill Discovery |
| pua-skills | [tanweai/pua](https://github.com/tanweai/pua) | AI Agent Pressure Drive |
| gd32-openocd | Custom | Build, Flash, Debug |
| hardware-analysis | Custom | Hardware Analysis |

### Directory Structure

```
your-gd32-project/
├── hardware/
│   └── hardware.md          # Hardware Document
├── workflow/
│   └── development-flow.md  # Development Flow
├── docs/
│   ├── analysis/            # Analysis Documents
│   ├── tasks/               # Task Documents
│   ├── reviews/             # Review Documents
│   ├── bugs/                # Bug Documents
│   └── testing/             # Test Documents
├── .gd32-agent/
│   ├── openocd.cfg          # OpenOCD Config
│   ├── check-env.sh         # Environment Check
│   ├── scan-project.sh      # Project Scan
│   ├── flash.sh             # Flash Script
│   ├── serial.sh            # Serial Script
│   ├── debug.sh             # Debug Script
│   └── log-with-timestamp.sh # Log Script
└── .claude/
    └── skills/              # Skills Directory
```

## Usage

### Environment Check

```bash
bash .gd32-agent/check-env.sh
```

### Project Scan

```bash
bash .gd32-agent/scan-project.sh
```

### Build Project

```bash
# CMake Project
mkdir -p build && cd build && cmake .. && make

# Make Project
make clean && make

# Keil Project
UV4 -b project.uvprojx -o build.log
```

### Flash Firmware

```bash
bash .gd32-agent/flash.sh build/app.hex
```

### Serial Monitor

```bash
bash .gd32-agent/serial.sh COM15 115200 10
```

### Register Debug

```bash
bash .gd32-agent/debug.sh build/app.elf
```

### Logging

```bash
bash .gd32-agent/log-with-timestamp.sh build SUCCESS "Build completed"
bash .gd32-agent/log-with-timestamp.sh flash SUCCESS "Flash completed"
```

## Documentation

- [User Guide](./docs/user-guide.md) - Detailed usage instructions
- [Design Document](./docs/方案设计.md) - Technical design
- [Task Review](./docs/task-review.md) - Task completion status
- [Requirements Analysis](./docs/需求对比分析.md) - Requirements analysis

## Supported Hardware

### Chip Series

- GD32F1xx
- GD32F3xx
- GD32F4xx
- GD32E2xx
- GD32VF103

### Debuggers

- ST-LINK
- DAPLink
- J-Link

### Project Types

- CMake
- Make
- Keil MDK
- IAR

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file.

## Acknowledgments

- [anthropics/skills](https://github.com/anthropics/skills) - Document Processing Skills
- [obra/superpowers](https://github.com/obra/superpowers) - Task Orchestration Skills
- [vercel-labs/skills](https://github.com/vercel-labs/skills) - Skill Discovery
- [tanweai/pua](https://github.com/tanweai/pua) - AI Agent Pressure Drive

## Contact

- GitHub: [XDL1234](https://github.com/XDL1234)
- Issues: [GitHub Issues](https://github.com/XDL1234/gd32-ai-openocd-agent/issues)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=XDL1234/gd32-ai-openocd-agent&type=Date)](https://star-history.com/#XDL1234/gd32-ai-openocd-agent&Date)
