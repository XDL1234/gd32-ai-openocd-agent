#!/bin/bash
# GD32 串口观察脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

PORT="${1:-${SERIAL_PORT:-COM3}}"
BAUDRATE="${2:-${SERIAL_BAUDRATE:-115200}}"
DURATION="${3:-10}"

echo "=========================================="
echo "GD32 串口观察"
echo "=========================================="
echo "串口: $PORT"
echo "波特率: $BAUDRATE"
echo "观察时间: ${DURATION}秒"
echo "=========================================="

if ! command -v python &> /dev/null; then
    echo "错误: Python 未安装"
    exit 1
fi

if ! python -c "import serial" &> /dev/null; then
    echo "错误: pyserial 未安装，请执行: pip install pyserial"
    exit 1
fi

mkdir -p .gd32-agent

echo "开始监听串口..."
timeout $DURATION python -m serial.tools.miniterm $PORT $BAUDRATE --raw 2>&1 | tee .gd32-agent/serial.log

echo ""
echo "=========================================="
echo "串口观察完成"
echo "日志保存在: .gd32-agent/serial.log"
echo "=========================================="
