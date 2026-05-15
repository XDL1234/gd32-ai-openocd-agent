#!/usr/bin/env bash
# GD32 AI Agent 串口自动检测脚本
# 支持 Windows (Git Bash) 和 Linux/macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

echo "检测可用串口..."

PORTS=""
case "$(detect_os)" in
    Windows)
        PORTS=$(powershell.exe -NoProfile -Command "[System.IO.Ports.SerialPort]::GetPortNames()" 2>/dev/null | tr -d '\r' || true)
        if [ -z "$PORTS" ]; then
            PORTS=$(powershell.exe -NoProfile -Command "Get-WmiObject Win32_SerialPort | Select-Object -ExpandProperty DeviceID" 2>/dev/null | tr -d '\r' || true)
        fi
        ;;
    Linux)
        PORTS=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true)
        ;;
    macOS)
        PORTS=$(ls /dev/tty.usbserial* /dev/tty.usbmodem* 2>/dev/null || true)
        ;;
esac

if [ -n "$PORTS" ]; then
    log_ok "检测到以下串口："
    echo "$PORTS" | while read -r port; do
        [ -n "$port" ] && echo "   - $port"
    done
    FIRST_PORT=$(echo "$PORTS" | head -1 | tr -d '\r\n')
    echo ""
    echo "DETECTED_PORT=$FIRST_PORT"
else
    log_error "未检测到串口设备"
    echo "DETECTED_PORT="
fi
