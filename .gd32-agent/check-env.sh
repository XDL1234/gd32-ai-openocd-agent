#!/usr/bin/env bash
# GD32 AI Agent 环境检查脚本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

banner "GD32 AI Agent 环境检查"

OS_TYPE=$(detect_os)
log_info "操作系统: $OS_TYPE"

OPENOCD_FOUND=0
GDB_FOUND=0
PYTHON_FOUND=0
PYSERIAL_FOUND=0
GCC_FOUND=0

# OpenOCD
log_step "检查 OpenOCD"
if openocd_path=$(resolve_openocd); then
    openocd_version=$("$openocd_path" --version 2>&1 | head -1)
    log_ok "OpenOCD 已安装"
    echo "   路径: $openocd_path"
    echo "   版本: $openocd_version"
    OPENOCD_FOUND=1
else
    log_error "OpenOCD 未安装"
    echo "   建议: 下载 xpack-openocd 并添加到 PATH"
fi

# GDB
log_step "检查 GDB"
if gdb_path=$(resolve_gdb); then
    gdb_version=$("$gdb_path" --version 2>&1 | head -1)
    log_ok "GDB 已安装"
    echo "   路径: $gdb_path"
    echo "   版本: $gdb_version"
    GDB_FOUND=1
else
    log_error "GDB 未安装"
fi

# Python
log_step "检查 Python"
PYTHON_CMD=""
if py=$(resolve_python); then
    PYTHON_CMD="$py"
    python_version=$("$py" --version 2>&1)
    log_ok "Python 已安装"
    echo "   路径: $py"
    echo "   版本: $python_version"
    PYTHON_FOUND=1
else
    log_error "Python 未安装"
fi

# pyserial
log_step "检查 pyserial"
if [ -n "$PYTHON_CMD" ] && "$PYTHON_CMD" -c "import serial" >/dev/null 2>&1; then
    pyserial_version=$("$PYTHON_CMD" -c "import serial; print(serial.__version__)")
    log_ok "pyserial 已安装"
    echo "   版本: $pyserial_version"
    PYSERIAL_FOUND=1
else
    log_error "pyserial 未安装"
    [ -n "$PYTHON_CMD" ] && echo "   安装: $PYTHON_CMD -m pip install pyserial"
fi

# GCC (可选)
log_step "检查 ARM GCC（可选）"
if gcc_path=$(resolve_arm_gcc); then
    gcc_version=$("$gcc_path" --version 2>&1 | head -1)
    log_ok "ARM GCC 已安装"
    echo "   路径: $gcc_path"
    echo "   版本: $gcc_version"
    GCC_FOUND=1
else
    log_warn "ARM GCC 未安装（可选，仅 CMake/Make 工程需要）"
fi

# 串口设备
log_step "检查串口设备"
if [ -x "$SCRIPT_DIR/detect-serial.sh" ]; then
    bash "$SCRIPT_DIR/detect-serial.sh" 2>/dev/null | grep -v "^DETECTED_PORT=" || true
fi

banner "环境检查总结"

MISSING_TOOLS=()
[ $OPENOCD_FOUND -eq 0 ]  && MISSING_TOOLS+=("OpenOCD")
[ $GDB_FOUND -eq 0 ]      && MISSING_TOOLS+=("GDB")
[ $PYTHON_FOUND -eq 0 ]   && MISSING_TOOLS+=("Python")
[ $PYSERIAL_FOUND -eq 0 ] && MISSING_TOOLS+=("pyserial")

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    log_ok "所有必需工具已安装"
    echo "环境配置完成，可以开始使用 GD32 AI Agent"
else
    log_error "缺少以下工具：${MISSING_TOOLS[*]}"
    echo ""
    echo "安装建议："
    [ $OPENOCD_FOUND -eq 0 ]  && echo "  OpenOCD:  https://github.com/xpack-dev-tools/openocd-xpack/releases"
    [ $GDB_FOUND -eq 0 ]      && echo "  GDB:      安装 GNU Arm Embedded Toolchain"
    [ $PYTHON_FOUND -eq 0 ]   && echo "  Python:   https://www.python.org/downloads/"
    [ $PYSERIAL_FOUND -eq 0 ] && echo "  pyserial: pip install pyserial"
    exit 1
fi
