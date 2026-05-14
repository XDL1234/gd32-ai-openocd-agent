#!/bin/bash
# GD32 寄存器调试脚本
# 支持三种模式：
#   1. 通用寄存器转储（默认）
#   2. 指定外设寄存器读取（--periph <地址> [数量]）
#   3. 批量外设寄存器读取（--batch <地址文件>）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

resolve_openocd() {
    if [ -n "$OPENOCD_PATH" ] && [ -f "$OPENOCD_PATH" ]; then
        echo "$OPENOCD_PATH"
    elif command -v openocd &> /dev/null; then
        which openocd
    else
        for candidate in \
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
GDB="${GDB_PATH:-arm-none-eabi-gdb}"
CONFIG="${OPENOCD_CFG:-.gd32-agent/openocd.cfg}"

if [ -z "$OPENOCD" ]; then
    echo "错误: 未找到 OpenOCD，请在 .gd32-agent/config.env 中设置 OPENOCD_PATH"
    exit 1
fi

MODE="general"
FIRMWARE=""
PERIPH_ADDR=""
PERIPH_COUNT=16
BATCH_FILE=""
OUTPUT_FILE=".gd32-agent/register-dump.md"

while [[ $# -gt 0 ]]; do
    case $1 in
        --periph)
            MODE="periph"
            PERIPH_ADDR="$2"
            shift 2
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                PERIPH_COUNT="$1"
                shift
            fi
            ;;
        --batch)
            MODE="batch"
            BATCH_FILE="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项] <固件.elf>"
            echo ""
            echo "模式:"
            echo "  (默认)                    通用寄存器 + CPU 状态转储"
            echo "  --periph <地址> [数量]    读取外设寄存器（默认读 16 个 32 位字）"
            echo "  --batch <地址文件>        批量读取多个外设基地址（文件每行一个: 地址 名称）"
            echo "  --output/-o <文件>        输出文件路径（默认 .gd32-agent/register-dump.md）"
            echo ""
            echo "示例:"
            echo "  $0 build/app.elf                              # 通用寄存器"
            echo "  $0 --periph 0x40011000 16 build/app.elf       # 读 USART0 16个寄存器"
            echo "  $0 --batch .gd32-agent/periph-addrs.txt build/app.elf  # 批量读"
            echo ""
            echo "地址文件格式（每行）:"
            echo "  0x40011000 USART0"
            echo "  0x40020C00 GPIOA"
            exit 0
            ;;
        *)
            FIRMWARE="$1"
            shift
            ;;
    esac
done

if [ -z "$FIRMWARE" ]; then
    echo "错误: 请指定固件 .elf 文件"
    echo "用法: $0 [选项] <固件.elf>"
    exit 1
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "错误: 固件文件不存在: $FIRMWARE"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "=========================================="
echo "GD32 寄存器调试"
echo "=========================================="
echo "模式: $MODE"
echo "OpenOCD: $OPENOCD"
echo "配置: $CONFIG"
echo "固件: $FIRMWARE"
echo "输出: $OUTPUT_FILE"
echo "时间: $TIMESTAMP"
echo "=========================================="

# 构造 OpenOCD 命令序列
build_ocd_commands() {
    local cmds="init; halt; "

    case $MODE in
        general)
            cmds+="reg; "
            ;;
        periph)
            cmds+="echo \">>> PERIPH_READ $PERIPH_ADDR count=$PERIPH_COUNT\"; "
            for ((i=0; i<PERIPH_COUNT; i++)); do
                local offset=$((i * 4))
                local addr=$(printf "0x%08X" $(( $PERIPH_ADDR + $offset )))
                cmds+="mdw $addr 1; "
            done
            ;;
        batch)
            if [ ! -f "$BATCH_FILE" ]; then
                echo "错误: 地址文件不存在: $BATCH_FILE"
                exit 1
            fi
            while IFS=' ' read -r addr name; do
                [ -z "$addr" ] && continue
                [[ "$addr" == \#* ]] && continue
                local count=${PERIPH_COUNT}
                cmds+="echo \">>> PERIPH_GROUP $name ($addr)\"; "
                for ((i=0; i<count; i++)); do
                    local offset=$((i * 4))
                    local a=$(printf "0x%08X" $(( $addr + $offset )))
                    cmds+="mdw $a 1; "
                done
            done < "$BATCH_FILE"
            ;;
    esac

    cmds+="exit"
    echo "$cmds"
}

OCD_CMDS=$(build_ocd_commands)

{
    echo "# 寄存器转储"
    echo ""
    echo "- 时间: $TIMESTAMP"
    echo "- 固件: $FIRMWARE"
    echo "- 模式: $MODE"
    echo ""
    echo '```'
} > "$OUTPUT_FILE"

echo "执行 OpenOCD 寄存器读取..."
"$OPENOCD" -f "$CONFIG" -c "$OCD_CMDS" >> "$OUTPUT_FILE" 2>&1
OCD_EXIT=$?

{
    echo '```'
    echo ""
    echo "- OpenOCD 退出码: $OCD_EXIT"
} >> "$OUTPUT_FILE"

if [ $OCD_EXIT -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "寄存器读取完成"
    echo "结果保存在: $OUTPUT_FILE"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "寄存器读取失败（退出码: $OCD_EXIT）"
    echo "请检查调试器连接和 OpenOCD 配置"
    echo "=========================================="
fi

exit $OCD_EXIT
