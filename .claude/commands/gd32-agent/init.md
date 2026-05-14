# GD32 AI Agent 初始化指令

## 指令说明

输入 `gd32-agent init` 进行 GD32 工程初始化。

## 前置条件

在运行此指令之前，请确保已经使用 `install.sh` 脚本将必要的文件拷贝到当前工程目录：

```bash
# 克隆 gd32-agent 仓库到任意位置
git clone https://github.com/XDL1234/gd32-agent.git

# 进入你的工程目录
cd /path/to/your-project

# 运行安装脚本，将文件拷贝到当前工程目录
bash /path/to/gd32-agent/install.sh
```

## 执行流程

### Step 0: 会话恢复检查（静默恢复）

首先检查是否存在四文件，如果存在则执行静默恢复：

**检查四文件是否存在**：
```bash
# 检查四文件
test -f "docs/项目规划清单.md" && echo "项目规划清单存在" || echo "项目规划清单不存在"
test -f "docs/编辑清单.md" && echo "编辑清单存在" || echo "编辑清单不存在"
test -f "hardware/硬件资源表.md" && echo "硬件资源表存在" || echo "硬件资源表不存在"
test -f "docs/研究发现.md" && echo "研究发现存在" || echo "研究发现不存在"
```

**如果四文件存在**，执行静默恢复：

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
   - "新任务" → 继续执行 Step 1

**如果四文件不存在**，继续执行 Step 1。

### Step 1: 环境配置检查

扫描用户电脑，检查以下工具是否安装：

1. **OpenOCD** - 用于烧录和调试
2. **GDB** - 用于调试
3. **GCC** - 用于编译（可选）
4. **Python** - 用于串口工具
5. **pyserial** - 用于串口通信

**检查方法**：
```bash
bash .gd32-agent/check-env.sh
```

**如果缺少工具**，提醒用户并提供安装建议。

### Step 2: 工程扫描与自动配置

扫描用户工程目录并自动回填配置：

```bash
bash .gd32-agent/scan-project.sh
```

扫描完成后，**主动向用户确认以下信息**（以选择题形式）：

1. **调试器类型**（如果硬件资源表未填写）：
   - [1] DAPLink
   - [2] ST-Link
   - [3] J-Link

2. **串口端口**（展示自动检测到的端口，让用户确认）：
   ```bash
   bash .gd32-agent/detect-serial.sh
   ```

3. **确认芯片型号**（展示扫描结果，让用户确认或修正）

用户确认后，自动执行：
- 更新 `.gd32-agent/config.env`（串口、OpenOCD 路径）
- 生成 `.gd32-agent/openocd.cfg`（根据调试器和芯片系列）：
  ```bash
  bash .gd32-agent/gen-openocd-cfg.sh
  ```
- 更新 `hardware/硬件资源表.md`（芯片型号、调试器、串口配置）

### Step 3: 生成工程文档

生成 `docs/analysis/project-scan-report.md`，包含：

```markdown
# 工程扫描报告

## 扫描时间
2024-XX-XX XX:XX:XX

## 工程信息
- 工程路径：/path/to/project
- 工程类型：CMake/Make/IDE

## 芯片信息
- 芯片型号：GD32F470VET6
- 芯片系列：GD32F4xx
- 内核：Cortex-M4

## 库类型
- 类型：标准库/HAL 库
- 依据：发现 gd32f4xx.h

## 文件结构
- 启动文件：startup_gd32f450_470.s
- 链接脚本：gd32f470zk_flash.ld
- 头文件：gd32f4xx.h

## 确认选项
1. 分析正确
2. 分析有误，再次分析
3. 用户自己描述问题在哪
```

### Step 4: 用户确认

等待用户确认扫描结果：

**如果用户选择 "分析正确"**：
- 继续执行 Step 5

**如果用户选择 "分析有误，再次分析"**：
- 重新扫描工程
- 提示用户指出问题所在

**如果用户选择 "用户自己描述问题在哪"**：
- 等待用户输入问题描述
- 根据用户描述调整分析

**如果没有读取到工程文件**：
- 提醒用户创立好工程文件
- 提示用户完成后再使用 `gd32-agent init`

### Step 5: 创建目录结构

在用户工程目录下创建以下文件夹：

```bash
# 创建 hardware 文件夹
mkdir -p hardware

# 创建 docs 文件夹
mkdir -p docs/{analysis,tasks,reviews,bugs,testing}

# 创建 workflow 文件夹
mkdir -p workflow

# 创建 skills 文件夹
mkdir -p .claude/skills
```

### Step 6: 生成文档文件

#### 6.1 hardware/硬件资源表.md

根据扫描结果生成硬件文档（表格形式，方便填写）：

```markdown
# 硬件资源表

## 芯片与开发环境

| 参数 | 值 | 来源 |
|------|------|------|
| 芯片型号 | GD32F470VET6 | AI 识别 |
| 芯片系列 | GD32F4xx | AI 识别 |
| 内核 | Cortex-M4 | AI 推断 |
| 主频 | 168MHz | 用户填写 |
| Flash | 512KB | AI 识别 |
| SRAM | 256KB | AI 识别 |

## 下载调试接口

| 参数 | 值 | 来源 |
|------|------|------|
| LINK 类型 | DAPLink | 用户填写 |
| 接口协议 | SWD | 用户填写 |
| 下载速度 | 10000 kHz | 用户填写 |

## 时钟配置

| 参数 | 值 | 来源 |
|------|------|------|
| 外部晶振 | 8MHz | 用户填写 |
| 系统主频 | 168MHz | 用户填写 |

## 外设资源

| 外设 | 用途 | 引脚 | 备注 |
|------|------|------|------|
| USART0 | 调试串口 | PA9(TX)/PA10(RX) | 波特率 115200 |
| GPIO | LED | P__ | 低电平亮 |
| I2C0 | 传感器 | PB__/PB__ | 400kHz |
| SPI0 | Flash | PA__/PA__/PA__ | Mode 0 |

## 串口输出

| 参数 | 值 | 来源 |
|------|------|------|
| 串口号 | USART0 | 用户填写 |
| TX | PA9 | 用户填写 |
| RX | PA10 | 用户填写 |
| 波特率 | 115200 | 用户填写 |

## 风险限制

| 操作 | 是否允许 |
|------|---------|
| 全片擦除 | 否 |
| 修改 Option Bytes | 否 |
| 解除读保护 | 否 |
```

#### 6.2 workflow/development-flow.md

生成开发流程文档：

```markdown
# 开发流程文档

## 用户需求区域

（在此填写用户需求，Agent 会根据需求调整开发流程）

---

## 最高优先级规则

必须严格遵守本文件。如果冲突，必须停止并报告。

## 标准开发流程

1. 读取硬件文档
2. 扫描工程目录
3. 生成工程分析文档
4. 根据用户需求生成任务文档
5. 使用 Plan Mode 制定执行计划
6. 用户确认计划后再修改代码
7. 修改代码后进行代码审查
8. 编译工程
9. 使用 OpenOCD 下载烧录
10. 观察串口输出
11. 观察寄存器和 GDB 状态
12. 根据日志和寄存器结果查找 bug
13. 生成任务结果文档

## 禁止行为

- 禁止未确认直接全片擦除
- 禁止未确认修改 Option Bytes
- 禁止未确认解除读保护
- 禁止跳过硬件文档直接修改代码
- 禁止编译失败后继续烧录
```

#### 6.3 Skills 文件

复制默认 Skills 到用户工程：

```bash
# 复制 Skills
cp -r .claude/skills/* user-project/.claude/skills/
```

### Step 7: 完成初始化

显示初始化结果：

```markdown
# 初始化完成

## 创建的目录
- hardware/
- docs/
- workflow/
- .claude/skills/

## 创建的文件
- hardware/硬件资源表.md
- workflow/development-flow.md
- docs/analysis/project-scan-report.md
- .claude/skills/gd32-openocd/SKILL.md
- .claude/skills/hardware-analysis/SKILL.md
- .claude/skills/document-skills/（PDF/Word/PPT/Excel 等）
- .claude/skills/superpowers-skills/（系统化调试/头脑风暴等）

## 下一步
1. 编辑 hardware/硬件资源表.md，填写引脚信息
2. 编辑 workflow/development-flow.md，填写用户需求
3. 开始开发任务
```

---

## 使用方法

在 Claude Code 中输入：

```
gd32-agent init
```

或

```
初始化这个 GD32 工程
```
