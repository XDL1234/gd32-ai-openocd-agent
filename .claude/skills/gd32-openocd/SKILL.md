---
name: gd32-openocd
description: GD32 编译、烧录、调试。当需要编译工程、烧录固件、串口观察、寄存器调试时使用。
allowed-tools: Read, Bash, Write, Glob, Grep
---

# GD32 OpenOCD Skill

## 功能概述

本 Skill 提供 GD32 嵌入式开发的核心功能：
- 编译工程
- 烧录固件
- 串口观察
- 寄存器调试

## 前置条件

1. 已读取 `hardware/hardware.md`
2. 已识别芯片型号
3. 已生成 OpenOCD 配置

## 编译工程

### IDE 工程

对于 Keil/IAR 工程，需要用户手动编译，或使用命令行工具：

```bash
# Keil MDK
UV4 -b project.uvprojx -o build.log

# IAR
IarBuild.exe project.ewp -build Debug
```

### CMake 工程

```bash
mkdir -p build && cd build && cmake .. && make 2>&1 | tee ../.gd32-agent/build.log
```

### Make 工程

```bash
make clean && make 2>&1 | tee .gd32-agent/build.log
```

## 烧录固件

### 烧录前确认

```bash
echo "芯片：$(grep '芯片型号' hardware/hardware.md | cut -d'：' -f2)"
echo "调试器：$(grep 'LINK 类型' hardware/hardware.md | cut -d'：' -f2)"
echo "固件：build/app.elf"
```

### 执行烧录

```bash
openocd -f .gd32-agent/openocd.cfg -c "program build/app.elf verify reset exit"
```

### 烧录失败处理

如果烧录失败，尝试以下步骤：

1. 检查 OpenOCD 连接：
```bash
openocd -f .gd32-agent/openocd.cfg -c "init; halt; exit"
```

2. 检查芯片是否被锁：
```bash
openocd -f .gd32-agent/openocd.cfg -c "init; halt; flash info 0; exit"
```

3. 尝试解除读保护（需要用户确认）：
```bash
openocd -f .gd32-agent/openocd.cfg -c "init; halt; gd32 protect disable; exit"
```

## 串口观察

### Windows

```bash
python -m serial.tools.miniterm COM3 115200 --raw > .gd32-agent/serial.log &
sleep 10
kill %1
```

### Linux

```bash
timeout 10 minicom -D /dev/ttyUSB0 -b 115200 -C .gd32-agent/serial.log
```

## 寄存器调试

### 启动 OpenOCD

```bash
openocd -f .gd32-agent/openocd.cfg &
OPENOCD_PID=$!
```

### 使用 GDB 读取寄存器

```bash
arm-none-eabi-gdb build/app.elf -batch \
  -ex "target remote :3333" \
  -ex "monitor halt" \
  -ex "info registers" \
  -ex "monitor reg" \
  > .gd32-agent/register-dump.md
```

### 停止 OpenOCD

```bash
kill $OPENOCD_PID
```

## 安全规则

- 烧录前必须确认芯片型号和调试器
- 禁止自动擦除或解锁
- 编译失败禁止烧录
- 芯片型号不确定时禁止烧录
- 调试器类型不确定时禁止烧录

## 输出文件

- `.gd32-agent/build.log` - 编译日志
- `.gd32-agent/serial.log` - 串口日志
- `.gd32-agent/register-dump.md` - 寄存器转储
