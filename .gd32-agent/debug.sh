#!/bin/bash
# GD32 寄存器调试脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

# OpenOCD 路径：config.env → which → 硬编码 fallback
resolve_openocd() {
    if [ -n "$OPENOCD_PATH" ] && [ -f "$OPENOCD_PATH" ]; then
        echo "$OPENOCD_PATH"
    elif command -v openocd &> /dev/null; then
        which openocd
    elif [ -f "D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe" ]; then
        echo "D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe"
    else
        echo ""
    fi
}

OPENOCD=$(resolve_openocd)
GDB="${GDB_PATH:-arm-none-eabi-gdb}"
CONFIG="${OPENOCD_CFG:-.gd32-agent/openocd.cfg}"
FIRMWARE="$1"

if [ -z "$OPENOCD" ]; then
    echo "错误: 未找到 OpenOCD，请在 .gd32-agent/config.env 中设置 OPENOCD_PATH"
    exit 1
fi

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

mkdir -p .gd32-agent

echo "启动 OpenOCD..."
"$OPENOCD" -f "$CONFIG" &
OPENOCD_PID=$!

sleep 2

echo "读取寄存器..."
"$GDB" "$FIRMWARE" -batch \
    -ex "target remote :3333" \
    -ex "monitor halt" \
    -ex "info registers" \
    -ex "monitor reg" \
    > .gd32-agent/register-dump.md 2>&1

echo "停止 OpenOCD..."
kill $OPENOCD_PID 2>/dev/null

echo ""
echo "=========================================="
echo "寄存器调试完成"
echo "寄存器转储保存在: .gd32-agent/register-dump.md"
echo "=========================================="
