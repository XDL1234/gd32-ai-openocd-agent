#!/bin/bash
# GD32 AI Agent 带时间戳的日志脚本

# 日志目录
LOG_DIR=".gd32-agent/logs"
mkdir -p "$LOG_DIR"

# 日志文件
LOG_FILE="$LOG_DIR/agent-$(date +%Y%m%d).log"

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# 编译日志
log_build() {
    local status=$1
    local details=$2

    if [ "$status" = "SUCCESS" ]; then
        log "BUILD" "编译成功: $details"
    else
        log "BUILD" "编译失败: $details"
    fi
}

# 烧录日志
log_flash() {
    local status=$1
    local details=$2

    if [ "$status" = "SUCCESS" ]; then
        log "FLASH" "烧录成功: $details"
    else
        log "FLASH" "烧录失败: $details"
    fi
}

# 调试日志
log_debug() {
    local status=$1
    local details=$2

    if [ "$status" = "SUCCESS" ]; then
        log "DEBUG" "调试成功: $details"
    else
        log "DEBUG" "调试失败: $details"
    fi
}

# 串口日志
log_serial() {
    local direction=$1
    local data=$2

    log "SERIAL" "[$direction] $data"
}

# 错误日志
log_error() {
    local message=$1
    local details=$2

    log "ERROR" "$message: $details"
}

# 信息日志
log_info() {
    local message=$1

    log "INFO" "$message"
}

# 警告日志
log_warn() {
    local message=$1

    log "WARN" "$message"
}

# 主函数
main() {
    case "$1" in
        "build")
            log_build "$2" "$3"
            ;;
        "flash")
            log_flash "$2" "$3"
            ;;
        "debug")
            log_debug "$2" "$3"
            ;;
        "serial")
            log_serial "$2" "$3"
            ;;
        "error")
            log_error "$2" "$3"
            ;;
        "info")
            log_info "$2"
            ;;
        "warn")
            log_warn "$2"
            ;;
        *)
            echo "用法: $0 {build|flash|debug|serial|error|info|warn} [status] [details]"
            echo ""
            echo "示例:"
            echo "  $0 build SUCCESS \"编译完成\""
            echo "  $0 flash FAIL \"连接失败\""
            echo "  $0 serial TX \"Hello GD32\""
            echo "  $0 info \"开始测试\""
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
