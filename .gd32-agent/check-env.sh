#!/bin/bash
# GD32 AI Agent 环境检查脚本

echo "=========================================="
echo "GD32 AI Agent 环境检查"
echo "=========================================="
echo ""

# 检查结果
OPENOCD_FOUND=0
GDB_FOUND=0
PYTHON_FOUND=0
PYSERIAL_FOUND=0

# 检查 OpenOCD
echo "检查 OpenOCD..."
if command -v openocd &> /dev/null; then
    OPENOCD_PATH=$(which openocd)
    OPENOCD_VERSION=$(openocd --version 2>&1 | head -1)
    echo "✅ OpenOCD 已安装"
    echo "   路径: $OPENOCD_PATH"
    echo "   版本: $OPENOCD_VERSION"
    OPENOCD_FOUND=1
else
    echo "❌ OpenOCD 未安装"
fi

echo ""

# 检查 GDB
echo "检查 GDB..."
if command -v arm-none-eabi-gdb &> /dev/null; then
    GDB_PATH=$(which arm-none-eabi-gdb)
    GDB_VERSION=$(arm-none-eabi-gdb --version 2>&1 | head -1)
    echo "✅ GDB 已安装"
    echo "   路径: $GDB_PATH"
    echo "   版本: $GDB_VERSION"
    GDB_FOUND=1
else
    echo "❌ GDB 未安装"
fi

echo ""

# 检查 Python
echo "检查 Python..."
if command -v python &> /dev/null; then
    PYTHON_PATH=$(which python)
    PYTHON_VERSION=$(python --version 2>&1)
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
if python -c "import serial" &> /dev/null; then
    PYSERIAL_VERSION=$(python -c "import serial; print(serial.__version__)")
    echo "✅ pyserial 已安装"
    echo "   版本: $PYSERIAL_VERSION"
    PYSERIAL_FOUND=1
else
    echo "❌ pyserial 未安装"
fi

echo ""

# 检查 GCC（可选）
echo "检查 GCC（可选）..."
if command -v arm-none-eabi-gcc &> /dev/null; then
    GCC_PATH=$(which arm-none-eabi-gcc)
    GCC_VERSION=$(arm-none-eabi-gcc --version 2>&1 | head -1)
    echo "✅ GCC 已安装"
    echo "   路径: $GCC_PATH"
    echo "   版本: $GCC_VERSION"
else
    echo "⚠️ GCC 未安装（可选）"
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
    echo "请选择："
    echo "1. 自动安装"
    echo "2. 手动安装"
    echo "3. 其他"
fi

echo ""
echo "=========================================="
