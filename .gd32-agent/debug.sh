#!/bin/bash
# GD32 寄存器调试脚本

# OpenOCD 路径
OPENOCD="D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe"

# 配置文件
CONFIG=".gd32-agent/openocd.cfg"

# GDB 路径
GDB="arm-none-eabi-gdb"

# 固件文件
FIRMWARE="$1"

if [ -z "$FIRMWARE" ]; then
    echo "用法: $0 <固件文件>"
    echo "示例: $0 build/app.elf"
    exit 1
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "错误: 固件文件不存在: $FIRMWARE"
    exit 1
fi

echo "=========================================="
echo "GD32 寄存器调试"
echo "=========================================="
echo "OpenOCD: $OPENOCD"
echo "配置: $CONFIG"
echo "固件: $FIRMWARE"
echo "GDB: $GDB"
echo "=========================================="

# 创建日志目录
mkdir -p .gd32-agent

# 启动 OpenOCD（后台）
echo "启动 OpenOCD..."
"$OPENOCD" -f "$CONFIG" &
OPENOCD_PID=$!

# 等待 OpenOCD 启动
sleep 2

# 使用 GDB 读取寄存器
echo "读取寄存器..."
"$GDB" "$FIRMWARE" -batch \
    -ex "target remote :3333" \
    -ex "monitor halt" \
    -ex "info registers" \
    -ex "monitor reg" \
    > .gd32-agent/register-dump.md 2>&1

# 停止 OpenOCD
echo "停止 OpenOCD..."
kill $OPENOCD_PID 2>/dev/null

echo ""
echo "=========================================="
echo "寄存器调试完成"
echo "寄存器转储保存在: .gd32-agent/register-dump.md"
echo "=========================================="
