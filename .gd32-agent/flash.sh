#!/usr/bin/env bash
# GD32 烧录脚本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"
load_config

FIRMWARE="${1:-}"
CONFIG="${OPENOCD_CFG:-$AGENT_DIR/openocd.cfg}"

if [ -z "$FIRMWARE" ]; then
    echo "用法: $0 <固件文件>"
    echo "示例: $0 build/app.hex"
    exit 1
fi

[ -f "$FIRMWARE" ] || die "固件文件不存在: $FIRMWARE"

OPENOCD=$(resolve_openocd) || die "未找到 OpenOCD，请在 $AGENT_DIR/config.env 中设置 OPENOCD_PATH"

banner "GD32 烧录"
log_info "OpenOCD: $OPENOCD"
log_info "配置: $CONFIG"
log_info "固件: $FIRMWARE"

if "$OPENOCD" -f "$CONFIG" -c "program $FIRMWARE verify reset exit"; then
    banner "烧录成功"
    bash "$SCRIPT_DIR/log-with-timestamp.sh" flash SUCCESS "$FIRMWARE" >/dev/null 2>&1 || true
else
    banner "烧录失败"
    bash "$SCRIPT_DIR/log-with-timestamp.sh" flash FAIL "$FIRMWARE" >/dev/null 2>&1 || true
    exit 1
fi
