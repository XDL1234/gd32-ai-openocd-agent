#!/bin/bash
# GD32 AI Agent 工程扫描脚本

echo "=========================================="
echo "GD32 AI Agent 工程扫描"
echo "=========================================="
echo ""

# 扫描时间
SCAN_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "扫描时间: $SCAN_TIME"
echo ""

# 工程路径
PROJECT_PATH=$(pwd)
echo "工程路径: $PROJECT_PATH"
echo ""

# 扫描启动文件
echo "扫描启动文件..."
STARTUP_FILES=$(find . -name "startup_*.s" 2>/dev/null | head -5)
if [ -n "$STARTUP_FILES" ]; then
    echo "✅ 找到启动文件："
    echo "$STARTUP_FILES"
else
    echo "❌ 未找到启动文件"
fi

echo ""

# 扫描链接脚本
echo "扫描链接脚本..."
LINKER_FILES=$(find . -name "*.ld" 2>/dev/null | head -5)
if [ -n "$LINKER_FILES" ]; then
    echo "✅ 找到链接脚本："
    echo "$LINKER_FILES"
else
    echo "❌ 未找到链接脚本"
fi

echo ""

# 扫描头文件
echo "扫描头文件..."
HEADER_FILES=$(find . -name "gd32*.h" -o -name "stm32*.h" 2>/dev/null | head -5)
if [ -n "$HEADER_FILES" ]; then
    echo "✅ 找到头文件："
    echo "$HEADER_FILES"
else
    echo "❌ 未找到头文件"
fi

echo ""

# 识别库类型
echo "识别库类型..."
GD32_HEADERS=$(find . -name "gd32f4xx*.h" 2>/dev/null | head -1)
STM32_HEADERS=$(find . -name "stm32f4xx_hal*.h" 2>/dev/null | head -1)

if [ -n "$GD32_HEADERS" ]; then
    echo "✅ 库类型: 标准库"
    echo "   依据: 发现 $GD32_HEADERS"
    LIB_TYPE="standard"
elif [ -n "$STM32_HEADERS" ]; then
    echo "✅ 库类型: HAL 库"
    echo "   依据: 发现 $STM32_HEADERS"
    LIB_TYPE="hal"
else
    echo "❌ 无法识别库类型"
    LIB_TYPE="unknown"
fi

echo ""

# 识别芯片型号
echo "识别芯片型号..."
CHIP_MODEL="unknown"
CHIP_SERIES="unknown"

# 从启动文件识别
if [ -n "$STARTUP_FILES" ]; then
    STARTUP_NAME=$(basename "$STARTUP_FILES" | head -1)
    if [[ "$STARTUP_NAME" == *"gd32f450"* ]] || [[ "$STARTUP_NAME" == *"gd32f470"* ]]; then
        CHIP_SERIES="GD32F4xx"
        echo "✅ 芯片系列: $CHIP_SERIES"
        echo "   依据: 启动文件 $STARTUP_NAME"
    elif [[ "$STARTUP_NAME" == *"gd32f30"* ]] || [[ "$STARTUP_NAME" == *"gd32f303"* ]]; then
        CHIP_SERIES="GD32F3xx"
        echo "✅ 芯片系列: $CHIP_SERIES"
        echo "   依据: 启动文件 $STARTUP_NAME"
    elif [[ "$STARTUP_NAME" == *"gd32f10"* ]] || [[ "$STARTUP_NAME" == *"gd32f103"* ]]; then
        CHIP_SERIES="GD32F1xx"
        echo "✅ 芯片系列: $CHIP_SERIES"
        echo "   依据: 启动文件 $STARTUP_NAME"
    elif [[ "$STARTUP_NAME" == *"gd32e23"* ]] || [[ "$STARTUP_NAME" == *"gd32e2"* ]]; then
        CHIP_SERIES="GD32E2xx"
        echo "✅ 芯片系列: $CHIP_SERIES"
        echo "   依据: 启动文件 $STARTUP_NAME"
    fi
fi

# 从链接脚本识别
if [ -n "$LINKER_FILES" ]; then
    LINKER_NAME=$(basename "$LINKER_FILES" | head -1)
    if [[ "$LINKER_NAME" == *"gd32f470"* ]] || [[ "$LINKER_NAME" == *"gd32f450"* ]]; then
        CHIP_MODEL="GD32F4xx"
        echo "✅ 芯片型号: $CHIP_MODEL"
        echo "   依据: 链接脚本 $LINKER_NAME"
    elif [[ "$LINKER_NAME" == *"gd32f303"* ]] || [[ "$LINKER_NAME" == *"gd32f30"* ]]; then
        CHIP_MODEL="GD32F3xx"
        echo "✅ 芯片型号: $CHIP_MODEL"
        echo "   依据: 链接脚本 $LINKER_NAME"
    elif [[ "$LINKER_NAME" == *"gd32f103"* ]] || [[ "$LINKER_NAME" == *"gd32f10"* ]]; then
        CHIP_MODEL="GD32F1xx"
        echo "✅ 芯片型号: $CHIP_MODEL"
        echo "   依据: 链接脚本 $LINKER_NAME"
    elif [[ "$LINKER_NAME" == *"gd32e23"* ]] || [[ "$LINKER_NAME" == *"gd32e2"* ]]; then
        CHIP_MODEL="GD32E2xx"
        echo "✅ 芯片型号: $CHIP_MODEL"
        echo "   依据: 链接脚本 $LINKER_NAME"
    fi
fi

echo ""

# 识别工程类型
echo "识别工程类型..."
PROJECT_TYPE="unknown"

if [ -f "CMakeLists.txt" ]; then
    PROJECT_TYPE="CMake"
    echo "✅ 工程类型: CMake"
    echo "   依据: 发现 CMakeLists.txt"
elif [ -f "Makefile" ]; then
    PROJECT_TYPE="Make"
    echo "✅ 工程类型: Make"
    echo "   依据: 发现 Makefile"
elif find . -name "*.uvprojx" -o -name "*.uvproj" 2>/dev/null | head -1 | grep -q .; then
    PROJECT_TYPE="Keil"
    echo "✅ 工程类型: Keil MDK"
    echo "   依据: 发现 .uvprojx 文件"
elif find . -name "*.ewp" 2>/dev/null | head -1 | grep -q .; then
    PROJECT_TYPE="IAR"
    echo "✅ 工程类型: IAR"
    echo "   依据: 发现 .ewp 文件"
else
    echo "❌ 无法识别工程类型"
fi

echo ""

# 生成扫描报告
REPORT_FILE="docs/analysis/project-scan-report.md"
mkdir -p docs/analysis

cat > "$REPORT_FILE" << EOF
# 工程扫描报告

## 扫描时间
$SCAN_TIME

## 工程信息
- 工程路径：$PROJECT_PATH
- 工程类型：$PROJECT_TYPE

## 芯片信息
- 芯片型号：$CHIP_MODEL
- 芯片系列：$CHIP_SERIES

## 库类型
- 类型：$LIB_TYPE

## 文件结构
- 启动文件：$STARTUP_FILES
- 链接脚本：$LINKER_FILES
- 头文件：$HEADER_FILES

## 确认选项
1. 分析正确
2. 分析有误，再次分析
3. 用户自己描述问题在哪
EOF

echo "=========================================="
echo "扫描完成"
echo "=========================================="
echo ""
echo "扫描报告已生成: $REPORT_FILE"
echo ""

# 自动回填 config.env
CONFIG_FILE=".gd32-agent/config.env"
if [ -f "$CONFIG_FILE" ]; then
    UPDATED=false

    # 自动检测 OpenOCD 路径
    CURRENT_OPENOCD=$(grep "^OPENOCD_PATH=" "$CONFIG_FILE" | cut -d'"' -f2)
    if [ -z "$CURRENT_OPENOCD" ]; then
        DETECTED_OPENOCD=$(which openocd 2>/dev/null)
        if [ -z "$DETECTED_OPENOCD" ]; then
            for candidate in \
                "/usr/bin/openocd" \
                "/usr/local/bin/openocd" \
                "/opt/openocd/bin/openocd" \
                "/c/Program Files/openocd/bin/openocd.exe" \
                "/c/Program Files (x86)/openocd/bin/openocd.exe" \
                /d/openocd/xpack-openocd-*/bin/openocd.exe \
                /c/openocd/xpack-openocd-*/bin/openocd.exe \
                "$HOME/.local/xPacks/@xpack-dev-tools/openocd/*/content/bin/openocd.exe" \
                "/c/xpack-openocd/bin/openocd.exe"; do
                if [ -f "$candidate" ]; then
                    DETECTED_OPENOCD="$candidate"
                    break
                fi
            done
        fi
        if [ -n "$DETECTED_OPENOCD" ]; then
            sed -i "s|^OPENOCD_PATH=.*|OPENOCD_PATH=\"$DETECTED_OPENOCD\"|" "$CONFIG_FILE"
            echo "✅ 已自动设置 OPENOCD_PATH=$DETECTED_OPENOCD"
            UPDATED=true
        fi
    fi

    # 自动检测串口
    CURRENT_PORT=$(grep "^SERIAL_PORT=" "$CONFIG_FILE" | cut -d'"' -f2)
    if [ "$CURRENT_PORT" = "COM3" ] || [ -z "$CURRENT_PORT" ]; then
        SERIAL_OUTPUT=$(bash .gd32-agent/detect-serial.sh 2>/dev/null)
        DETECTED_PORT=$(echo "$SERIAL_OUTPUT" | grep "^DETECTED_PORT=" | cut -d'=' -f2)
        if [ -n "$DETECTED_PORT" ]; then
            sed -i "s|^SERIAL_PORT=.*|SERIAL_PORT=\"$DETECTED_PORT\"|" "$CONFIG_FILE"
            echo "✅ 已自动设置 SERIAL_PORT=$DETECTED_PORT"
            UPDATED=true
        fi
    fi

    if [ "$UPDATED" = true ]; then
        echo ""
        echo "config.env 已自动更新，请确认配置是否正确。"
    fi
fi

echo ""
echo "请确认扫描结果："
echo "1. 分析正确"
echo "2. 分析有误，再次分析"
echo "3. 用户自己描述问题在哪"
echo ""
echo "=========================================="
