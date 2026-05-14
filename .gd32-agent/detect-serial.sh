#!/bin/bash
# GD32 AI Agent 串口自动检测脚本
# 支持 Windows (Git Bash) 和 Linux/macOS

echo "检测可用串口..."

if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows: 通过 mode 命令检测
    PORTS=$(powershell.exe -NoProfile -Command "[System.IO.Ports.SerialPort]::GetPortNames()" 2>/dev/null | tr -d '\r')
    if [ -z "$PORTS" ]; then
        # fallback: 检查注册表
        PORTS=$(powershell.exe -NoProfile -Command "Get-WmiObject Win32_SerialPort | Select-Object -ExpandProperty DeviceID" 2>/dev/null | tr -d '\r')
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    PORTS=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    PORTS=$(ls /dev/tty.usbserial* /dev/tty.usbmodem* 2>/dev/null)
fi

if [ -n "$PORTS" ]; then
    echo "✅ 检测到以下串口："
    echo "$PORTS" | while read -r port; do
        [ -n "$port" ] && echo "   - $port"
    done
    # 输出第一个串口作为推荐
    FIRST_PORT=$(echo "$PORTS" | head -1 | tr -d '\r\n')
    echo ""
    echo "DETECTED_PORT=$FIRST_PORT"
else
    echo "❌ 未检测到串口设备"
    echo "DETECTED_PORT="
fi
