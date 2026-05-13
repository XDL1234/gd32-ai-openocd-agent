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

### gd32-openocd Skill

用于编译、烧录、调试：

```bash
# 编译
gd32-agent build

# 烧录
gd32-agent flash

# 串口观察
gd32-agent serial

# 寄存器调试
gd32-agent debug
```

### document-skills Skill

用于文档读取和转换：

```bash
# 读取文档
gd32-agent ingest-docs

# 生成索引
gd32-agent analyze
```

### hardware-analysis Skill

用于硬件分析：

```bash
# 分析硬件
gd32-agent analyze

# 一致性检查
gd32-agent check
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

## 总结

**核心理念**：硬件文档定事实，流程文档定规矩，AI 负责理解和规划，Bash 负责执行。

**执行顺序**：读取硬件文档 → 扫描工程 → 识别芯片 → 一致性检查 → 执行任务

**安全第一**：任何不确定的情况，必须停止并报告，等待用户确认。
