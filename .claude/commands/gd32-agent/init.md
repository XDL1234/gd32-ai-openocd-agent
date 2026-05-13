# GD32 AI Agent 初始化指令

## 指令说明

输入 `/gd32-agent init` 进行 GD32 工程初始化。

## 执行流程

### Step 0: 自动安装检测

首先检测当前目录是否已安装 GD32 AI Agent 的必要文件。如果没有，自动从克隆的仓库中复制。

**检测是否已安装**：
```bash
# 检查必要文件是否存在
if [ ! -f ".gd32-agent/check-env.sh" ] || [ ! -f ".gd32-agent/build.sh" ]; then
    echo "检测到 GD32 AI Agent 未安装，正在自动安装..."

    # 查找 gd32-agent 仓库位置
    # 可能在当前目录的子目录中，或者用户已克隆到其他位置
    AGENT_DIR=""

    # 检查当前目录下是否有 gd32-agent 文件夹
    if [ -d "gd32-agent" ] && [ -f "gd32-agent/install.sh" ]; then
        AGENT_DIR="gd32-agent"
    # 检查上级目录
    elif [ -f "../gd32-agent/install.sh" ]; then
        AGENT_DIR="../gd32-agent"
    # 检查环境变量
    elif [ -n "$GD32_AGENT_PATH" ] && [ -f "$GD32_AGENT_PATH/install.sh" ]; then
        AGENT_DIR="$GD32_AGENT_PATH"
    fi

    if [ -n "$AGENT_DIR" ]; then
        echo "找到 gd32-agent 仓库: $AGENT_DIR"
        bash "$AGENT_DIR/install.sh"
    else
        echo "❌ 未找到 gd32-agent 仓库"
        echo ""
        echo "请先克隆 gd32-agent 仓库："
        echo "  git clone https://github.com/XDL1234/gd32-agent.git"
        echo ""
        echo "然后将克隆的文件夹放到以下位置之一："
        echo "  1. 当前工程目录下（gd32-agent/）"
        echo "  2. 上级目录（../gd32-agent/）"
        echo "  3. 或设置环境变量 GD32_AGENT_PATH 指向仓库路径"
        echo ""
        echo "完成后再次运行: /gd32-agent init"
        exit 1
    fi
else
    echo "✅ GD32 AI Agent 已安装"
fi
```

**安装完成后继续执行后续步骤。**

### Step 1: 环境配置检查

扫描用户电脑，检查以下工具是否安装：

1. **OpenOCD** - 用于烧录和调试
2. **GDB** - 用于调试
3. **GCC** - 用于编译（可选）
4. **Python** - 用于串口工具
5. **pyserial** - 用于串口通信

**检查方法**：
```bash
# 检查 OpenOCD
where openocd 2>/dev/null || echo "OpenOCD 未安装"

# 检查 GDB
where arm-none-eabi-gdb 2>/dev/null || echo "GDB 未安装"

# 检查 Python
where python 2>/dev/null || echo "Python 未安装"

# 检查 pyserial
python -c "import serial" 2>/dev/null || echo "pyserial 未安装"
```

**如果缺少工具**，提醒用户并提供选择：
1. 自动安装
2. 手动安装
3. 其他

### Step 2: 工程扫描

扫描用户工程目录，识别：

1. **芯片型号** - 从启动文件、链接脚本、头文件识别
2. **库类型** - 标准库/HAL 库
3. **工程类型** - CMake/Make/IDE

**扫描方法**：
```bash
# 扫描启动文件
find . -name "startup_*.s" | head -5

# 扫描链接脚本
find . -name "*.ld" | head -5

# 扫描头文件
find . -name "gd32*.h" -o -name "stm32*.h" | head -5

# 扫描 HAL 库特征
find . -name "stm32f4xx_hal*.h" | head -5

# 扫描标准库特征
find . -name "gd32f4xx*.h" | head -5
```

**识别规则**：
| 特征 | 库类型 |
|------|--------|
| `gd32f4xx*.h` | 标准库 |
| `stm32f4xx_hal*.h` | HAL 库 |
| `startup_gd32*.s` | 标准库 |
| `startup_stm32*.s` | HAL 库 |

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
- 提示用户完成后再使用 `/gd32-agent init`

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

#### 6.1 hardware/hardware.md

根据扫描结果生成硬件文档：

```markdown
# 硬件文档

## MCU 信息

- 芯片型号：GD32F470VET6  # AI 识别
- 芯片系列：GD32F4xx      # AI 识别
- 内核：Cortex-M4          # AI 推断
- 主频：168MHz             # 用户填写
- Flash：512KB             # AI 识别
- SRAM：256KB              # AI 识别

## 下载调试接口

- LINK 类型：DAPLink       # 用户填写
- 接口协议：SWD            # 用户填写
- 默认下载速度：1000 kHz   # 用户填写

## 时钟配置

- 外部晶振：8MHz           # 用户填写
- 系统主频：168MHz         # 用户填写

## 外设资源

| 外设 | 用途 | 引脚 | 备注 |
|------|------|------|------|
| USART0 | 调试串口 | PA__/PA__ | 波特率 115200 |
| GPIO | LED | P__ | 低电平亮 |
| I2C0 | 传感器 | PB__/PB__ | 400kHz |
| SPI0 | Flash | PA__/PA__/PA__ | Mode 0 |

## 串口输出

- 串口号：USART0          # 用户填写
- TX：PA__                 # 用户填写
- RX：PA__                 # 用户填写
- 波特率：115200           # 用户填写

## 风险限制

- 是否允许全片擦除：否
- 是否允许修改 Option Bytes：否
- 是否允许解除读保护：否
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
- hardware/hardware.md
- workflow/development-flow.md
- docs/analysis/project-scan-report.md
- .claude/skills/document-skills/SKILL.md
- .claude/skills/gd32-openocd/SKILL.md
- .claude/skills/hardware-analysis/SKILL.md
- .claude/skills/superpowers-skills/SKILL.md
- .claude/skills/find-skills/SKILL.md
- .claude/skills/pua-skills/SKILL.md

## 下一步
1. 编辑 hardware/hardware.md，填写引脚信息
2. 编辑 workflow/development-flow.md，填写用户需求
3. 开始开发任务
```

---

## 使用方法

在 Claude Code 中输入：

```
/gd32-agent init
```

或

```
初始化这个 GD32 工程
```
