#!/bin/bash
# GD32 串口观察脚本

# 串口配置
PORT="${1:-COM3}"
BAUDRATE="${2:-115200}"
DURATION="${3:-10}"

echo "=========================================="
echo "GD32 串口观察"
echo "=========================================="
echo "串口: $PORT"
echo "波特率: $BAUDRATE"
echo "观察时间: ${DURATION}秒"
echo "=========================================="

# 检查 Python 是否可用
if ! command -v python &> /dev/null; then
    echo "错误: Python 未安装"
    exit 1
fi

# 检查 pyserial 是否安装
if ! python -c "import serial" &> /dev/null; then
    echo "错误: pyserial 未安装，请执行: pip install pyserial"
    exit 1
fi

# 创建日志目录
mkdir -p .gd32-agent

# 启动串口监听
echo "开始监听串口..."
timeout $DURATION python -m serial.tools.miniterm $PORT $BAUDRATE --raw 2>&1 | tee .gd32-agent/serial.log

echo ""
echo "=========================================="
echo "串口观察完成"
echo "日志保存在: .gd32-agent/serial.log"
echo "=========================================="
