#!/bin/bash
# GD32 烧录脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

# OpenOCD 路径：config.env → which → 常见安装路径 fallback
resolve_openocd() {
    if [ -n "$OPENOCD_PATH" ] && [ -f "$OPENOCD_PATH" ]; then
        echo "$OPENOCD_PATH"
    elif command -v openocd &> /dev/null; then
        which openocd
    else
        for candidate in \
            "/usr/bin/openocd" \
            "/usr/local/bin/openocd" \
            "/opt/openocd/bin/openocd" \
            "D:/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe" \
            "C:/Program Files/openocd/bin/openocd.exe" \
            "C:/Program Files (x86)/openocd/bin/openocd.exe" \
            "C:/openocd/bin/openocd.exe"; do
            if [ -f "$candidate" ]; then
                echo "$candidate"
                return
            fi
        done
        echo ""
    fi
}

OPENOCD=$(resolve_openocd)
CONFIG="${OPENOCD_CFG:-.gd32-agent/openocd.cfg}"
FIRMWARE="$1"

if [ -z "$OPENOCD" ]; then
    echo "错误: 未找到 OpenOCD，请在 .gd32-agent/config.env 中设置 OPENOCD_PATH"
    exit 1
fi

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
