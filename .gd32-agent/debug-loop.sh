#!/bin/bash
# GD32 自动调试循环脚本
# 编译 → 烧录 → 寄存器读取 → 串口观察，一键执行全流程
# 用于 Bug 自动定位：Agent 调用此脚本收集硬件证据

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR" || exit 1

TIMESTAMP=$(date "+%Y-%m-%d_%H%M%S")
EVIDENCE_DIR=".gd32-agent/logs/debug-$TIMESTAMP"
mkdir -p "$EVIDENCE_DIR"

SERIAL_TIMEOUT="${1:-5}"
PERIPH_ADDRS_FILE="${2:-.gd32-agent/periph-addrs.txt}"

echo "=========================================="
echo "GD32 自动调试循环"
echo "=========================================="
echo "时间: $TIMESTAMP"
echo "证据目录: $EVIDENCE_DIR"
echo "串口超时: ${SERIAL_TIMEOUT}s"
echo "=========================================="

# Step 1: 编译
echo ""
echo "[1/4] 编译..."
bash .gd32-agent/build.sh > "$EVIDENCE_DIR/build.log" 2>&1
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
    echo "  编译失败（退出码: $BUILD_EXIT）"
    echo "BUILD_RESULT=FAIL" > "$EVIDENCE_DIR/summary.env"
    echo "BUILD_EXIT=$BUILD_EXIT" >> "$EVIDENCE_DIR/summary.env"
    echo ""
    echo "=========================================="
    echo "调试循环终止：编译失败"
    echo "编译日志: $EVIDENCE_DIR/build.log"
    echo "=========================================="
    cat "$EVIDENCE_DIR/build.log"
    exit 1
fi
echo "  编译成功"

# 查找固件文件
FIRMWARE=""
for f in build/*.hex build/*.bin build/*.elf; do
    [ -f "$f" ] && FIRMWARE="$f" && break
done
if [ -z "$FIRMWARE" ]; then
    echo "  错误: 编译成功但未找到固件文件"
    exit 1
fi
echo "  固件: $FIRMWARE"

# 查找 ELF（用于寄存器调试）
ELF_FILE=""
for f in build/*.elf; do
    [ -f "$f" ] && ELF_FILE="$f" && break
done

# Step 2: 烧录
echo ""
echo "[2/4] 烧录..."
bash .gd32-agent/flash.sh "$FIRMWARE" > "$EVIDENCE_DIR/flash.log" 2>&1
FLASH_EXIT=$?

if [ $FLASH_EXIT -ne 0 ]; then
    echo "  烧录失败（退出码: $FLASH_EXIT）"
    echo "BUILD_RESULT=PASS" > "$EVIDENCE_DIR/summary.env"
    echo "FLASH_RESULT=FAIL" >> "$EVIDENCE_DIR/summary.env"
    echo "FLASH_EXIT=$FLASH_EXIT" >> "$EVIDENCE_DIR/summary.env"
    echo ""
    echo "=========================================="
    echo "调试循环终止：烧录失败"
    echo "烧录日志: $EVIDENCE_DIR/flash.log"
    echo "=========================================="
    cat "$EVIDENCE_DIR/flash.log"
    exit 2
fi
echo "  烧录成功"

# Step 3: 寄存器读取
echo ""
echo "[3/4] 读取寄存器..."

REG_EXIT=0
if [ -n "$ELF_FILE" ]; then
    # 通用寄存器
    bash .gd32-agent/debug.sh --output "$EVIDENCE_DIR/registers-general.md" "$ELF_FILE" > /dev/null 2>&1
    REG_EXIT=$?

    # 外设寄存器（如果地址文件存在）
    if [ -f "$PERIPH_ADDRS_FILE" ]; then
        bash .gd32-agent/debug.sh --batch "$PERIPH_ADDRS_FILE" --output "$EVIDENCE_DIR/registers-periph.md" "$ELF_FILE" > /dev/null 2>&1
    fi

    if [ $REG_EXIT -eq 0 ]; then
        echo "  寄存器读取成功"
    else
        echo "  寄存器读取失败（退出码: $REG_EXIT），继续执行"
    fi
else
    echo "  跳过：未找到 .elf 文件"
fi

# Step 4: 串口观察
echo ""
echo "[4/4] 串口观察 (${SERIAL_TIMEOUT}s)..."
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi
SPORT="${SERIAL_PORT:-COM3}"
SBAUD="${SERIAL_BAUDRATE:-115200}"

bash .gd32-agent/serial.sh "$SPORT" "$SBAUD" "$SERIAL_TIMEOUT" > "$EVIDENCE_DIR/serial.log" 2>&1
SERIAL_EXIT=$?

if [ $SERIAL_EXIT -eq 0 ]; then
    echo "  串口捕获完成"
else
    echo "  串口捕获失败或超时（退出码: $SERIAL_EXIT）"
fi

# 汇总
{
    echo "BUILD_RESULT=PASS"
    echo "BUILD_EXIT=$BUILD_EXIT"
    echo "FLASH_RESULT=PASS"
    echo "FLASH_EXIT=$FLASH_EXIT"
    echo "REG_RESULT=$([ $REG_EXIT -eq 0 ] && echo PASS || echo FAIL)"
    echo "REG_EXIT=$REG_EXIT"
    echo "SERIAL_RESULT=$([ $SERIAL_EXIT -eq 0 ] && echo PASS || echo FAIL)"
    echo "SERIAL_EXIT=$SERIAL_EXIT"
    echo "FIRMWARE=$FIRMWARE"
    echo "ELF_FILE=$ELF_FILE"
    echo "EVIDENCE_DIR=$EVIDENCE_DIR"
    echo "TIMESTAMP=$TIMESTAMP"
} > "$EVIDENCE_DIR/summary.env"

echo ""
echo "=========================================="
echo "调试循环完成"
echo "=========================================="
echo "证据目录: $EVIDENCE_DIR"
echo "  - build.log        编译日志"
echo "  - flash.log        烧录日志"
[ -f "$EVIDENCE_DIR/registers-general.md" ] && echo "  - registers-general.md   通用寄存器转储"
[ -f "$EVIDENCE_DIR/registers-periph.md" ] && echo "  - registers-periph.md    外设寄存器转储"
echo "  - serial.log       串口输出"
echo "  - summary.env      结果汇总"
echo "=========================================="
