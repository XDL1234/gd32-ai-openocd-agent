# GD32 AI Agent 用户使用指南

## 概述

GD32 AI Agent 是一个基于 Claude Code 的自动化开发工具，可以帮助你快速开发 GD32 嵌入式工程。它支持：

- 自动识别芯片型号
- 自动生成 OpenOCD 配置
- 自动编译、烧录、调试
- 自动观察串口输出
- 自动读取寄存器状态

---

## 快速开始

### 第一步：Clone Agent 到你的工程

```bash
# 进入你的 GD32 工程目录
cd your-gd32-project

# Clone Agent
git clone https://github.com/your-repo/gd32-ai-openocd-agent.git .gd32-agent

# 或者复制 Agent 文件到你的工程
cp -r /path/to/gd32-ai-openocd-agent/* .
```

### 第二步：检查目录结构

确保你的工程目录结构如下：

```
your-gd32-project/
├── src/                    # 你的源代码
├── inc/                    # 你的头文件
├── Drivers/                # 驱动库
├── CMakeLists.txt          # CMake 工程（可选）
├── Makefile                # Make 工程（可选）
├── MDK-ARM/                # Keil 工程（可选）
├── hardware/               # 硬件文档（Agent 提供）
│   └── 硬件资源表.md
├── workflow/               # 开发流程（Agent 提供）
│   └── development-flow.md
├── docs/                   # 文档目录（Agent 提供）
│   ├── analysis/
│   ├── tasks/
│   └── reviews/
├── .gd32-agent/            # Agent 配置（Agent 提供）
│   ├── openocd.cfg
│   ├── flash.sh
│   ├── serial.sh
│   └── debug.sh
└── CLAUDE.md               # Claude 规则（Agent 提供）
```

### 第三步：配置硬件文档

编辑 `hardware/硬件资源表.md`，填写你的硬件信息：

```markdown
# 硬件文档

## MCU 信息

- 芯片型号：GD32F470VET6      # 修改为你的芯片型号
- 芯片系列：GD32F4xx          # 修改为你的芯片系列
- 内核：Cortex-M4             # 修改为你的内核
- 主频：168MHz                # 修改为你的主频
- Flash：512KB                # 修改为你的 Flash 大小
- SRAM：256KB                 # 修改为你的 SRAM 大小

## 下载调试接口

- LINK 类型：DAPLink          # 修改为你的调试器（ST-LINK/DAPLink/J-Link）
- 接口协议：SWD               # 修改为你的接口协议
- 默认下载速度：1000 kHz

## 串口输出

- 串口号：USART0              # 修改为你的串口
- TX：PA9                     # 修改为你的 TX 引脚
- RX：PA10                    # 修改为你的 RX 引脚
- 波特率：115200              # 修改为你的波特率

## 风险限制

- 是否允许全片擦除：否        # 根据需要修改
- 是否允许修改 Option Bytes：否
- 是否允许解除读保护：否
```

### 第四步：配置 OpenOCD

编辑 `.gd32-agent/openocd.cfg`，根据你的调试器修改：

```bash
# DAPLink 调试器
source [find interface/cmsis-dap.cfg]
source [find target/stm32f4x.cfg]  # GD32F4xx 兼容 STM32F4xx
adapter speed 1000
transport select swd

# ST-LINK 调试器（取消注释）
# source [find interface/stlink.cfg]
# source [find target/stm32f4x.cfg]
# adapter speed 1000
# transport select swd

# J-Link 调试器（取消注释）
# source [find interface/jlink.cfg]
# source [find target/stm32f4x.cfg]
# adapter speed 1000
# transport select swd
```

### 第五步：验证连接

```bash
# 测试 OpenOCD 连接
"D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" -f .gd32-agent/openocd.cfg -c "init; halt; exit"

# 如果连接成功，会显示：
# Info : [stm32f4x.cpu] Cortex-M4 r0p1 processor detected
# Info : [stm32f4x.cpu] target has 6 breakpoints, 4 watchpoints
# Info : [stm32f4x.cpu] Examination succeed
```

---

## 使用方法

### 1. 启动 Claude Code

```bash
# 进入你的工程目录
cd your-gd32-project

# 启动 Claude Code
claude
```

### 2. 初始化 Agent

在 Claude Code 中输入：

```
初始化这个 GD32 工程
```

Claude 会自动：
1. 读取 `hardware/硬件资源表.md`
2. 扫描工程文件
3. 识别芯片型号
4. 生成分析文档

### 3. 执行开发任务

在 Claude Code 中描述你的需求：

```
帮我实现 USART0 打印启动日志，并烧录验证
```

Claude 会自动：
1. 读取硬件文档
2. 扫描工程源码
3. 生成任务需求文档
4. 使用 Plan Mode 制定计划
5. 用户确认后执行代码修改
6. 编译工程
7. 烧录固件
8. 观察串口输出
9. 如果失败，自动调试

### 4. 烧录固件

```bash
# 使用烧录脚本
bash .gd32-agent/flash.sh build/app.hex

# 或者直接使用 OpenOCD
"D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" -f .gd32-agent/openocd.cfg -c "program build/app.hex verify reset exit"
```

### 5. 观察串口输出

```bash
# 使用串口脚本
bash .gd32-agent/serial.sh COM15 115200 10

# 或者直接使用 Python
python -m serial.tools.miniterm COM15 115200 --raw
```

### 6. 寄存器调试

```bash
# 使用调试脚本
bash .gd32-agent/debug.sh build/app.elf

# 或者手动调试
# 启动 OpenOCD
"D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" -f .gd32-agent/openocd.cfg &

# 使用 GDB 连接
arm-none-eabi-gdb build/app.elf -ex "target remote :3333"
```

---

## 常见问题

### Q1: OpenOCD 连接失败

**错误信息**：
```
Error: unable to find a matching CMSIS-DAP device
```

**解决方案**：
1. 检查 DAPLink 是否连接到电脑
2. 检查 DAPLink 驱动是否安装
3. 检查 USB 线是否正常

### Q2: 烧录失败

**错误信息**：
```
Error: couldn't open firmware.hex
```

**解决方案**：
1. 检查固件文件路径是否正确
2. 使用正斜杠 `/` 而不是反斜杠 `\`
3. 检查固件文件是否存在

### Q3: 串口无输出

**可能原因**：
1. 串口配置不正确
2. 波特率不匹配
3. GPIO 配置错误
4. 时钟配置错误

**解决方案**：
1. 检查 `hardware/硬件资源表.md` 中的串口配置
2. 检查代码中的串口初始化
3. 使用示波器检查 TX 引脚

### Q4: 编译失败

**可能原因**：
1. 头文件路径错误
2. 源文件未加入编译
3. 宏定义错误
4. 链接脚本错误

**解决方案**：
1. 检查 CMakeLists.txt 或 Makefile
2. 检查头文件路径
3. 检查宏定义

---

## 高级用法

### 1. 自定义 OpenOCD 配置

如果你的芯片不在支持列表中，可以自定义 OpenOCD 配置：

```bash
# 创建自定义配置
cat > .gd32-agent/openocd.cfg << 'EOF'
source [find interface/cmsis-dap.cfg]

# 自定义目标配置
set CHIPNAME gd32f470vet6
set CPUTAPID 0x4ba00477

jtag newtap $CHIPNAME cpu -irlen 4 -ircapture 0x1 -irmask 0xf -expected-id $CPUTAPID

target create $CHIPNAME.cpu cortex-m -chain-position $CHIPNAME.cpu
$CHIPNAME.cpu configure -work-area-phys 0x20000000 -work-area-size 0x40000

adapter speed 1000
transport select swd
EOF
```

### 2. 使用 GDB 调试

```bash
# 启动 OpenOCD
"D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" -f .gd32-agent/openocd.cfg &

# 启动 GDB
arm-none-eabi-gdb build/app.elf

# 在 GDB 中连接
(gdb) target remote :3333
(gdb) monitor halt
(gdb) break main
(gdb) continue
(gdb) info registers
(gdb) monitor reg
```

### 3. 批量烧录

```bash
# 创建批量烧录脚本
cat > batch_flash.sh << 'EOF'
#!/binbin/bash
for i in {1..10}; do
    echo "烧录第 $i 个设备..."
    bash .gd32-agent/flash.sh build/app.hex
    if [ $? -ne 0 ]; then
        echo "烧录失败！"
        exit 1
    fi
    echo "等待更换设备..."
    read -p "按 Enter 继续..."
done
echo "批量烧录完成！"
EOF

chmod +x batch_flash.sh
```

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `hardware/硬件资源表.md` | 硬件文档，包含芯片、调试器、串口配置 |
| `workflow/development-flow.md` | 开发流程文档，定义标准流程和禁止行为 |
| `CLAUDE.md` | Claude Code 规则文件，定义 Agent 行为 |
| `.gd32-agent/openocd.cfg` | OpenOCD 配置文件 |
| `.gd32-agent/flash.sh` | 烧录脚本 |
| `.gd32-agent/serial.sh` | 串口观察脚本 |
| `.gd32-agent/debug.sh` | 寄存器调试脚本 |
| `docs/analysis/project-hardware-analysis.md` | 工程分析文档 |
| `docs/tasks/task-requirements.md` | 任务需求文档 |
| `docs/tasks/task-plan.md` | 任务计划文档 |
| `docs/tasks/task-result.md` | 任务结果文档 |

---

## 技术支持

如有问题，请提交 Issue 到 GitHub 仓库。

---

## 许可证

MIT License
