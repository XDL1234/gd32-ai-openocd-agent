#!/usr/bin/env bash
# .gd32-agent/lib/common.sh
# GD32 Agent 公共库：路径解析、日志、配置加载、工程检测、跨平台 timeout
#
# 设计原则：
# 1. 仅提供函数和常量，不修改调用方的 shell 选项（set -e/-u/-o pipefail 由调用方决定）
# 2. 函数返回值优先用 echo，错误时返回非零退出码，由调用方决定如何报错
# 3. 所有路径优先用 glob 匹配，避免硬编码版本号
#
# 用法：
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"
#   load_config
#   OPENOCD=$(resolve_openocd) || die "未找到 OpenOCD"

# 防止重复 source
if [ -n "${__GD32_COMMON_LOADED:-}" ]; then
    return 0 2>/dev/null || true
fi
__GD32_COMMON_LOADED=1

# ===== 路径常量 =====
# common.sh 位于 .gd32-agent/lib/，向上一级是 .gd32-agent/
COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$COMMON_LIB_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$AGENT_DIR/.." && pwd)"

# ===== 平台检测 =====
detect_os() {
    case "$(uname -s)" in
        Linux*)   echo "Linux" ;;
        Darwin*)  echo "macOS" ;;
        MINGW*|MSYS*|CYGWIN*) echo "Windows" ;;
        *)        echo "Unknown" ;;
    esac
}

# ===== 配置加载 =====
load_config() {
    if [ -f "$AGENT_DIR/config.env" ]; then
        # shellcheck disable=SC1091
        source "$AGENT_DIR/config.env"
    fi
}

# ===== 颜色与日志 =====
# 仅在 stdout 是 tty 时启用颜色
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m'
    C_INFO=$'\033[36m'   # cyan
    C_OK=$'\033[32m'     # green
    C_WARN=$'\033[33m'   # yellow
    C_ERR=$'\033[31m'    # red
    C_STEP=$'\033[1;34m' # bold blue
else
    C_RESET=""; C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_STEP=""
fi

log_info()  { printf '%s[INFO]%s  %s\n' "$C_INFO" "$C_RESET" "$*"; }
log_ok()    { printf '%s[OK]%s    %s\n'  "$C_OK"   "$C_RESET" "$*"; }
log_warn()  { printf '%s[WARN]%s  %s\n'  "$C_WARN" "$C_RESET" "$*" >&2; }
log_error() { printf '%s[ERROR]%s %s\n'  "$C_ERR"  "$C_RESET" "$*" >&2; }
log_step()  { printf '\n%s==>%s %s\n'    "$C_STEP" "$C_RESET" "$*"; }

# 致命错误并退出
die() {
    log_error "$@"
    exit 1
}

# 横幅
banner() {
    local title="$1"
    echo "=========================================="
    echo "$title"
    echo "=========================================="
}

# ===== OpenOCD 路径解析 =====
# 优先级: config.env (OPENOCD_PATH) → PATH → 常见安装路径 → glob 匹配
# 用法: OPENOCD=$(resolve_openocd) || die "未找到 OpenOCD"
resolve_openocd() {
    if [ -n "${OPENOCD_PATH:-}" ] && [ -f "$OPENOCD_PATH" ]; then
        echo "$OPENOCD_PATH"
        return 0
    fi
    if command -v openocd >/dev/null 2>&1; then
        command -v openocd
        return 0
    fi
    local candidate
    for candidate in \
        "/usr/bin/openocd" \
        "/usr/local/bin/openocd" \
        "/opt/openocd/bin/openocd" \
        "/opt/homebrew/bin/openocd" \
        "C:/openocd/bin/openocd.exe" \
        "C:/Program Files/openocd/bin/openocd.exe" \
        "C:/Program Files (x86)/openocd/bin/openocd.exe"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    # 通配匹配 xpack-openocd 任意版本
    for candidate in \
        D:/openocd/xpack-openocd-*/bin/openocd.exe \
        C:/openocd/xpack-openocd-*/bin/openocd.exe \
        D:/openocd/bin/openocd.exe; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# ===== GDB 路径解析 =====
resolve_gdb() {
    if [ -n "${GDB_PATH:-}" ] && [ -x "$GDB_PATH" ]; then
        echo "$GDB_PATH"
        return 0
    fi
    local cmd
    for cmd in arm-none-eabi-gdb gdb-multiarch; do
        if command -v "$cmd" >/dev/null 2>&1; then
            command -v "$cmd"
            return 0
        fi
    done
    local candidate
    for candidate in \
        "/usr/bin/arm-none-eabi-gdb" \
        "/usr/local/bin/arm-none-eabi-gdb" \
        "C:/Program Files (x86)/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gdb.exe" \
        "C:/Program Files/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gdb.exe"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# ===== Python 解析 =====
resolve_python() {
    if command -v python3 >/dev/null 2>&1; then
        command -v python3
        return 0
    fi
    if command -v python >/dev/null 2>&1; then
        command -v python
        return 0
    fi
    return 1
}

# ===== ARM GCC 路径解析 =====
resolve_arm_gcc() {
    if command -v arm-none-eabi-gcc >/dev/null 2>&1; then
        command -v arm-none-eabi-gcc
        return 0
    fi
    local candidate
    for candidate in \
        "/usr/bin/arm-none-eabi-gcc" \
        "/usr/local/bin/arm-none-eabi-gcc" \
        "C:/Program Files (x86)/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gcc.exe" \
        "C:/Program Files/GNU Arm Embedded Toolchain/bin/arm-none-eabi-gcc.exe"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# ===== 工程类型检测 =====
# 在 PROJECT_DIR 下检测：CMake / Make / Keil / IAR / Unknown
detect_project_type() {
    local dir="${1:-$PROJECT_DIR}"
    if [ -f "$dir/CMakeLists.txt" ]; then
        echo "CMake"
    elif [ -f "$dir/Makefile" ]; then
        echo "Make"
    elif ls "$dir"/*.uvprojx >/dev/null 2>&1; then
        echo "Keil"
    elif ls "$dir"/*.ewp >/dev/null 2>&1; then
        echo "IAR"
    else
        echo "Unknown"
    fi
}

# ===== 跨平台 timeout =====
# 用法: run_with_timeout 10 some_command arg1 arg2
run_with_timeout() {
    local dur="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$dur" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$dur" "$@"
    else
        local py
        py=$(resolve_python) || { log_error "未找到 Python，无法实现 timeout fallback"; return 1; }
        "$py" -c '
import subprocess, sys
try:
    sys.exit(subprocess.run(sys.argv[2:], timeout=float(sys.argv[1])).returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)
' "$dur" "$@"
    fi
}

# ===== 时间戳 =====
ts_human()   { date "+%Y-%m-%d %H:%M:%S"; }
ts_compact() { date "+%Y%m%d_%H%M%S"; }

# ===== 文件查找 =====
# 在 build/ 中按优先级查找固件：.hex > .bin > .elf
find_firmware() {
    local dir="${1:-$PROJECT_DIR/build}"
    local ext
    for ext in hex bin elf; do
        local f
        for f in "$dir"/*."$ext"; do
            [ -f "$f" ] && echo "$f" && return 0
        done
    done
    return 1
}

# 仅查找 .elf 文件
find_elf() {
    local dir="${1:-$PROJECT_DIR/build}"
    local f
    for f in "$dir"/*.elf; do
        [ -f "$f" ] && echo "$f" && return 0
    done
    return 1
}
