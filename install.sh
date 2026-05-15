#!/bin/bash
# GD32 AI Agent 安装脚本
# 将 gd32-agent 配置文件复制到当前工程目录
# 支持首次安装和增量更新

VERSION="1.1.0"

echo "=========================================="
echo "GD32 AI Agent 安装 v$VERSION"
echo "=========================================="
echo ""

# 获取脚本所在目录（gd32-agent 仓库目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取当前工作目录（用户工程目录）
CURRENT_DIR="$(pwd)"

# 解析命令行参数
MODE="install"
while [[ $# -gt 0 ]]; do
    case $1 in
        --update)
            MODE="update"
            shift
            ;;
        --check)
            MODE="check"
            shift
            ;;
        --force)
            MODE="force"
            shift
            ;;
        --help|-h)
            echo "用法: bash install.sh [选项]"
            echo ""
            echo "选项:"
            echo "  (无参数)   首次安装（已安装则询问覆盖）"
            echo "  --update   增量更新（只更新脚本和协议，保留用户配置）"
            echo "  --check    检查是否有新版本"
            echo "  --force    强制覆盖所有文件（包括用户配置）"
            echo "  --help     显示帮助"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

echo "gd32-agent 仓库: $SCRIPT_DIR"
echo "目标工程目录: $CURRENT_DIR"
echo "安装模式: $MODE"
echo ""

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)   echo "Linux" ;;
        Darwin*)  echo "macOS" ;;
        MINGW*|MSYS*|CYGWIN*) echo "Windows" ;;
        *)        echo "Unknown" ;;
    esac
}

OS_TYPE=$(detect_os)
echo "操作系统: $OS_TYPE"
echo ""

# 检查是否在 gd32-agent 仓库目录下运行
if [ "$SCRIPT_DIR" = "$CURRENT_DIR" ]; then
    echo "错误: 请不要在 gd32-agent 仓库目录下运行此脚本"
    echo ""
    echo "正确用法："
    echo "  1. 克隆 gd32-agent 仓库到任意位置"
    echo "  2. 进入你的 GD32 工程目录"
    echo "  3. 运行: bash /path/to/gd32-agent/install.sh"
    exit 1
fi

# --check 模式：只检查版本
if [ "$MODE" = "check" ]; then
    INSTALLED_VERSION=""
    if [ -f ".gd32-agent/.version" ]; then
        INSTALLED_VERSION=$(cat .gd32-agent/.version)
    fi
    echo "仓库版本: $VERSION"
    if [ -n "$INSTALLED_VERSION" ]; then
        echo "已安装版本: $INSTALLED_VERSION"
        if [ "$INSTALLED_VERSION" = "$VERSION" ]; then
            echo "✅ 已是最新版本"
        else
            echo "⬆️  有新版本可用，运行 'bash $0 --update' 更新"
        fi
    else
        echo "未安装或版本未记录"
        echo "运行 'bash $0' 进行安装"
    fi
    exit 0
fi

# 检查是否已经安装
ALREADY_INSTALLED=false
if [ -d ".gd32-agent" ] || [ -d ".claude/skills/gd32-openocd" ]; then
    ALREADY_INSTALLED=true
fi

if [ "$ALREADY_INSTALLED" = true ] && [ "$MODE" = "install" ]; then
    echo "检测到已存在 GD32 AI Agent 配置"
    echo "提示: 使用 --update 仅更新脚本和协议（保留你的配置）"
    read -p "是否覆盖？(y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
fi

# 用户配置文件列表（--update 模式不覆盖这些文件）
USER_CONFIG_FILES=(
    ".gd32-agent/config.env"
    ".gd32-agent/openocd.cfg"
    "hardware/硬件资源表.md"
    "docs/编辑清单.md"
    "docs/研究发现.md"
    "docs/项目规划清单.md"
    "workflow/development-flow.md"
    "CLAUDE.md"
)

# 判断文件是否为用户配置（--update 时跳过）
is_user_config() {
    local file="$1"
    if [ "$MODE" = "force" ]; then
        return 1  # force 模式不跳过任何文件
    fi
    if [ "$MODE" = "update" ]; then
        for cfg in "${USER_CONFIG_FILES[@]}"; do
            if [ "$file" = "$cfg" ]; then
                return 0  # 是用户配置，跳过
            fi
        done
    fi
    return 1  # 不是用户配置，正常覆盖
}

# 安全复制：update 模式下不覆盖用户配置
safe_copy() {
    local src="$1"
    local dest="$2"
    if [ ! -f "$src" ]; then
        return
    fi
    if is_user_config "$dest" && [ -f "$dest" ]; then
        echo "  [跳过] $dest（用户配置，已存在）"
        return
    fi
    cp "$src" "$dest"
}

echo "开始安装..."
echo ""

# 创建目录结构
echo "[1/9] 创建目录结构..."
mkdir -p .gd32-agent/logs
mkdir -p hardware
mkdir -p workflow
mkdir -p docs/{analysis,tasks,reviews,bugs,testing}
mkdir -p .claude/commands/gd32-agent
mkdir -p .claude/skills

# 复制 .gd32-agent 脚本
echo "[2/9] 复制 gd32-agent 脚本..."
for f in check-env.sh scan-project.sh build.sh flash.sh serial.sh debug.sh \
         debug-loop.sh log-with-timestamp.sh gen-openocd-cfg.sh verify-hardware.sh detect-serial.sh \
         probe-chip.sh gd32-chip-db.sh; do
    if [ -f "$SCRIPT_DIR/.gd32-agent/$f" ]; then
        cp "$SCRIPT_DIR/.gd32-agent/$f" .gd32-agent/
    fi
done

# config.env 和 openocd.cfg 走安全复制
safe_copy "$SCRIPT_DIR/.gd32-agent/config.env" ".gd32-agent/config.env"
safe_copy "$SCRIPT_DIR/.gd32-agent/openocd.cfg" ".gd32-agent/openocd.cfg"

# 设置执行权限
chmod +x .gd32-agent/*.sh 2>/dev/null

# 复制 Claude 命令
echo "[3/9] 复制 Claude 命令..."
for cmd in "$SCRIPT_DIR"/.claude/commands/gd32-agent/*.md; do
    [ -f "$cmd" ] && cp "$cmd" .claude/commands/gd32-agent/
done

# 复制 Skills（gd32-openocd、hardware-analysis、document-skills、superpowers-skills）
echo "[4/9] 复制 Skills..."
cp -r "$SCRIPT_DIR/.claude/skills/gd32-openocd" .claude/skills/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/.claude/skills/hardware-analysis" .claude/skills/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/.claude/skills/document-skills" .claude/skills/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/.claude/skills/superpowers-skills" .claude/skills/ 2>/dev/null || true

# 复制 embedded-dev skill
echo "[5/9] 复制 embedded-dev skill..."
if [ -d "$SCRIPT_DIR/embedded-dev" ]; then
    cp -r "$SCRIPT_DIR/embedded-dev" . 2>/dev/null || true
fi

# 复制 CLAUDE.md
echo "[6/9] 复制 CLAUDE.md..."
safe_copy "$SCRIPT_DIR/CLAUDE.md" "CLAUDE.md"

# 复制四文件模板（仅在文件不存在时）
echo "[7/9] 复制四文件模板..."
for tpl in "hardware/硬件资源表.md:templates/硬件资源表.md" \
           "docs/编辑清单.md:templates/编辑清单.md" \
           "docs/研究发现.md:templates/研究发现.md" \
           "docs/项目规划清单.md:templates/项目规划清单.md"; do
    dest="${tpl%%:*}"
    src="${tpl##*:}"
    if [ ! -f "$dest" ] && [ -f "$SCRIPT_DIR/$src" ]; then
        cp "$SCRIPT_DIR/$src" "$dest"
    fi
done

# 跨平台 sed -i
portable_sed_i() {
    if [[ "$(uname -s)" == Darwin* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# 自动检测工具路径
echo "[8/9] 检测工具路径..."
CONFIG_ENV=".gd32-agent/config.env"

# 仅在 OPENOCD_PATH 为空时自动检测
CURRENT_OPENOCD=$(grep "^OPENOCD_PATH=" "$CONFIG_ENV" 2>/dev/null | cut -d'"' -f2)
if [ -z "$CURRENT_OPENOCD" ]; then
    DETECTED_OPENOCD=""
    if command -v openocd &> /dev/null; then
        DETECTED_OPENOCD=$(which openocd)
    else
        for p in "/usr/bin/openocd" \
                 "/usr/local/bin/openocd" \
                 "/opt/openocd/bin/openocd" \
                 "D:/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe" \
                 "C:/openocd/bin/openocd.exe" \
                 "C:/Program Files/openocd/bin/openocd.exe" \
                 "C:/Program Files (x86)/openocd/bin/openocd.exe" \
                 "$LOCALAPPDATA/xPacks/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe"; do
            if [ -f "$p" ]; then
                DETECTED_OPENOCD="$p"
                break
            fi
        done
    fi

    if [ -n "$DETECTED_OPENOCD" ]; then
        echo "  检测到 OpenOCD: $DETECTED_OPENOCD"
        portable_sed_i "s|^OPENOCD_PATH=.*|OPENOCD_PATH=\"$DETECTED_OPENOCD\"|" "$CONFIG_ENV" 2>/dev/null || true
    fi
fi

# 写入版本号
echo "$VERSION" > .gd32-agent/.version

# 运行环境检查
echo "[9/9] 运行环境检查..."
if [ -f ".gd32-agent/check-env.sh" ]; then
    bash .gd32-agent/check-env.sh
fi

echo ""
echo "=========================================="
if [ "$MODE" = "update" ]; then
    echo "更新完成 (v$VERSION)"
else
    echo "安装完成 (v$VERSION)"
fi
echo "=========================================="
echo ""
echo "已创建的目录："
echo "  - hardware/          (硬件文档)"
echo "  - workflow/          (开发流程)"
echo "  - docs/              (文档目录)"
echo "  - .gd32-agent/       (Agent 脚本)"
echo "  - .claude/           (Claude 配置)"
echo "  - embedded-dev/      (开发协议 Skill)"
echo ""
if [ "$MODE" = "update" ]; then
    echo "已更新: 脚本、命令、Skills、协议"
    echo "已保留: config.env、openocd.cfg、硬件资源表.md 等用户配置"
else
    echo "下一步："
    echo "  1. 在 Claude Code 中输入: gd32-agent init"
    echo "     (初始化向导会自动配置调试器和串口)"
    echo "  2. 或手动编辑 .gd32-agent/config.env 和 hardware/硬件资源表.md"
    echo "  3. 开始开发！"
fi
echo ""
echo "=========================================="
