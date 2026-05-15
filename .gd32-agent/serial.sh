#!/usr/bin/env bash
# GD32 串口观察脚本
# 支持 Windows (Git Bash/MSYS2) 和 Linux/macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

# 平台默认串口
default_serial_port() {
    case "$(detect_os)" in
        Linux)   echo "/dev/ttyUSB0" ;;
        macOS)   echo "/dev/tty.usbserial" ;;
        *)       echo "COM3" ;;
    esac
}

PORT="${1:-${SERIAL_PORT:-$(default_serial_port)}}"
BAUDRATE="${2:-${SERIAL_BAUDRATE:-115200}}"
DURATION="${3:-10}"

banner "GD32 串口观察"
log_info "串口: $PORT"
log_info "波特率: $BAUDRATE"
log_info "观察时间: ${DURATION}秒"

PYTHON_CMD=$(resolve_python) || die "Python 未安装（需要 python3 或 python）"

if ! "$PYTHON_CMD" -c "import serial" >/dev/null 2>&1; then
    die "pyserial 未安装，请执行: $PYTHON_CMD -m pip install pyserial"
fi

mkdir -p "$AGENT_DIR"

log_step "开始监听串口"
run_with_timeout "$DURATION" "$PYTHON_CMD" -m serial.tools.miniterm "$PORT" "$BAUDRATE" --raw 2>&1 | tee "$AGENT_DIR/serial.log"

banner "串口观察完成"
log_info "日志保存在: $AGENT_DIR/serial.log"
