#!/usr/bin/env bash
# GD32 自动调试循环脚本
# 编译 → 烧录 → 寄存器读取 → 串口观察，一键执行全流程
# 用于 Bug 自动定位：Agent 调用此脚本收集硬件证据
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

cd "$PROJECT_DIR"

TIMESTAMP=$(ts_compact)
EVIDENCE_DIR="$AGENT_DIR/logs/debug-$TIMESTAMP"
mkdir -p "$EVIDENCE_DIR"

SERIAL_TIMEOUT="${1:-5}"
PERIPH_ADDRS_FILE="${2:-$AGENT_DIR/periph-addrs.txt}"

banner "GD32 自动调试循环"
log_info "时间: $TIMESTAMP"
log_info "证据目录: $EVIDENCE_DIR"
log_info "串口超时: ${SERIAL_TIMEOUT}s"

# 写入汇总信息（无论后续是否失败都尽量记录）
write_summary() {
    local build_result="${1:-FAIL}"
    local build_exit="${2:-1}"
    local flash_result="${3:-SKIP}"
    local flash_exit="${4:-0}"
    local reg_result="${5:-SKIP}"
    local reg_exit="${6:-0}"
    local serial_result="${7:-SKIP}"
    local serial_exit="${8:-0}"
    local firmware="${9:-}"
    local elf="${10:-}"
    {
        echo "BUILD_RESULT=$build_result"
        echo "BUILD_EXIT=$build_exit"
        echo "FLASH_RESULT=$flash_result"
        echo "FLASH_EXIT=$flash_exit"
        echo "REG_RESULT=$reg_result"
        echo "REG_EXIT=$reg_exit"
        echo "SERIAL_RESULT=$serial_result"
        echo "SERIAL_EXIT=$serial_exit"
        echo "FIRMWARE=$firmware"
        echo "ELF_FILE=$elf"
        echo "EVIDENCE_DIR=$EVIDENCE_DIR"
        echo "TIMESTAMP=$TIMESTAMP"
    } > "$EVIDENCE_DIR/summary.env"
}

# Step 1: 编译
log_step "[1/4] 编译"
set +e
bash "$SCRIPT_DIR/build.sh" > "$EVIDENCE_DIR/build.log" 2>&1
BUILD_EXIT=$?
set -e

if [ $BUILD_EXIT -ne 0 ]; then
    log_error "编译失败（退出码: $BUILD_EXIT）"
    write_summary FAIL "$BUILD_EXIT"
    banner "调试循环终止：编译失败"
    log_info "编译日志: $EVIDENCE_DIR/build.log"
    cat "$EVIDENCE_DIR/build.log"
    exit 1
fi
log_ok "编译成功"

# 查找固件与 ELF
FIRMWARE=$(find_firmware "$PROJECT_DIR/build") || { log_error "编译成功但未找到固件文件"; exit 1; }
ELF_FILE=$(find_elf "$PROJECT_DIR/build" || true)
log_info "固件: $FIRMWARE"
[ -n "$ELF_FILE" ] && log_info "ELF:  $ELF_FILE"

# Step 2: 烧录
log_step "[2/4] 烧录"
set +e
bash "$SCRIPT_DIR/flash.sh" "$FIRMWARE" > "$EVIDENCE_DIR/flash.log" 2>&1
FLASH_EXIT=$?
set -e

if [ $FLASH_EXIT -ne 0 ]; then
    log_error "烧录失败（退出码: $FLASH_EXIT）"
    write_summary PASS "$BUILD_EXIT" FAIL "$FLASH_EXIT"
    banner "调试循环终止：烧录失败"
    log_info "烧录日志: $EVIDENCE_DIR/flash.log"
    cat "$EVIDENCE_DIR/flash.log"
    exit 2
fi
log_ok "烧录成功"

# Step 3: 寄存器读取
log_step "[3/4] 读取寄存器"

REG_EXIT=0
if [ -n "$ELF_FILE" ]; then
    set +e
    bash "$SCRIPT_DIR/debug.sh" --output "$EVIDENCE_DIR/registers-general.md" "$ELF_FILE" >/dev/null 2>&1
    REG_EXIT=$?
    set -e

    if [ -f "$PERIPH_ADDRS_FILE" ]; then
        set +e
        bash "$SCRIPT_DIR/debug.sh" --batch "$PERIPH_ADDRS_FILE" --output "$EVIDENCE_DIR/registers-periph.md" "$ELF_FILE" >/dev/null 2>&1
        set -e
    fi

    if [ $REG_EXIT -eq 0 ]; then
        log_ok "寄存器读取成功"
    else
        log_warn "寄存器读取失败（退出码: $REG_EXIT），继续执行"
    fi
else
    log_warn "跳过：未找到 .elf 文件"
fi

# Step 4: 串口观察
log_step "[4/4] 串口观察 (${SERIAL_TIMEOUT}s)"
SPORT="${SERIAL_PORT:-COM3}"
SBAUD="${SERIAL_BAUDRATE:-115200}"

set +e
bash "$SCRIPT_DIR/serial.sh" "$SPORT" "$SBAUD" "$SERIAL_TIMEOUT" > "$EVIDENCE_DIR/serial.log" 2>&1
SERIAL_EXIT=$?
set -e

if [ $SERIAL_EXIT -eq 0 ]; then
    log_ok "串口捕获完成"
else
    log_warn "串口捕获失败或超时（退出码: $SERIAL_EXIT）"
fi

# 汇总
reg_result="PASS"; [ $REG_EXIT -ne 0 ] && reg_result="FAIL"
serial_result="PASS"; [ $SERIAL_EXIT -ne 0 ] && serial_result="FAIL"
write_summary PASS "$BUILD_EXIT" PASS "$FLASH_EXIT" "$reg_result" "$REG_EXIT" "$serial_result" "$SERIAL_EXIT" "$FIRMWARE" "${ELF_FILE:-}"

banner "调试循环完成"
log_info "证据目录: $EVIDENCE_DIR"
echo "  - build.log               编译日志"
echo "  - flash.log               烧录日志"
[ -f "$EVIDENCE_DIR/registers-general.md" ] && echo "  - registers-general.md    通用寄存器转储"
[ -f "$EVIDENCE_DIR/registers-periph.md" ]  && echo "  - registers-periph.md     外设寄存器转储"
echo "  - serial.log              串口输出"
echo "  - summary.env             结果汇总"
