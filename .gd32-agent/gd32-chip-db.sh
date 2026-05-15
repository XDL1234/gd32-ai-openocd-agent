#!/bin/bash
# GD32 芯片 ID 数据库
# 提供 Device ID → 芯片型号/系列/内核/Flash地址/UID地址 的映射
# 被 probe-chip.sh 通过 source 加载

# DBGMCU_IDCODE 寄存器地址（按系列不同）
# GD32F1xx/F3xx/F4xx: 0xE0042000
# GD32E2xx: 0x40015800

# 解析 DBGMCU_IDCODE → DEV_ID（低12位）
# 参数: $1 = 32位 IDCODE 值（如 "0x10006410"）
parse_dev_id() {
    local val=$(($1))
    printf "0x%03X" $((val & 0xFFF))
}

# 解析 DBGMCU_IDCODE → REV_ID（高16位）
parse_rev_id() {
    local val=$(($1))
    printf "0x%04X" $(((val >> 16) & 0xFFFF))
}

# Device ID 到芯片信息的映射
# 参数: $1 = DEV_ID（如 "0x410"）, $2 = DBGMCU 来源地址（用于区分 0x410 冲突）
# 输出变量: CHIP_DB_MODEL, CHIP_DB_SERIES, CHIP_DB_CORE, CHIP_DB_NOTE
#           CHIP_DB_FLASH_ADDR, CHIP_DB_UID_ADDR
lookup_chip_by_devid() {
    local dev_id="$1"
    local dbgmcu_addr="$2"

    CHIP_DB_MODEL="unknown"
    CHIP_DB_SERIES="unknown"
    CHIP_DB_CORE="unknown"
    CHIP_DB_NOTE=""
    CHIP_DB_FLASH_ADDR=""
    CHIP_DB_UID_ADDR=""

    # 标准化：统一为小写 0x + 大写十六进制（如 0x434, 0x41A）
    dev_id=$(echo "$dev_id" | sed 's/^0[xX]//' | tr '[:lower:]' '[:upper:]')
    dev_id="0x${dev_id}"

    # 0x410 在 GD32F103 和 GD32E230 中重复，通过 DBGMCU 地址区分
    if [ "$dev_id" = "0x410" ] && [ "$dbgmcu_addr" = "0x40015800" ]; then
        CHIP_DB_MODEL="GD32E230"
        CHIP_DB_SERIES="GD32E2xx"
        CHIP_DB_CORE="Cortex-M23"
        CHIP_DB_NOTE="通过 DBGMCU 地址 0x40015800 确认"
        CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
        CHIP_DB_UID_ADDR="0x1FFFF7E8"
        return 0
    fi

    case "$dev_id" in
        "0x410")
            CHIP_DB_MODEL="GD32F103"
            CHIP_DB_SERIES="GD32F1xx"
            CHIP_DB_CORE="Cortex-M3"
            CHIP_DB_NOTE="Medium density (Flash<=128K)"
            CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
            CHIP_DB_UID_ADDR="0x1FFFF7E8"
            ;;
        "0x414")
            CHIP_DB_MODEL="GD32F103"
            CHIP_DB_SERIES="GD32F1xx"
            CHIP_DB_CORE="Cortex-M3"
            CHIP_DB_NOTE="High density (Flash>=256K)"
            CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
            CHIP_DB_UID_ADDR="0x1FFFF7E8"
            ;;
        "0x418")
            CHIP_DB_MODEL="GD32F105/107"
            CHIP_DB_SERIES="GD32F1xx"
            CHIP_DB_CORE="Cortex-M3"
            CHIP_DB_NOTE="Connectivity line"
            CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
            CHIP_DB_UID_ADDR="0x1FFFF7E8"
            ;;
        "0x422")
            CHIP_DB_MODEL="GD32F303xB/C"
            CHIP_DB_SERIES="GD32F3xx"
            CHIP_DB_CORE="Cortex-M4"
            CHIP_DB_NOTE="Flash<=256K"
            CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
            CHIP_DB_UID_ADDR="0x1FFFF7E8"
            ;;
        "0x432")
            CHIP_DB_MODEL="GD32F303xD/E"
            CHIP_DB_SERIES="GD32F3xx"
            CHIP_DB_CORE="Cortex-M4"
            CHIP_DB_NOTE="Flash>=384K"
            CHIP_DB_FLASH_ADDR="0x1FFFF7E0"
            CHIP_DB_UID_ADDR="0x1FFFF7E8"
            ;;
        "0x419")
            CHIP_DB_MODEL="GD32F405/407/450"
            CHIP_DB_SERIES="GD32F4xx"
            CHIP_DB_CORE="Cortex-M4"
            CHIP_DB_NOTE="基础型"
            CHIP_DB_FLASH_ADDR="0x1FFF7A22"
            CHIP_DB_UID_ADDR="0x1FFF7A10"
            ;;
        "0x434")
            CHIP_DB_MODEL="GD32F470"
            CHIP_DB_SERIES="GD32F4xx"
            CHIP_DB_CORE="Cortex-M4"
            CHIP_DB_NOTE="增强型"
            CHIP_DB_FLASH_ADDR="0x1FFF7A22"
            CHIP_DB_UID_ADDR="0x1FFF7A10"
            ;;
        *)
            CHIP_DB_NOTE="未知 Device ID: $dev_id"
            return 1
            ;;
    esac
    return 0
}

# 解析 Flash 大小寄存器值
# 参数: $1 = mdw 读取的32位原始值, $2 = 芯片系列
# 输出变量: CHIP_DB_FLASH_KB
parse_flash_size() {
    local val=$(($1))
    CHIP_DB_FLASH_KB=$((val & 0xFFFF))
}

# 基于 Device ID 和 Flash 大小推断 SRAM
# 参数: $1 = DEV_ID, $2 = Flash KB
# 输出变量: CHIP_DB_SRAM_KB
estimate_sram_size() {
    local dev_id="$1"
    local flash_kb="${2:-0}"

    dev_id=$(echo "$dev_id" | sed 's/^0[xX]//' | tr '[:lower:]' '[:upper:]')
    dev_id="0x${dev_id}"

    case "$dev_id" in
        "0x410")
            CHIP_DB_SRAM_KB=20
            ;;
        "0x414")
            if [ "$flash_kb" -ge 512 ] 2>/dev/null; then
                CHIP_DB_SRAM_KB=96
            else
                CHIP_DB_SRAM_KB=64
            fi
            ;;
        "0x418")
            CHIP_DB_SRAM_KB=96
            ;;
        "0x422")
            CHIP_DB_SRAM_KB=48
            ;;
        "0x432")
            CHIP_DB_SRAM_KB=80
            ;;
        "0x419")
            CHIP_DB_SRAM_KB=192
            ;;
        "0x434")
            CHIP_DB_SRAM_KB=256
            ;;
        *)
            CHIP_DB_SRAM_KB=0
            ;;
    esac
}
