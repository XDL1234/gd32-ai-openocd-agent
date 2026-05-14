#!/bin/bash
# 对比 hardware/hardware.md 与工程文件的一致性

HARDWARE_MD="hardware/hardware.md"

if [ ! -f "$HARDWARE_MD" ]; then
    echo "错误: 未找到 $HARDWARE_MD"
    exit 1
fi

echo "=========================================="
echo "硬件一致性检查"
echo "=========================================="

ISSUES=0

# 从 hardware.md 提取芯片型号
HW_CHIP=$(grep -i "芯片型号\|chip.*model\|MCU" "$HARDWARE_MD" | head -1 | sed 's/.*[：:]\s*//' | tr -d '[:space:]')
HW_SERIES=$(grep -i "芯片系列\|chip.*series" "$HARDWARE_MD" | head -1 | sed 's/.*[：:]\s*//' | tr -d '[:space:]')

echo "hardware.md 声明:"
echo "  芯片型号: $HW_CHIP"
echo "  芯片系列: $HW_SERIES"
echo ""

# 从启动文件检测
echo "--- 启动文件检测 ---"
STARTUP=$(find . -name "startup_*.s" -o -name "startup_*.S" 2>/dev/null | head -1)
if [ -n "$STARTUP" ]; then
    STARTUP_CHIP=$(basename "$STARTUP" | sed 's/startup_//' | sed 's/\..*//')
    echo "启动文件: $STARTUP → $STARTUP_CHIP"
    if [ -n "$HW_CHIP" ] && ! echo "$STARTUP_CHIP" | grep -qi "$(echo "$HW_CHIP" | tr '[:upper:]' '[:lower:]' | sed 's/[0-9]*$//')"; then
        echo "  ⚠️ 可能不匹配: hardware.md=$HW_CHIP vs startup=$STARTUP_CHIP"
        ISSUES=$((ISSUES + 1))
    else
        echo "  ✅ 一致"
    fi
else
    echo "  未找到启动文件"
fi

# 从链接脚本检测
echo ""
echo "--- 链接脚本检测 ---"
LD_SCRIPT=$(find . -name "*.ld" -o -name "*.lds" 2>/dev/null | head -1)
if [ -n "$LD_SCRIPT" ]; then
    FLASH_SIZE=$(grep -i "FLASH.*LENGTH\|FLASH.*len" "$LD_SCRIPT" | head -1 | grep -oE '[0-9]+[KkMm]' | head -1)
    RAM_SIZE=$(grep -i "RAM.*LENGTH\|RAM.*len" "$LD_SCRIPT" | head -1 | grep -oE '[0-9]+[KkMm]' | head -1)
    echo "链接脚本: $LD_SCRIPT"
    echo "  Flash: $FLASH_SIZE"
    echo "  RAM: $RAM_SIZE"
else
    echo "  未找到链接脚本"
fi

# 从头文件检测
echo ""
echo "--- 头文件检测 ---"
GD32_HEADER=$(find . -name "gd32f4xx.h" -o -name "gd32f3xx.h" -o -name "gd32f1xx.h" -o -name "gd32e2xx.h" -o -name "gd32f10x.h" -o -name "gd32f30x.h" -o -name "gd32f4xx_libopt.h" 2>/dev/null | head -1)
if [ -n "$GD32_HEADER" ]; then
    HEADER_SERIES=$(basename "$GD32_HEADER" | sed 's/\.h//' | sed 's/_libopt//')
    echo "GD32 头文件: $GD32_HEADER → $HEADER_SERIES"
else
    echo "  未找到 GD32 系列头文件"
fi

# 从 CMakeLists.txt / Makefile 检测宏定义
echo ""
echo "--- 编译宏检测 ---"
if [ -f "CMakeLists.txt" ]; then
    DEFINE=$(grep -oE 'GD32F[A-Za-z0-9]+' CMakeLists.txt | head -1)
    if [ -n "$DEFINE" ]; then
        echo "CMakeLists.txt 宏定义: $DEFINE"
    fi
elif [ -f "Makefile" ]; then
    DEFINE=$(grep -oE 'GD32F[A-Za-z0-9]+' Makefile | head -1)
    if [ -n "$DEFINE" ]; then
        echo "Makefile 宏定义: $DEFINE"
    fi
fi

echo ""
echo "=========================================="
if [ $ISSUES -eq 0 ]; then
    echo "✅ 检查通过，未发现明显不一致"
else
    echo "⚠️ 发现 $ISSUES 个潜在不一致，请人工确认"
fi
echo "=========================================="
