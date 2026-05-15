# GD32 AI Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/XDL1234/gd32-agent.svg)](https://github.com/XDL1234/gd32-agent/network/members)

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

### 1. Clone gd32-agent repository

```bash
# Clone to any location (e.g., D:\tools\gd32-agent)
git clone https://github.com/XDL1234/gd32-agent.git
```

### 2. Install to your project directory

```bash
# Enter your GD32 project directory
cd /path/to/your-gd32-project

# Run install script to copy necessary files to current project directory
bash /path/to/gd32-agent/install.sh
```

### 3. Initialize

Open Claude Code in your project directory, type:

```
gd32-agent init
```

or

```
Initialize this GD32 project
```

### 4. Configure Hardware

Edit `hardware/硬件资源表.md`, fill in your hardware information:

```markdown
## MCU Information

| Parameter | Value |
|-----------|-------|
| Chip Model | GD32F470VET6 |
| Chip Series | GD32F4xx |

## Debug Interface

| Parameter | Value |
|-----------|-------|
| LINK Type | DAPLink |
| Protocol | SWD |

## Serial Output

| Parameter | Value |
|-----------|-------|
| Serial Port | USART0 |
| TX | PA9 |
| RX | PA10 |
| Baudrate | 115200 |
```

### 5. Start Development

```
Help me implement USART0 boot log printing, and verify with flash
```

## Features

### Automation Flow

```
User Requirement → Environment Check → Project Scan → Document Generation → Task Planning → Code Modification → Build → Flash → Test → Report
```

### Four-File Working Memory Mechanism

This project uses a four-file disk working memory pattern to solve the "memory loss" problem after session interruptions:

| File | Path | Purpose |
|------|------|---------|
| **Hardware Resource Table** | `hardware/硬件资源表.md` | Record chip, pins, DMA, interrupts |
| **Edit Log** | `docs/编辑清单.md` | Record every code modification and Git status |
| **Research Findings** | `docs/研究发现.md` | Record search results and technical solutions |
| **Project Planning** | `docs/项目规划清单.md` | Record overall project progress |

**Session Recovery Rules**: At the start of each session, answer the Five-Question Restart Test:
1. What stage am I in?
2. What was the last code modification?
3. Are chip model and pin assignment confirmed?
4. What did previous searches find?
5. Where should I continue?

### Evidence-First Principle

This project adopts an evidence-first principle to ensure code quality:

- **Verification Gate**: Every completion claim must have verification evidence
- **Anti-Self-Deception Checklist**: Prevent using vague language to mask uncertainty
- **Prohibited Vague Words**: Words like "should", "theoretically", "probably" are prohibited

| Claim | Required Evidence |
|-------|-------------------|
| "Build passed" | Build command output + exit code 0 |
| "Function works" | Actual runtime result / serial log / oscilloscope waveform |
| "Pin config correct" | Cross-check with datasheet + hardware resource table |

### Multi-Agent Collaboration

This project supports three-role collaboration for complex tasks:

| Role | Responsibility | Allowed Operations |
|------|----------------|-------------------|
| **Scout** | Collect evidence and constraints | Search, analyze, report |
| **Builder** | Implement code and verify | Write code, compile, flash |
| **Verifier** | Review and accept | Review, evaluate, report |

**When to use**:
- Need to modify 2 or more files
- Expected 2+ rounds of compile/flash/debug
- Task prone to divergence or needs mid-way rollback
- User explicitly requests "multi-agent"

**Workflow**:
```
User Requirement → [Scout] Collect Evidence → [Builder] Implement & Verify → [Verifier] Review & Accept
```

Detailed multi-agent workflow: `docs/multi-agent-workflow.md`

### Skills System

| Skill | Source | Function | Trigger |
|-------|--------|----------|---------|
| embedded-dev | Custom | RIPER-5 Embedded Development Protocol | 58 trigger words (auto) |
| gd32-openocd | Custom | Build, Flash, Debug | Manual |
| hardware-analysis | Custom | Hardware Analysis | Manual |
| document-skills | [anthropics/skills](https://github.com/anthropics/skills) | PDF/Word/PPT/Excel Processing | "pdf", "word", "ppt", "excel" etc. |
| superpowers | [obra/superpowers](https://github.com/obra/superpowers) | Systematic Debugging, Brainstorming, Planning, Parallel Agents | "debug", "brainstorm", "plan" etc. |

### Instruction Hierarchy

```
L1 — CLAUDE.md: Safety rules + path config + core flow (loaded every session)
L2 — embedded-dev/SKILL.md: Complete RIPER-5 protocol (loaded when Skill triggers)
L3 — embedded-dev/refs/: On-demand reference docs (API reference, templates, etc.)
```

### Directory Structure

```
your-gd32-project/
├── hardware/
│   └── 硬件资源表.md        # Hardware Resource Table (pins, DMA, interrupts)
├── workflow/
│   └── development-flow.md  # Development Flow
├── docs/
│   ├── analysis/            # Analysis Documents
│   ├── tasks/               # Task Documents
│   ├── reviews/             # Review Documents
│   ├── bugs/                # Bug Documents
│   ├── testing/             # Test Documents
│   ├── 编辑清单.md          # Edit Log (session recovery)
│   ├── 研究发现.md          # Research Findings (session recovery)
│   └── 项目规划清单.md      # Project Planning (session recovery)
├── .gd32-agent/
│   ├── config.env           # Configuration
│   ├── openocd.cfg          # OpenOCD Config
│   ├── check-env.sh         # Environment Check
│   ├── scan-project.sh      # Project Scan
│   ├── build.sh             # Build Script
│   ├── flash.sh             # Flash Script
│   ├── serial.sh            # Serial Script
│   ├── debug.sh             # Debug Script (general/peripheral/batch modes)
│   ├── debug-loop.sh        # Auto Debug Loop (build→flash→registers→serial)
│   ├── probe-chip.sh        # Chip Hardware Probe (read DBGMCU_IDCODE via OpenOCD)
│   ├── gd32-chip-db.sh      # GD32 Chip ID Database
│   ├── gen-openocd-cfg.sh   # Auto-generate OpenOCD Config
│   ├── verify-hardware.sh   # Hardware Consistency Check
│   ├── detect-serial.sh     # Serial Port Auto-detection
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

### Chip Hardware Probe

Read DBGMCU_IDCODE / Flash Size / Unique ID directly from the chip via OpenOCD:

```bash
bash .gd32-agent/probe-chip.sh                    # Auto probe
bash .gd32-agent/probe-chip.sh --interface daplink # Specify debugger type
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
- [RIPER-5 Protocol](./embedded-dev/SKILL.md) - Complete embedded development protocol
- [GD32F4xx API Reference](./embedded-dev/refs/gd32f4xx-stdperiph-api.md) - GD32 Standard Library API
- [Multi-Agent Workflow](./embedded-dev/refs/vibe-workflow.md) - Scout/Builder/Verifier collaboration

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

- [anthropics/skills](https://github.com/anthropics/skills) - Claude Skills System
- [zhengnianli/EmbedSummary](https://github.com/zhengnianli/EmbedSummary) - Embedded Open Source Resources

## Contact

- GitHub: [XDL1234](https://github.com/XDL1234)
- Issues: [GitHub Issues](https://github.com/XDL1234/gd32-agent/issues)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=XDL1234/gd32-agent&type=Date)](https://star-history.com/#XDL1234/gd32-agent&Date)
