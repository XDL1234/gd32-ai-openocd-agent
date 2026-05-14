#!/bin/bash
# GD32 串口观察脚本
# 支持 Windows (Git Bash/MSYS2) 和 Linux/macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

# 平台默认串口
default_serial_port() {
    case "$(uname -s)" in
        Linux*)   echo "/dev/ttyUSB0" ;;
        Darwin*)  echo "/dev/tty.usbserial" ;;
        *)        echo "COM3" ;;
    esac
}

PORT="${1:-${SERIAL_PORT:-$(default_serial_port)}}"
BAUDRATE="${2:-${SERIAL_BAUDRATE:-115200}}"
DURATION="${3:-10}"

echo "=========================================="
echo "GD32 串口观察"
echo "=========================================="
echo "串口: $PORT"
echo "波特率: $BAUDRATE"
echo "观察时间: ${DURATION}秒"
echo "=========================================="

# 优先使用 python3，fallback 到 python
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "错误: Python 未安装（需要 python3 或 python）"
    exit 1
fi

if ! $PYTHON_CMD -c "import serial" &> /dev/null; then
    echo "错误: pyserial 未安装，请执行: $PYTHON_CMD -m pip install pyserial"
    exit 1
fi

mkdir -p .gd32-agent

# 跨平台 timeout：Linux 用 timeout，macOS 用 gtimeout 或 Python fallback
run_with_timeout() {
    local dur="$1"
    shift
    if command -v timeout &> /dev/null; then
        timeout "$dur" "$@"
    elif command -v gtimeout &> /dev/null; then
        gtimeout "$dur" "$@"
    else
        $PYTHON_CMD -c "
import subprocess, sys
try:
    subprocess.run(sys.argv[1:], timeout=$dur)
except subprocess.TimeoutExpired:
    pass
" "$@"
    fi
}

echo "开始监听串口..."
run_with_timeout $DURATION $PYTHON_CMD -m serial.tools.miniterm $PORT $BAUDRATE --raw 2>&1 | tee .gd32-agent/serial.log

echo ""
echo "=========================================="
echo "串口观察完成"
echo "日志保存在: .gd32-agent/serial.log"
echo "=========================================="
