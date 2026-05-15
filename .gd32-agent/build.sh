#!/usr/bin/env bash
# GD32 AI Agent 编译脚本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

LOG_DIR="$AGENT_DIR/logs"
mkdir -p "$LOG_DIR"
BUILD_LOG="$AGENT_DIR/build.log"

banner "GD32 AI Agent 编译"
log_info "编译时间: $(ts_human)"

log_with_ts() {
    bash "$SCRIPT_DIR/log-with-timestamp.sh" "$@" >/dev/null 2>&1 || true
}

# 编译 CMake 工程
build_cmake() {
    log_info "检测到 CMake 工程"
    mkdir -p "$PROJECT_DIR/build"
    pushd "$PROJECT_DIR/build" >/dev/null

    log_step "运行 cmake"
    if ! cmake .. 2>&1 | tee -a "$BUILD_LOG"; then
        log_error "cmake 配置失败"
        log_with_ts build FAIL "cmake 配置失败"
        popd >/dev/null
        exit 1
    fi
    # 检查 pipeline 退出码
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log_error "cmake 配置失败"
        log_with_ts build FAIL "cmake 配置失败"
        popd >/dev/null
        exit 1
    fi

    log_step "运行 make"
    if ! make 2>&1 | tee -a "$BUILD_LOG"; then
        log_error "编译失败"
        log_with_ts build FAIL "编译失败"
        popd >/dev/null
        exit 1
    fi
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log_error "编译失败"
        log_with_ts build FAIL "编译失败"
        popd >/dev/null
        exit 1
    fi

    popd >/dev/null
    log_ok "编译成功"
    log_with_ts build SUCCESS "CMake 工程编译完成"
}

# 编译 Make 工程
build_make() {
    log_info "检测到 Make 工程"
    pushd "$PROJECT_DIR" >/dev/null

    log_step "清理旧文件"
    make clean 2>&1 | tee -a "$BUILD_LOG" || true

    log_step "运行 make"
    if ! make 2>&1 | tee -a "$BUILD_LOG"; then
        log_error "编译失败"
        log_with_ts build FAIL "编译失败"
        popd >/dev/null
        exit 1
    fi
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log_error "编译失败"
        log_with_ts build FAIL "编译失败"
        popd >/dev/null
        exit 1
    fi

    popd >/dev/null
    log_ok "编译成功"
    log_with_ts build SUCCESS "Make 工程编译完成"
}

# 编译 Keil 工程（仅 Windows）
build_keil() {
    log_info "检测到 Keil MDK 工程"
    log_warn "Keil 工程需要手动编译或使用 UV4 命令行工具"
    echo "手动编译命令: UV4 -b project.uvprojx -o build.log"
    log_with_ts warn "Keil 工程需要手动编译"
}

# 编译 IAR 工程
build_iar() {
    log_info "检测到 IAR 工程"
    log_warn "IAR 工程需要手动编译或使用 IarBuild 命令行工具"
    echo "手动编译命令: IarBuild.exe project.ewp -build Debug"
    log_with_ts warn "IAR 工程需要手动编译"
}

main() {
    local project_type
    project_type=$(detect_project_type)
    log_info "工程类型: $project_type"

    case "$project_type" in
        CMake)   build_cmake ;;
        Make)    build_make ;;
        Keil)    build_keil ;;
        IAR)     build_iar ;;
        *)
            log_error "无法识别工程类型"
            echo "支持的工程类型："
            echo "  - CMake (需要 CMakeLists.txt)"
            echo "  - Make (需要 Makefile)"
            echo "  - Keil MDK (需要 .uvprojx 文件)"
            echo "  - IAR (需要 .ewp 文件)"
            log_with_ts build FAIL "无法识别工程类型"
            exit 1
            ;;
    esac

    banner "编译完成"
    log_info "日志文件: $BUILD_LOG"
}

main "$@"
