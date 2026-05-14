#!/bin/bash
# GD32 AI Agent 编译脚本

# 日志目录
LOG_DIR=".gd32-agent/logs"
mkdir -p "$LOG_DIR"

# 日志文件
BUILD_LOG=".gd32-agent/build.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "=========================================="
echo "GD32 AI Agent 编译"
echo "=========================================="
echo ""
echo "编译时间: $TIMESTAMP"
echo ""

# 检测工程类型
detect_project_type() {
    if [ -f "CMakeLists.txt" ]; then
        echo "CMake"
    elif [ -f "Makefile" ]; then
        echo "Make"
    elif ls *.uvprojx 2>/dev/null | head -1 | grep -q .; then
        echo "Keil"
    elif ls *.ewp 2>/dev/null | head -1 | grep -q .; then
        echo "IAR"
    else
        echo "Unknown"
    fi
}

# 编译 CMake 工程
build_cmake() {
    echo "检测到 CMake 工程"
    echo ""

    # 创建 build 目录
    mkdir -p build
    cd build || exit 1

    # 运行 cmake
    echo "运行 cmake..."
    if ! cmake .. 2>&1 | tee -a "../$BUILD_LOG"; then
        echo ""
        echo "❌ cmake 配置失败"
        bash ../.gd32-agent/log-with-timestamp.sh build FAIL "cmake 配置失败"
        exit 1
    fi

    # 运行 make
    echo ""
    echo "运行 make..."
    if ! make 2>&1 | tee -a "../$BUILD_LOG"; then
        echo ""
        echo "❌ 编译失败"
        bash ../.gd32-agent/log-with-timestamp.sh build FAIL "编译失败"
        exit 1
    fi

    cd ..
    echo ""
    echo "✅ 编译成功"
    bash .gd32-agent/log-with-timestamp.sh build SUCCESS "CMake 工程编译完成"
}

# 编译 Make 工程
build_make() {
    echo "检测到 Make 工程"
    echo ""

    # 清理
    echo "清理旧文件..."
    make clean 2>&1 | tee -a "$BUILD_LOG"

    # 编译
    echo "运行 make..."
    if ! make 2>&1 | tee -a "$BUILD_LOG"; then
        echo ""
        echo "❌ 编译失败"
        bash .gd32-agent/log-with-timestamp.sh build FAIL "编译失败"
        exit 1
    fi

    echo ""
    echo "✅ 编译成功"
    bash .gd32-agent/log-with-timestamp.sh build SUCCESS "Make 工程编译完成"
}

# 编译 Keil 工程
build_keil() {
    echo "检测到 Keil MDK 工程"
    echo ""
    echo "⚠️ Keil 工程需要手动编译或使用 UV4 命令行工具"
    echo ""
    echo "手动编译命令："
    echo "  UV4 -b project.uvprojx -o build.log"
    echo ""
    bash .gd32-agent/log-with-timestamp.sh warn "Keil 工程需要手动编译"
}

# 编译 IAR 工程
build_iar() {
    echo "检测到 IAR 工程"
    echo ""
    echo "⚠️ IAR 工程需要手动编译或使用 IarBuild 命令行工具"
    echo ""
    echo "手动编译命令："
    echo "  IarBuild.exe project.ewp -build Debug"
    echo ""
    bash .gd32-agent/log-with-timestamp.sh warn "IAR 工程需要手动编译"
}

# 主函数
main() {
    # 检测工程类型
    PROJECT_TYPE=$(detect_project_type)
    echo "工程类型: $PROJECT_TYPE"
    echo ""

    # 根据工程类型编译
    case "$PROJECT_TYPE" in
        "CMake")
            build_cmake
            ;;
        "Make")
            build_make
            ;;
        "Keil")
            build_keil
            ;;
        "IAR")
            build_iar
            ;;
        *)
            echo "❌ 无法识别工程类型"
            echo ""
            echo "支持的工程类型："
            echo "  - CMake (需要 CMakeLists.txt)"
            echo "  - Make (需要 Makefile)"
            echo "  - Keil MDK (需要 .uvprojx 文件)"
            echo "  - IAR (需要 .ewp 文件)"
            bash .gd32-agent/log-with-timestamp.sh build FAIL "无法识别工程类型"
            exit 1
            ;;
    esac

    echo ""
    echo "=========================================="
    echo "编译完成"
    echo "=========================================="
    echo ""
    echo "日志文件: $BUILD_LOG"
}

# 执行主函数
main "$@"
