#!/bin/bash
# GD32 AI Agent 环境检查脚本
# 支持 Windows (Git Bash/MSYS2) 和 Linux/macOS

echo "=========================================="
echo "GD32 AI Agent 环境检查"
echo "=========================================="
echo ""

# 检测操作系统
OS_TYPE="unknown"
case "$(uname -s)" in
    Linux*)   OS_TYPE="Linux" ;;
    Darwin*)  OS_TYPE="macOS" ;;
    MINGW*|MSYS*|CYGWIN*) OS_TYPE="Windows" ;;
esac
echo "操作系统: $OS_TYPE"
echo ""

# 检查结果
OPENOCD_FOUND=0
GDB_FOUND=0
PYTHON_FOUND=0
PYSERIAL_FOUND=0

# 通用命令查找函数（支持 Windows PATH 和常见安装路径）
find_tool() {
    local tool_name="$1"
    shift
    local extra_paths=("$@")

    if command -v "$tool_name" &> /dev/null; then
        which "$tool_name"
        return 0
    fi

    # Windows: 搜索额外路径
    if [ "$OS_TYPE" = "Windows" ]; then
        for p in "${extra_paths[@]}"; do
            if [ -f "$p" ]; then
                echo "$p"
                return 0
            fi
        done
    fi

    return 1
}

# 检查 OpenOCD
echo "检查 OpenOCD..."
OPENOCD_RESULT=$(find_tool "openocd" \
    "D:/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe" \
    "C:/Program Files/openocd/bin/openocd.exe" \
    "C:/Program Files (x86)/openocd/bin/openocd.exe" \
    "C:/openocd/bin/openocd.exe")
if [ -n "$OPENOCD_RESULT" ]; then
    OPENOCD_VERSION=$("$OPENOCD_RESULT" --version 2>&1 | head -1)
    echo "✅ OpenOCD 已安装"
    echo "   路径: $OPENOCD_RESULT"
    echo "   版本: $OPENOCD_VERSION"
    OPENOCD_FOUND=1
else
    echo "❌ OpenOCD 未安装"
    echo "   建议: 下载 xpack-openocd 并添加到 PATH"
fi

echo ""

# 检查 GDB
echo "检查 GDB..."
GDB_RESULT=$(find_tool "arm-none-eabi-gdb" \
    "C:/Program Files (x86)/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gdb.exe" \
    "C:/Program Files/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gdb.exe")
if [ -n "$GDB_RESULT" ]; then
    GDB_VERSION=$("$GDB_RESULT" --version 2>&1 | head -1)
    echo "✅ GDB 已安装"
    echo "   路径: $GDB_RESULT"
    echo "   版本: $GDB_VERSION"
    GDB_FOUND=1
else
    echo "❌ GDB 未安装"
fi

echo ""

# 检查 Python（Windows 上可能是 python 或 python3）
echo "检查 Python..."
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    PYTHON_PATH=$(which $PYTHON_CMD)
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
    echo "✅ Python 已安装"
    echo "   路径: $PYTHON_PATH"
    echo "   版本: $PYTHON_VERSION"
    PYTHON_FOUND=1
else
    echo "❌ Python 未安装"
fi

echo ""

# 检查 pyserial
echo "检查 pyserial..."
if [ -n "$PYTHON_CMD" ] && $PYTHON_CMD -c "import serial" &> /dev/null; then
    PYSERIAL_VERSION=$($PYTHON_CMD -c "import serial; print(serial.__version__)")
    echo "✅ pyserial 已安装"
    echo "   版本: $PYSERIAL_VERSION"
    PYSERIAL_FOUND=1
else
    echo "❌ pyserial 未安装"
    if [ -n "$PYTHON_CMD" ]; then
        echo "   安装: $PYTHON_CMD -m pip install pyserial"
    fi
fi

echo ""

# 检查 GCC（可选）
echo "检查 GCC（可选）..."
GCC_RESULT=$(find_tool "arm-none-eabi-gcc" \
    "C:/Program Files (x86)/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gcc.exe" \
    "C:/Program Files/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gcc.exe")
if [ -n "$GCC_RESULT" ]; then
    GCC_VERSION=$("$GCC_RESULT" --version 2>&1 | head -1)
    echo "✅ GCC 已安装"
    echo "   路径: $GCC_RESULT"
    echo "   版本: $GCC_VERSION"
else
    echo "⚠️ GCC 未安装（可选，仅 CMake/Make 工程需要）"
fi

echo ""

# 检查串口设备
echo "检查串口设备..."
if [ -f ".gd32-agent/detect-serial.sh" ]; then
    bash .gd32-agent/detect-serial.sh 2>/dev/null | grep -v "^DETECTED_PORT="
fi

echo ""

# 总结
echo "=========================================="
echo "环境检查总结"
echo "=========================================="

MISSING_TOOLS=""

if [ $OPENOCD_FOUND -eq 0 ]; then
    MISSING_TOOLS="$MISSING_TOOLS OpenOCD"
fi

if [ $GDB_FOUND -eq 0 ]; then
    MISSING_TOOLS="$MISSING_TOOLS GDB"
fi

if [ $PYTHON_FOUND -eq 0 ]; then
    MISSING_TOOLS="$MISSING_TOOLS Python"
fi

if [ $PYSERIAL_FOUND -eq 0 ]; then
    MISSING_TOOLS="$MISSING_TOOLS pyserial"
fi

if [ -z "$MISSING_TOOLS" ]; then
    echo "✅ 所有必需工具已安装"
    echo ""
    echo "环境配置完成，可以开始使用 GD32 AI Agent"
else
    echo "❌ 缺少以下工具：$MISSING_TOOLS"
    echo ""
    echo "安装建议："
    [ $OPENOCD_FOUND -eq 0 ] && echo "  OpenOCD: https://github.com/xpack-dev-tools/openocd-xpack/releases"
    [ $GDB_FOUND -eq 0 ] && echo "  GDB: 安装 GNU Arm Embedded Toolchain"
    [ $PYTHON_FOUND -eq 0 ] && echo "  Python: https://www.python.org/downloads/"
    [ $PYSERIAL_FOUND -eq 0 ] && echo "  pyserial: pip install pyserial"
fi

echo ""
echo "=========================================="
