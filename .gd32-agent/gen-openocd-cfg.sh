#!/bin/bash
# 根据 hardware/hardware.md 自动生成 openocd.cfg

HARDWARE_MD="hardware/hardware.md"
OUTPUT_CFG=".gd32-agent/openocd.cfg"

if [ ! -f "$HARDWARE_MD" ]; then
    echo "错误: 未找到 $HARDWARE_MD"
    echo "请先填写硬件文档"
    exit 1
fi

echo "=========================================="
echo "自动生成 OpenOCD 配置"
echo "=========================================="

# 提取 LINK 类型
LINK_TYPE=$(grep -i "LINK.*类型\|调试器\|debugger" "$HARDWARE_MD" | head -1 | sed 's/.*[：:]\s*//' | tr -d '[:space:]')

# 提取芯片系列
CHIP_SERIES=$(grep -i "芯片系列\|chip.*series" "$HARDWARE_MD" | head -1 | sed 's/.*[：:]\s*//' | tr -d '[:space:]')

# 提取下载速度
ADAPTER_SPEED=$(grep -i "下载速度\|adapter.*speed\|速度" "$HARDWARE_MD" | head -1 | sed 's/.*[：:]\s*//' | tr -d '[:space:]')
ADAPTER_SPEED="${ADAPTER_SPEED:-10000}"

echo "调试器: $LINK_TYPE"
echo "芯片系列: $CHIP_SERIES"
echo "适配器速度: $ADAPTER_SPEED"
echo ""

# 映射 interface
case "$LINK_TYPE" in
    *ST-LINK*|*STLINK*|*stlink*)
        INTERFACE="interface/stlink.cfg"
        TRANSPORT="hla_swd"
        ;;
    *DAPLink*|*daplink*|*CMSIS-DAP*|*cmsis-dap*|*DAP*)
        INTERFACE="interface/cmsis-dap.cfg"
        TRANSPORT="swd"
        ;;
    *J-Link*|*jlink*|*JLINK*)
        INTERFACE="interface/jlink.cfg"
        TRANSPORT="swd"
        ;;
    *)
        echo "警告: 无法识别调试器类型 '$LINK_TYPE'，默认使用 cmsis-dap"
        INTERFACE="interface/cmsis-dap.cfg"
        TRANSPORT="swd"
        ;;
esac

# 映射 target
case "$CHIP_SERIES" in
    *GD32F1*|*gd32f1*)
        TARGET="target/stm32f1x.cfg"
        ;;
    *GD32F3*|*gd32f3*)
        TARGET="target/stm32f3x.cfg"
        ;;
    *GD32F4*|*gd32f4*)
        TARGET="target/stm32f4x.cfg"
        ;;
    *GD32E2*|*gd32e2*)
        TARGET="target/stm32f0x.cfg"
        ;;
    *GD32VF*|*gd32vf*)
        echo "错误: GD32VF RISC-V 系列需要专用 target 配置，请手动配置"
        exit 1
        ;;
    *)
        echo "警告: 无法识别芯片系列 '$CHIP_SERIES'，默认使用 stm32f4x.cfg"
        TARGET="target/stm32f4x.cfg"
        ;;
esac

echo "Interface: $INTERFACE"
echo "Transport: $TRANSPORT"
echo "Target: $TARGET"
echo ""

# 生成配置文件
cat > "$OUTPUT_CFG" << EOF
# OpenOCD 配置文件（自动生成）
# 调试器: $LINK_TYPE
# 芯片系列: $CHIP_SERIES
# 生成时间: $(date "+%Y-%m-%d %H:%M:%S")

source [find $INTERFACE]
transport select $TRANSPORT
adapter speed $ADAPTER_SPEED
source [find $TARGET]

reset_config srst_only
EOF

echo "=========================================="
echo "配置文件已生成: $OUTPUT_CFG"
echo "=========================================="
cat "$OUTPUT_CFG"
