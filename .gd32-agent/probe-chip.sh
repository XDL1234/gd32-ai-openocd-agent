#!/bin/bash
# GD32 芯片硬件探测脚本
# 通过 OpenOCD 连接芯片，读取 DBGMCU_IDCODE / Flash Size / Unique ID
#
# 设计原则：
#   - 容错：调试器未连接不阻塞 init 流程（始终返回退出码 0）
#   - 探测模式：init 阶段无 openocd.cfg 时自动生成最小探测配置
#   - 一次性全读：单次 OpenOCD 会话读取所有可能的寄存器地址
#   - 跨平台：Windows(Git Bash)/Linux/macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

# 加载芯片数据库
# shellcheck disable=SC1091
source "$SCRIPT_DIR/gd32-chip-db.sh"

OPENOCD=$(resolve_openocd || true)

# ===== 参数解析 =====
INTERFACE_HINT=""
OUTPUT_FILE=""
VERBOSE=0
TIMEOUT=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --interface|-i)
            INTERFACE_HINT="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --timeout|-t)
            TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo ""
            echo "通过 OpenOCD 连接芯片，读取 DBGMCU_IDCODE / Flash / UID"
            echo ""
            echo "选项:"
            echo "  --interface/-i <type>   调试器类型提示 (daplink|stlink|jlink)"
            echo "  --output/-o <file>      输出结果到文件（默认 .gd32-agent/probe-result.env）"
            echo "  --verbose/-v            详细输出"
            echo "  --timeout/-t <sec>      连接超时秒数（默认 10）"
            echo ""
            echo "示例:"
            echo "  $0                           # 自动探测"
            echo "  $0 --interface daplink       # 指定 DAPLink"
            echo "  $0 -v -t 15                  # 详细模式，15秒超时"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done

# ===== 写入结果文件的辅助函数 =====
RESULT_FILE="${OUTPUT_FILE:-$SCRIPT_DIR/probe-result.env}"

write_result() {
    local result="$1"
    local reason="$2"
    cat > "$RESULT_FILE" << EOF
# GD32 芯片探测结果
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

PROBE_RESULT="$result"
PROBE_REASON="$reason"
PROBE_DEBUGGER="${PROBE_DEBUGGER:-}"
PROBE_DPIDR="${PROBE_DPIDR:-}"
PROBE_DBGMCU_ADDR="${PROBE_DBGMCU_ADDR:-}"
PROBE_IDCODE_RAW="${PROBE_IDCODE_RAW:-}"
PROBE_DEV_ID="${PROBE_DEV_ID:-}"
PROBE_REV_ID="${PROBE_REV_ID:-}"
PROBE_CHIP_MODEL="${PROBE_CHIP_MODEL:-unknown}"
PROBE_CHIP_SERIES="${PROBE_CHIP_SERIES:-unknown}"
PROBE_CPU_CORE="${PROBE_CPU_CORE:-unknown}"
PROBE_FLASH_KB="${PROBE_FLASH_KB:-0}"
PROBE_SRAM_KB="${PROBE_SRAM_KB:-0}"
PROBE_UID="${PROBE_UID:-}"
PROBE_NOTE="${PROBE_NOTE:-}"
EOF
}

# ===== 前置检查 =====
echo "=========================================="
echo "GD32 芯片硬件探测"
echo "=========================================="
echo ""

if [ -z "$OPENOCD" ]; then
    echo "❌ 未找到 OpenOCD，跳过硬件探测"
    echo "   提示: 安装 OpenOCD 后可直接读取芯片硬件信息"
    write_result "SKIP" "openocd_not_found"
    exit 0
fi

echo "OpenOCD: $OPENOCD"
echo ""

# ===== 生成探测用最小 OpenOCD 配置 =====
PROBE_CFG_DIR="$SCRIPT_DIR/probe-configs"
mkdir -p "$PROBE_CFG_DIR"

# DAPLink (CMSIS-DAP) — GD32 开发板最常见
cat > "$PROBE_CFG_DIR/probe-daplink.cfg" << 'CFGEOF'
source [find interface/cmsis-dap.cfg]
transport select swd
adapter speed 1000
source [find target/stm32f4x.cfg]
CFGEOF

# ST-Link
cat > "$PROBE_CFG_DIR/probe-stlink.cfg" << 'CFGEOF'
source [find interface/stlink.cfg]
transport select hla_swd
adapter speed 1000
source [find target/stm32f4x.cfg]
CFGEOF

# J-Link
cat > "$PROBE_CFG_DIR/probe-jlink.cfg" << 'CFGEOF'
source [find interface/jlink.cfg]
transport select swd
adapter speed 1000
source [find target/stm32f4x.cfg]
CFGEOF

# ===== 确定探测配置优先级 =====
build_probe_list() {
    local list=()

    # 已有 openocd.cfg 优先
    if [ -f "$SCRIPT_DIR/openocd.cfg" ]; then
        list+=("$SCRIPT_DIR/openocd.cfg")
    fi

    # 根据用户提示排序
    case "$INTERFACE_HINT" in
        *daplink*|*DAP*|*cmsis*|*CMSIS*)
            list+=("$PROBE_CFG_DIR/probe-daplink.cfg")
            list+=("$PROBE_CFG_DIR/probe-stlink.cfg")
            list+=("$PROBE_CFG_DIR/probe-jlink.cfg")
            ;;
        *stlink*|*ST-LINK*|*ST-Link*|*st-link*)
            list+=("$PROBE_CFG_DIR/probe-stlink.cfg")
            list+=("$PROBE_CFG_DIR/probe-daplink.cfg")
            list+=("$PROBE_CFG_DIR/probe-jlink.cfg")
            ;;
        *jlink*|*J-Link*|*j-link*|*JLINK*)
            list+=("$PROBE_CFG_DIR/probe-jlink.cfg")
            list+=("$PROBE_CFG_DIR/probe-daplink.cfg")
            list+=("$PROBE_CFG_DIR/probe-stlink.cfg")
            ;;
        *)
            # 默认: DAPLink 优先
            list+=("$PROBE_CFG_DIR/probe-daplink.cfg")
            list+=("$PROBE_CFG_DIR/probe-stlink.cfg")
            list+=("$PROBE_CFG_DIR/probe-jlink.cfg")
            ;;
    esac

    # 去重输出
    printf '%s\n' "${list[@]}" | awk '!seen[$0]++'
}

# ===== 构造一次性读取命令 =====
build_probe_commands() {
    local cmds="init; halt; "
    # DBGMCU_IDCODE（两个可能的地址）
    cmds+="echo \">>> DBGMCU_E004\"; mdw 0xE0042000 1; "
    cmds+="echo \">>> DBGMCU_4001\"; mdw 0x40015800 1; "
    # Flash size（两个可能的地址）
    cmds+="echo \">>> FLASH_7A22\"; mdw 0x1FFF7A22 1; "
    cmds+="echo \">>> FLASH_F7E0\"; mdw 0x1FFFF7E0 1; "
    # Unique ID（两组，各3个32位字）
    cmds+="echo \">>> UID_7A10\"; mdw 0x1FFF7A10 3; "
    cmds+="echo \">>> UID_F7E8\"; mdw 0x1FFFF7E8 3; "
    cmds+="echo \">>> PROBE_DONE\"; "
    cmds+="exit"
    echo "$cmds"
}

# ===== 尝试连接并读取 =====
# 参数: $1 = 配置文件路径
# 成功时设置: RAW_OUTPUT, USED_CFG
try_connect() {
    local cfg="$1"
    local cfg_name
    cfg_name=$(basename "$cfg")

    [ $VERBOSE -eq 1 ] && echo "  尝试: $cfg_name ..."

    local cmds
    cmds=$(build_probe_commands)
    local tmp
    tmp=$(mktemp)

    timeout "$TIMEOUT" "$OPENOCD" -f "$cfg" -c "$cmds" > "$tmp" 2>&1
    local rc=$?

    if [ $rc -eq 0 ] || grep -q "PROBE_DONE" "$tmp" 2>/dev/null; then
        RAW_OUTPUT=$(cat "$tmp")
        USED_CFG="$cfg"
        rm -f "$tmp"
        return 0
    else
        [ $VERBOSE -eq 1 ] && echo "    失败（退出码: $rc）"
        [ $VERBOSE -eq 1 ] && grep -i "error\|fail" "$tmp" | head -3 | sed 's/^/    /'
        rm -f "$tmp"
        return 1
    fi
}

# ===== 从 OpenOCD 输出中提取 mdw 值 =====
# 参数: $1 = 原始输出, $2 = 标记（如 "DBGMCU_E004"）
extract_mdw_value() {
    local output="$1"
    local marker="$2"
    # mdw 输出格式: "0xADDRESS: VALUE" 或含其他前缀
    echo "$output" | sed -n "/>>> $marker/,/>>> /p" | grep -oE ': [0-9a-fA-F]+' | head -1 | sed 's/: /0x/'
}

# 提取 mdw 多字值（如 UID 的 3 个 word）
extract_mdw_multi() {
    local output="$1"
    local marker="$2"
    echo "$output" | sed -n "/>>> $marker/,/>>> /p" | grep -oE ': [0-9a-fA-F]+' | sed 's/: /0x/' | tr '\n' '-' | sed 's/-$//'
}

# ===== 主探测流程 =====
echo "--- 连接芯片 ---"

RAW_OUTPUT=""
USED_CFG=""
CONNECTED=0

while IFS= read -r cfg; do
    [ -z "$cfg" ] && continue
    if try_connect "$cfg"; then
        CONNECTED=1
        echo "✅ 连接成功"
        echo "   使用配置: $(basename "$USED_CFG")"
        break
    fi
done < <(build_probe_list)

if [ $CONNECTED -eq 0 ]; then
    echo "❌ 无法连接芯片"
    echo "   可能原因:"
    echo "   - 调试器未连接 USB"
    echo "   - 目标板未上电"
    echo "   - SWD 线路故障"
    echo ""
    write_result "FAIL" "connection_failed"
    exit 0
fi

# ===== 解析 OpenOCD 输出 =====
echo ""
echo "--- 解析芯片信息 ---"

# SWD DPIDR
PROBE_DPIDR=$(echo "$RAW_OUTPUT" | grep -oE "SWD DPIDR 0x[0-9a-fA-F]+" | head -1 | awk '{print $3}')
[ -n "$PROBE_DPIDR" ] && echo "✅ SWD DPIDR: $PROBE_DPIDR"

# CPU 类型（从 OpenOCD 自动检测输出提取）
DETECTED_CPU=$(echo "$RAW_OUTPUT" | grep -oE "Cortex-M[0-9]+" | head -1)
[ -n "$DETECTED_CPU" ] && echo "✅ CPU 检测: $DETECTED_CPU"

# DBGMCU_IDCODE
IDCODE_E004=$(extract_mdw_value "$RAW_OUTPUT" "DBGMCU_E004")
IDCODE_4001=$(extract_mdw_value "$RAW_OUTPUT" "DBGMCU_4001")

[ $VERBOSE -eq 1 ] && echo "  DBGMCU@0xE0042000 原始值: ${IDCODE_E004:-无}"
[ $VERBOSE -eq 1 ] && echo "  DBGMCU@0x40015800 原始值: ${IDCODE_4001:-无}"

# 确定有效 IDCODE
PROBE_DBGMCU_ADDR=""
PROBE_IDCODE_RAW=""

is_valid_value() {
    local v="$1"
    [ -n "$v" ] && [ "$v" != "0x00000000" ] && [ "$v" != "0x0" ] && [ "$v" != "0xFFFFFFFF" ] && [ "$v" != "0xffffffff" ]
}

if is_valid_value "$IDCODE_E004"; then
    PROBE_DBGMCU_ADDR="0xE0042000"
    PROBE_IDCODE_RAW="$IDCODE_E004"
    echo "✅ DBGMCU_IDCODE @ 0xE0042000: $IDCODE_E004"
elif is_valid_value "$IDCODE_4001"; then
    PROBE_DBGMCU_ADDR="0x40015800"
    PROBE_IDCODE_RAW="$IDCODE_4001"
    echo "✅ DBGMCU_IDCODE @ 0x40015800: $IDCODE_4001"
else
    echo "❌ 无法读取有效的 DBGMCU_IDCODE"
    echo "   0xE0042000 = ${IDCODE_E004:-无数据}"
    echo "   0x40015800 = ${IDCODE_4001:-无数据}"
    echo ""
    # 仍然输出部分结果（调试器类型等）
    PROBE_DEBUGGER="unknown"
    case "$(basename "$USED_CFG")" in
        *daplink*|*cmsis*) PROBE_DEBUGGER="DAPLink" ;;
        *stlink*)          PROBE_DEBUGGER="ST-Link" ;;
        *jlink*)           PROBE_DEBUGGER="J-Link" ;;
    esac
    PROBE_CHIP_MODEL="unknown"
    PROBE_CHIP_SERIES="unknown"
    PROBE_CPU_CORE="${DETECTED_CPU:-unknown}"
    PROBE_FLASH_KB="0"
    PROBE_SRAM_KB="0"
    PROBE_NOTE="IDCODE 读取失败，仅确认调试器连接正常"
    write_result "PARTIAL" "idcode_invalid"
    echo "=========================================="
    echo "部分探测完成（IDCODE 读取失败）"
    echo "  调试器: $PROBE_DEBUGGER"
    echo "  CPU: $PROBE_CPU_CORE"
    echo "=========================================="
    exit 0
fi

# ===== 查询芯片数据库 =====
PROBE_DEV_ID=$(parse_dev_id "$PROBE_IDCODE_RAW")
PROBE_REV_ID=$(parse_rev_id "$PROBE_IDCODE_RAW")

echo "  Device ID: $PROBE_DEV_ID"
echo "  Revision:  $PROBE_REV_ID"
echo ""

lookup_chip_by_devid "$PROBE_DEV_ID" "$PROBE_DBGMCU_ADDR"

echo "--- 芯片识别结果 ---"
if [ "$CHIP_DB_MODEL" != "unknown" ]; then
    echo "✅ 芯片型号: $CHIP_DB_MODEL"
    echo "✅ 芯片系列: $CHIP_DB_SERIES"
    echo "✅ CPU 内核: $CHIP_DB_CORE"
    [ -n "$CHIP_DB_NOTE" ] && echo "   备注: $CHIP_DB_NOTE"
    PROBE_CHIP_MODEL="$CHIP_DB_MODEL"
    PROBE_CHIP_SERIES="$CHIP_DB_SERIES"
    PROBE_CPU_CORE="$CHIP_DB_CORE"
    PROBE_NOTE="$CHIP_DB_NOTE"
else
    echo "❌ 未能识别芯片型号（DEV_ID=$PROBE_DEV_ID）"
    echo "   可能是尚未收录的 GD32 型号"
    PROBE_CHIP_MODEL="unknown"
    PROBE_CHIP_SERIES="unknown"
    PROBE_CPU_CORE="${DETECTED_CPU:-unknown}"
    PROBE_NOTE="DEV_ID=$PROBE_DEV_ID 未收录"
fi

# ===== 解析 Flash 大小 =====
echo ""
echo "--- Flash 大小 ---"

PROBE_FLASH_KB="0"

if [ "$CHIP_DB_MODEL" != "unknown" ]; then
    # 根据数据库中的 Flash 地址选择对应的读取值
    FLASH_RAW=""
    case "$CHIP_DB_FLASH_ADDR" in
        "0x1FFF7A22")
            FLASH_RAW=$(extract_mdw_value "$RAW_OUTPUT" "FLASH_7A22")
            ;;
        "0x1FFFF7E0")
            FLASH_RAW=$(extract_mdw_value "$RAW_OUTPUT" "FLASH_F7E0")
            ;;
    esac

    if is_valid_value "$FLASH_RAW"; then
        parse_flash_size "$FLASH_RAW"
        PROBE_FLASH_KB="$CHIP_DB_FLASH_KB"
        echo "✅ Flash: ${PROBE_FLASH_KB}KB"
        echo "   寄存器: $CHIP_DB_FLASH_ADDR = $FLASH_RAW"
    else
        echo "❌ 无法读取 Flash 大小（$CHIP_DB_FLASH_ADDR = ${FLASH_RAW:-无数据}）"
    fi
else
    echo "⚠️ 跳过（芯片未识别）"
fi

# ===== 估算 SRAM =====
PROBE_SRAM_KB="0"
if [ -n "$PROBE_DEV_ID" ] && [ "$PROBE_FLASH_KB" != "0" ]; then
    estimate_sram_size "$PROBE_DEV_ID" "$PROBE_FLASH_KB"
    PROBE_SRAM_KB="$CHIP_DB_SRAM_KB"
    if [ "$PROBE_SRAM_KB" != "0" ]; then
        echo "✅ SRAM: ${PROBE_SRAM_KB}KB（基于 Device ID 推断）"
    fi
fi

# ===== 解析 Unique ID =====
echo ""
echo "--- Unique ID ---"

PROBE_UID=""
if [ "$CHIP_DB_MODEL" != "unknown" ]; then
    UID_RAW=""
    case "$CHIP_DB_UID_ADDR" in
        "0x1FFF7A10")
            UID_RAW=$(extract_mdw_multi "$RAW_OUTPUT" "UID_7A10")
            ;;
        "0x1FFFF7E8")
            UID_RAW=$(extract_mdw_multi "$RAW_OUTPUT" "UID_F7E8")
            ;;
    esac

    if [ -n "$UID_RAW" ]; then
        PROBE_UID="$UID_RAW"
        echo "✅ Unique ID: $PROBE_UID"
    else
        echo "⚠️ 无法读取 Unique ID"
    fi
else
    echo "⚠️ 跳过"
fi

# ===== 调试器类型 =====
echo ""
echo "--- 调试器信息 ---"

PROBE_DEBUGGER="unknown"
case "$(basename "$USED_CFG")" in
    *daplink*|*cmsis*) PROBE_DEBUGGER="DAPLink" ;;
    *stlink*)          PROBE_DEBUGGER="ST-Link" ;;
    *jlink*)           PROBE_DEBUGGER="J-Link" ;;
    *)
        # 从 openocd.cfg 内容推断
        if [ -f "$USED_CFG" ]; then
            if grep -qi "cmsis-dap\|daplink" "$USED_CFG"; then
                PROBE_DEBUGGER="DAPLink"
            elif grep -qi "stlink" "$USED_CFG"; then
                PROBE_DEBUGGER="ST-Link"
            elif grep -qi "jlink" "$USED_CFG"; then
                PROBE_DEBUGGER="J-Link"
            fi
        fi
        ;;
esac
echo "✅ 调试器: $PROBE_DEBUGGER"

# ===== 汇总 =====
echo ""
echo "=========================================="
echo "探测结果汇总"
echo "=========================================="
echo "  调试器:        $PROBE_DEBUGGER"
echo "  SWD DPIDR:     ${PROBE_DPIDR:-N/A}"
echo "  DBGMCU_IDCODE: ${PROBE_IDCODE_RAW:-N/A} @ ${PROBE_DBGMCU_ADDR:-N/A}"
echo "  Device ID:     ${PROBE_DEV_ID:-N/A}"
echo "  Revision:      ${PROBE_REV_ID:-N/A}"
echo "  芯片型号:      ${PROBE_CHIP_MODEL:-N/A}"
echo "  芯片系列:      ${PROBE_CHIP_SERIES:-N/A}"
echo "  CPU 内核:      ${PROBE_CPU_CORE:-N/A}"
echo "  Flash:         ${PROBE_FLASH_KB}KB"
echo "  SRAM:          ${PROBE_SRAM_KB}KB（估算）"
echo "  Unique ID:     ${PROBE_UID:-N/A}"
echo "=========================================="

# ===== 写入结果文件 =====
write_result "PASS" "success"

echo ""
echo "结果已保存: $RESULT_FILE"
echo ""

exit 0
