# GD32 AI Agent 任务执行规则

你正在协助用户开发 GD32 嵌入式工程。必须严格遵守以下规则。

---

## 最高优先级

必须严格遵守以下文档，如果冲突，必须停止并报告：

1. `hardware/hardware.md` - 硬件事实源
2. `workflow/development-flow.md` - 开发流程规则

---

## 第一步：读取硬件文档

每次执行任务前，必须先读取硬件文档：

```bash
cat hardware/hardware.md
```

提取关键信息：
- 芯片型号
- 芯片系列
- 调试器类型
- 串口配置
- 风险限制

---

## 第二步：扫描工程文件

扫描工程目录，识别芯片型号：

```bash
# 1. 扫描启动文件
find . -name "startup_*.s" | head -5

# 2. 扫描链接脚本
find . -name "*.ld" | head -5

# 3. 扫描头文件
find . -name "gd32*.h" | head -5

# 4. 扫描 CMakeLists.txt
grep -r "GD32" CMakeLists.txt 2>/dev/null

# 5. 扫描 Makefile
grep -r "GD32" Makefile 2>/dev/null

# 6. 扫描源码头文件引用
grep -r "#include.*gd32" src/ inc/ 2>/dev/null
```

### 识别规则

| 来源 | 文件 | 识别内容 |
|------|------|----------|
| 启动文件 | `startup_*.s` | 芯片系列（GD32F10x、GD32F30x 等） |
| 链接脚本 | `*.ld` | Flash/SRAM 大小、起始地址 |
| 头文件 | `gd32*.h` | 芯片系列宏定义 |
| CMakeLists.txt | `CMakeLists.txt` | 芯片型号宏（GD32F103C8T6） |
| 源码 | `main.c` | 头文件引用 |

### 识别优先级

1. 启动文件名 → 芯片系列
2. 链接脚本 → Flash/SRAM
3. 头文件 → 芯片系列
4. CMakeLists.txt → 芯片型号
5. 源码头文件引用 → 芯片系列

### 自动更新 hardware.md

当 AI 识别到芯片型号后，自动更新 `hardware/hardware.md`：

```markdown
# 硬件文档

## MCU 信息
- 芯片型号：GD32F470VET6  <!-- AI 识别 -->
- 芯片系列：GD32F4xx      <!-- AI 识别 -->
- 内核：Cortex-M4          <!-- AI 推断 -->
- Flash：512KB              <!-- AI 识别 -->
- SRAM：256KB               <!-- AI 识别 -->
- Flash 起始地址：0x08000000 <!-- AI 识别 -->

## 下载调试接口
- LINK 类型：DAPLink       <!-- 用户填写 -->
- 接口协议：SWD            <!-- 用户填写 -->
- 默认下载速度：1000 kHz   <!-- 用户填写 -->

## 串口输出
- 串口号：USART0           <!-- 用户填写 -->
- TX：PA9                  <!-- 用户填写 -->
- RX：PA10                 <!-- 用户填写 -->
- 波特率：115200           <!-- 用户填写 -->

## 风险限制
- 是否允许全片擦除：否     <!-- 用户填写 -->
- 是否允许修改 Option Bytes：否 <!-- 用户填写 -->
- 是否允许解除读保护：否   <!-- 用户填写 -->
```

### 识别规则

| 来源 | 文件 | 识别内容 |
|------|------|----------|
| 启动文件 | `startup_*.s` | 芯片系列（GD32F10x、GD32F30x 等） |
| 链接脚本 | `*.ld` | Flash/SRAM 大小、起始地址 |
| 头文件 | `gd32*.h` | 芯片系列宏定义 |
| CMakeLists.txt | `CMakeLists.txt` | 芯片型号宏（GD32F103C8T6） |
| 源码 | `main.c` | 头文件引用 |

---

## 第三步：一致性检查

将 AI 识别结果与硬件文档对比：

```markdown
| 项目 | 硬件文档 | AI 识别 | 结果 |
|------|----------|---------|------|
| 芯片型号 | ? | ? | 一致/冲突 |
| 芯片系列 | ? | ? | 一致/冲突 |
| Flash | ? | ? | 一致/冲突 |
| SRAM | ? | ? | 一致/冲突 |
```

### 冲突处理

如果硬件文档与 AI 识别结果冲突：
1. **停止执行**
2. **报告冲突详情**
3. **要求用户确认**
4. **用户确认后继续**

---

## 第四步：自动生成 OpenOCD 配置

根据识别结果，生成 `.gd32-agent/openocd.cfg`：

```bash
mkdir -p .gd32-agent

# 根据调试器类型生成配置
# ST-LINK
cat > .gd32-agent/openocd.cfg << 'EOF'
source [find interface/stlink.cfg]
source [find target/gd32f1x.cfg]
adapter speed 1000
EOF

# DAPLink
# source [find interface/cmsis-dap.cfg]

# J-Link
# source [find interface/jlink.cfg]
```

### 调试器配置映射

| 调试器 | OpenOCD 配置 |
|--------|--------------|
| ST-LINK | interface/stlink.cfg |
| DAPLink | interface/cmsis-dap.cfg |
| J-Link | interface/jlink.cfg |

### GD32 系列配置映射

| 系列 | OpenOCD 配置 |
|------|--------------|
| GD32F1x | target/gd32f1x.cfg |
| GD32F3x | target/gd32f3x.cfg |
| GD32F4x | target/stm32f4x.cfg（兼容） |

### OpenOCD 路径配置

OpenOCD 安装路径：`D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe`

使用时需要指定完整路径：
```bash
"D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" -f .gd32-agent/openocd.cfg -c "program firmware.hex verify reset exit"
```

---

## 第五步：执行开发任务

### 标准流程

1. 读取硬件文档
2. 扫描工程目录
3. 识别芯片型号
4. 一致性检查
5. 生成 OpenOCD 配置
6. 用户确认任务需求
7. 使用 Plan Mode 制定计划
8. 用户确认计划
9. 执行代码修改
10. 编译工程
11. 烧录固件
12. 观察串口输出
13. 观察寄存器状态
14. 修复 bug
15. 生成任务结果文档

### 任务规划流程

#### 1. 生成任务需求文档

创建 `docs/tasks/task-requirements.md`：
- 用户原始需求
- 硬件依据
- 需要完成的事项
- 禁止事项
- 验收标准

#### 2. 使用 Plan Mode 制定计划

进入 Plan Mode，只允许：
- 读取文件
- 扫描源码
- 分析依赖
- 生成计划
- 不允许直接改代码

创建 `docs/tasks/task-plan.md`：
- 目标
- 修改计划（Step 1, 2, 3...）
- 风险
- 依赖

#### 3. 用户确认计划

展示计划给用户，获得确认后再执行。

#### 4. 执行代码修改

根据 task-plan.md 执行代码修改，更新 `docs/tasks/task-progress.md`。

#### 5. 生成任务结果

创建 `docs/tasks/task-result.md`：
- 任务概述
- 执行结果（编译、烧录、串口、寄存器）
- 验证结果
- 问题与解决
- 总结

### 编译工程

```bash
# CMake 工程
mkdir -p build && cd build && cmake .. && make 2>&1 | tee ../.gd32-agent/build.log

# Make 工程
make clean && make 2>&1 | tee .gd32-agent/build.log
```

### 烧录固件

```bash
# 烧录前确认
echo "芯片：$(grep '芯片型号' hardware/hardware.md | cut -d'：' -f2)"
echo "调试器：$(grep 'LINK 类型' hardware/hardware.md | cut -d'：' -f2)"
echo "固件：build/app.elf"

# 执行烧录
openocd -f .gd32-agent/openocd.cfg -c "program build/app.elf verify reset exit"
```

### 串口观察

```bash
# Windows
python -m serial.tools.miniterm COM3 115200 --raw > .gd32-agent/serial.log &
sleep 10
kill %1

# Linux
timeout 10 minicom -D /dev/ttyUSB0 -b 115200 -C .gd32-agent/serial.log
```

### 寄存器调试

```bash
# 启动 OpenOCD
openocd -f .gd32-agent/openocd.cfg &
OPENOCD_PID=$!

# 使用 GDB 读取寄存器
arm-none-eabi-gdb build/app.elf -batch \
  -ex "target remote :3333" \
  -ex "monitor halt" \
  -ex "info registers" \
  -ex "monitor reg" \
  > .gd32-agent/register-dump.md

# 停止 OpenOCD
kill $OPENOCD_PID
```

---

## 安全规则

### 禁止行为

- **禁止**未确认直接全片擦除
- **禁止**未确认修改 Option Bytes
- **禁止**未确认解除读保护
- **禁止**跳过硬件文档直接修改代码
- **禁止**编译失败后继续烧录
- **禁止**芯片型号不确定时执行烧录
- **禁止**调试器类型不确定时执行烧录

### 必须确认

烧录前必须确认：
1. 芯片型号
2. 调试器类型
3. 固件文件
4. OpenOCD 配置

---

## 输出文档

每次任务必须生成：

```bash
mkdir -p docs/{imported,analysis,tasks,reviews}
```

### 必须生成的文档

| 文档 | 路径 | 内容 |
|------|------|------|
| 硬件分析 | `docs/analysis/project-hardware-analysis.md` | MCU、引脚、时钟、外设 |
| 任务需求 | `docs/tasks/task-requirements.md` | 用户需求、硬件依据 |
| 任务计划 | `docs/tasks/task-plan.md` | 执行步骤、风险点 |
| 代码审查 | `docs/reviews/code-review.md` | 修改文件、一致性检查 |
| 任务结果 | `docs/tasks/task-result.md` | 执行结果、验证结果 |

---

## Skills 使用

### 开源 Skills

本项目使用以下开源 Skills：

| Skill | 来源 | 功能 |
|-------|------|------|
| document-skills | [anthropics/skills](https://github.com/anthropics/skills) | 文档处理（PDF、Word、Excel、PPT） |
| superpowers-skills | [obra/superpowers](https://github.com/obra/superpowers) | 任务编排和开发流程 |
| find-skills | [skills.sh](https://www.skills.sh/) | 技能发现和安装 |
| pua-skills | [tanweai/pua](https://github.com/tanweai/pua) | AI 代理压力驱动 |

### 自定义 Skills

| Skill | 功能 |
|-------|------|
| gd32-openocd | 编译、烧录、调试 |
| hardware-analysis | 硬件分析 |

### gd32-openocd Skill

用于编译、烧录、调试：

```bash
# 编译
bash .gd32-agent/build.sh

# 烧录
bash .gd32-agent/flash.sh build/app.hex

# 串口观察
bash .gd32-agent/serial.sh COM15 115200 10

# 寄存器调试
bash .gd32-agent/debug.sh build/app.elf
```

### document-skills Skill

用于文档读取和转换：

```bash
# 扫描工程
bash .gd32-agent/scan-project.sh

# 生成分析文档
# （自动生成 docs/analysis/project-scan-report.md）
```

### hardware-analysis Skill

用于硬件分析：

```bash
# 分析硬件
# （读取 hardware/hardware.md，扫描工程文件）

# 一致性检查
# （对比硬件文档和工程源码）
```

### superpowers-skills Skill

用于任务编排和流程控制：

```bash
# 任务分解
# （将复杂任务分解为子任务）

# 流程编排
# （按顺序执行开发流程）

# 状态管理
# （跟踪任务进度）
```

### find-skills Skill

用于技能发现和安装：

```bash
# 安装技能
npx skills add <owner/repo>

# 搜索技能
npx skills search <keyword>
```

### pua-skills Skill

用于 AI 代理压力驱动：

```bash
# 核心引擎
/pua

# 开启/关闭
/pua:on
/pua:off

# 鼓励模式
/pua:yes

# 循环模式
/pua:pua-loop
```

---

## 紧急情况处理

### 烧录失败

```bash
# 1. 检查 OpenOCD 连接
openocd -f .gd32-agent/openocd.cfg -c "init; halt; exit"

# 2. 检查芯片是否被锁
openocd -f .gd32-agent/openocd.cfg -c "init; halt; flash info 0; exit"

# 3. 尝试解除读保护（需要用户确认）
openocd -f .gd32-agent/openocd.cfg -c "init; halt; gd32 protect disable; exit"
```

### 串口无输出

```bash
# 1. 检查 GPIO 配置
# 2. 检查时钟配置
# 3. 检查波特率配置
# 4. 检查 printf 重定向
```

### 编译失败

```bash
# 1. 检查头文件路径
# 2. 检查源文件是否加入编译
# 3. 检查宏定义
# 4. 检查链接脚本
```

---

## 串口模拟触发

对于需要外部硬件触发的操作（如按键按下），使用串口模拟触发：

### 模拟按键按下

```bash
# 发送按键按下命令
echo "BUTTON_PRESS" > /dev/ttyUSB0

# 接收响应
timeout 5 cat /dev/ttyUSB0
```

### 模拟传感器数据

```bash
# 发送传感器数据
echo "SENSOR_VALUE:1234" > /dev/ttyUSB0

# 接收响应
timeout 5 cat /dev/ttyUSB0
```

### 确认流程

1. 使用串口模拟触发
2. 观察系统响应
3. 如果响应正确，再改为实际硬件触发
4. 记录测试结果到 `docs/testing/pua-test-report.md`

---

## 日志记录

使用带时间戳的日志脚本记录开发过程：

### 记录编译日志

```bash
bash .gd32-agent/log-with-timestamp.sh build SUCCESS "编译完成"
bash .gd32-agent/log-with-timestamp.sh build FAIL "编译失败"
```

### 记录烧录日志

```bash
bash .gd32-agent/log-with-timestamp.sh flash SUCCESS "烧录完成"
bash .gd32-agent/log-with-timestamp.sh flash FAIL "烧录失败"
```

### 记录调试日志

```bash
bash .gd32-agent/log-with-timestamp.sh debug SUCCESS "调试完成"
bash .gd32-agent/log-with-timestamp.sh debug FAIL "调试失败"
```

### 记录串口日志

```bash
bash .gd32-agent/log-with-timestamp.sh serial TX "发送数据"
bash .gd32-agent/log-with-timestamp.sh serial RX "接收数据"
```

### 日志文件位置

- 日志目录：`.gd32-agent/logs/`
- 日志文件：`.gd32-agent/logs/agent-YYYYMMDD.log`

---

## Bug 修复文档

修复 bug 时，必须提供强有力的证据支持：

### 证据收集

1. **寄存器转储** - 使用 GDB 读取关键寄存器
2. **串口日志** - 记录串口输出
3. **代码分析** - 分析相关代码

### Bug 修复流程

1. 发现 bug
2. 收集证据（寄存器、日志、代码）
3. 分析根本原因
4. 修复代码
5. 验证修复
6. 记录到 `docs/bugs/bug-fix-template.md`

### 证据示例

```markdown
## 证据 1：寄存器转储

**时间**：2024-XX-XX XX:XX:XX

| 寄存器 | 期望值 | 实际值 | 说明 |
|--------|--------|--------|------|
| USART_SR | 0x00000040 | 0x00000000 | 状态寄存器错误 |
| USART_DR | 0x000000xx | 0x000000xx | 数据寄存器正确 |

## 证据 2：串口日志

**时间**：2024-XX-XX XX:XX:XX

```
发送：Hello GD32
接收：（无响应）
```
```

---

## User-test 文档

完成工作时，必须书写详细的 user-test 文档：

### 测试内容

1. 基本功能测试
2. 通信功能测试
3. 按键功能测试
4. 定时器测试
5. ADC 测试
6. I2C 测试
7. SPI 测试
8. 中断测试
9. 低功耗测试
10. 稳定性测试

### 测试文档位置

- 模板：`docs/testing/user-test-template.md`
- 测试报告：`docs/testing/user-test-report.md`

### 测试流程

1. 生成测试文档
2. 用户手动测试
3. 记录测试结果
4. 发现问题则修复
5. 重新测试直到通过

---

## 总结

**核心理念**：硬件文档定事实，流程文档定规矩，AI 负责理解和规划，Bash 负责执行。

**执行顺序**：读取硬件文档 → 扫描工程 → 识别芯片 → 一致性检查 → 执行任务

**安全第一**：任何不确定的情况，必须停止并报告，等待用户确认。

**质量保证**：串口模拟验证 → 日志记录 → Bug 证据 → 用户测试
