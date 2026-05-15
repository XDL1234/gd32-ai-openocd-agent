#!/usr/bin/env bash
# GD32 寄存器调试脚本
# 三种模式：
#   1. 通用寄存器转储（默认）
#   2. 指定外设寄存器读取（--periph <地址> [数量]）
#   3. 批量外设寄存器读取（--batch <地址文件>）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

CONFIG="${OPENOCD_CFG:-$AGENT_DIR/openocd.cfg}"

MODE="general"
FIRMWARE=""
PERIPH_ADDR=""
PERIPH_COUNT=16
BATCH_FILE=""
OUTPUT_FILE="$AGENT_DIR/register-dump.md"

while [[ $# -gt 0 ]]; do
    case $1 in
        --periph)
            MODE="periph"
            PERIPH_ADDR="$2"
            shift 2
            if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
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
            cat <<'EOF'
用法: debug.sh [选项] <固件.elf>

模式:
  (默认)                    通用寄存器 + CPU 状态转储
  --periph <地址> [数量]    读取外设寄存器（默认读 16 个 32 位字）
  --batch <地址文件>        批量读取多个外设基地址（文件每行一个: 地址 名称）
  --output/-o <文件>        输出文件路径（默认 .gd32-agent/register-dump.md）

示例:
  debug.sh build/app.elf                              # 通用寄存器
  debug.sh --periph 0x40011000 16 build/app.elf       # 读 USART0 16个寄存器
  debug.sh --batch .gd32-agent/periph-addrs.txt build/app.elf

地址文件格式（每行）:
  0x40011000 USART0
  0x40020C00 GPIOA
EOF
            exit 0
            ;;
        *)
            FIRMWARE="$1"
            shift
            ;;
    esac
done

[ -n "$FIRMWARE" ] || die "请指定固件 .elf 文件，用法: $0 [选项] <固件.elf>"
[ -f "$FIRMWARE" ] || die "固件文件不存在: $FIRMWARE"

OPENOCD=$(resolve_openocd) || die "未找到 OpenOCD，请在 $AGENT_DIR/config.env 中设置 OPENOCD_PATH"

mkdir -p "$(dirname "$OUTPUT_FILE")"

TIMESTAMP=$(ts_human)

banner "GD32 寄存器调试"
log_info "模式: $MODE"
log_info "OpenOCD: $OPENOCD"
log_info "配置: $CONFIG"
log_info "固件: $FIRMWARE"
log_info "输出: $OUTPUT_FILE"
log_info "时间: $TIMESTAMP"

# 构造 OpenOCD 命令序列
build_ocd_commands() {
    local cmds="init; halt; "

    case $MODE in
        general)
            cmds+="reg; "
            ;;
        periph)
            cmds+="echo \">>> PERIPH_READ $PERIPH_ADDR count=$PERIPH_COUNT\"; "
            local i offset addr
            for ((i=0; i<PERIPH_COUNT; i++)); do
                offset=$((i * 4))
                addr=$(printf "0x%08X" $(( PERIPH_ADDR + offset )))
                cmds+="mdw $addr 1; "
            done
            ;;
        batch)
            [ -f "$BATCH_FILE" ] || die "地址文件不存在: $BATCH_FILE"
            local addr name i offset a
            while IFS=' ' read -r addr name; do
                [ -z "$addr" ] && continue
                [[ "$addr" == \#* ]] && continue
                cmds+="echo \">>> PERIPH_GROUP $name ($addr)\"; "
                for ((i=0; i<PERIPH_COUNT; i++)); do
                    offset=$((i * 4))
                    a=$(printf "0x%08X" $(( addr + offset )))
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

log_step "执行 OpenOCD 寄存器读取"
set +e
"$OPENOCD" -f "$CONFIG" -c "$OCD_CMDS" >> "$OUTPUT_FILE" 2>&1
OCD_EXIT=$?
set -e

{
    echo '```'
    echo ""
    echo "- OpenOCD 退出码: $OCD_EXIT"
} >> "$OUTPUT_FILE"

if [ $OCD_EXIT -eq 0 ]; then
    banner "寄存器读取完成"
    log_info "结果保存在: $OUTPUT_FILE"
else
    banner "寄存器读取失败（退出码: $OCD_EXIT）"
    log_warn "请检查调试器连接和 OpenOCD 配置"
fi

exit $OCD_EXIT
