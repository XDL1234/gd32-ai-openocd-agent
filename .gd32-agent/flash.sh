#!/bin/bash
# GD32 烧录脚本

# OpenOCD 路径
OPENOCD="D:\openocd\xpack-openocd-0.12.0-6\bin\openocd.exe"

# 配置文件
CONFIG=".gd32-agent/openocd.cfg"

# 固件文件
FIRMWARE="$1"

if [ -z "$FIRMWARE" ]; then
    echo "用法: $0 <固件文件>"
    echo "示例: $0 build/app.hex"
    exit 1
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "错误: 固件文件不存在: $FIRMWARE"
    exit 1
fi

echo "=========================================="
echo "GD32 烧录"
echo "=========================================="
echo "OpenOCD: $OPENOCD"
echo "配置: $CONFIG"
echo "固件: $FIRMWARE"
echo "=========================================="

# 执行烧录
"$OPENOCD" -f "$CONFIG" -c "program $FIRMWARE verify reset exit"

if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "烧录成功！"
    echo "=========================================="
else
    echo "=========================================="
    echo "烧录失败！"
    echo "=========================================="
    exit 1
fi
