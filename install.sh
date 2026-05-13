#!/bin/bash
# GD32 AI Agent 安装脚本
# 将 gd32-agent 配置文件复制到当前工程目录

echo "=========================================="
echo "GD32 AI Agent 安装"
echo "=========================================="
echo ""

# 获取脚本所在目录（gd32-agent 仓库目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取当前工作目录（用户工程目录）
CURRENT_DIR="$(pwd)"

echo "gd32-agent 仓库: $SCRIPT_DIR"
echo "目标工程目录: $CURRENT_DIR"
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

# 检查是否已经安装
if [ -d ".gd32-agent" ] || [ -d ".claude/skills/gd32-openocd" ]; then
    echo "检测到已存在 GD32 AI Agent 配置"
    read -p "是否覆盖？(y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
fi

echo "开始安装..."
echo ""

# 创建目录结构
echo "[1/8] 创建目录结构..."
mkdir -p .gd32-agent/logs
mkdir -p hardware
mkdir -p workflow
mkdir -p docs/{analysis,tasks,reviews,bugs,testing}
mkdir -p .claude/commands/gd32-agent
mkdir -p .claude/skills

# 复制 .gd32-agent 脚本
echo "[2/8] 复制 gd32-agent 脚本..."
for f in check-env.sh scan-project.sh build.sh flash.sh serial.sh debug.sh \
         log-with-timestamp.sh gen-openocd-cfg.sh verify-hardware.sh openocd.cfg config.env; do
    if [ -f "$SCRIPT_DIR/.gd32-agent/$f" ]; then
        cp "$SCRIPT_DIR/.gd32-agent/$f" .gd32-agent/
    fi
done

# 如果用户已有 config.env 且非首次安装，不覆盖
if [ -f ".gd32-agent/config.env.bak" ]; then
    mv .gd32-agent/config.env.bak .gd32-agent/config.env
fi

# 设置执行权限
chmod +x .gd32-agent/*.sh 2>/dev/null

# 复制 Claude 命令
echo "[3/8] 复制 Claude 命令..."
cp "$SCRIPT_DIR/.claude/commands/gd32-agent/init.md" .claude/commands/gd32-agent/

# 复制 Skills（仅 gd32-openocd 和 hardware-analysis）
echo "[4/8] 复制 Skills..."
cp -r "$SCRIPT_DIR/.claude/skills/gd32-openocd" .claude/skills/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/.claude/skills/hardware-analysis" .claude/skills/ 2>/dev/null || true

# 复制 embedded-dev skill
if [ -d "$SCRIPT_DIR/embedded-dev" ]; then
    echo "[4/8] 复制 embedded-dev skill..."
    cp -r "$SCRIPT_DIR/embedded-dev" . 2>/dev/null || true
fi

# 复制 CLAUDE.md（如果不存在）
echo "[5/8] 复制 CLAUDE.md..."
if [ ! -f "CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" .
else
    echo "  CLAUDE.md 已存在，跳过"
fi

# 复制四文件模板（工作记忆机制）
echo "[6/8] 复制四文件模板..."
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

# 复制多 Agent 工作流程文档
if [ ! -f "docs/multi-agent-workflow.md" ] && [ -f "$SCRIPT_DIR/docs/multi-agent-workflow.md" ]; then
    cp "$SCRIPT_DIR/docs/multi-agent-workflow.md" docs/
fi

# 生成 config.env（自动检测工具路径）
echo "[7/8] 检测工具路径..."
CONFIG_ENV=".gd32-agent/config.env"

# 自动检测 OpenOCD 路径
DETECTED_OPENOCD=""
if command -v openocd &> /dev/null; then
    DETECTED_OPENOCD=$(which openocd)
elif [ "$OS_TYPE" = "Windows" ]; then
    for p in "D:/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe" \
             "C:/openocd/bin/openocd.exe" \
             "$LOCALAPPDATA/xPacks/openocd/xpack-openocd-0.12.0-6/bin/openocd.exe"; do
        if [ -f "$p" ]; then
            DETECTED_OPENOCD="$p"
            break
        fi
    done
fi

if [ -n "$DETECTED_OPENOCD" ]; then
    echo "  检测到 OpenOCD: $DETECTED_OPENOCD"
    sed -i "s|^OPENOCD_PATH=.*|OPENOCD_PATH=\"$DETECTED_OPENOCD\"|" "$CONFIG_ENV" 2>/dev/null || true
fi

# 运行环境检查
echo "[8/8] 运行环境检查..."
if [ -f ".gd32-agent/check-env.sh" ]; then
    bash .gd32-agent/check-env.sh
fi

echo ""
echo "=========================================="
echo "安装完成"
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
echo "已创建的文件："
echo "  - CLAUDE.md                    (Agent 规则)"
echo "  - .gd32-agent/*.sh             (工具脚本)"
echo "  - .gd32-agent/config.env       (配置文件)"
echo "  - hardware/硬件资源表.md       (硬件资源记录)"
echo "  - docs/编辑清单.md             (代码修改记录)"
echo "  - docs/研究发现.md             (搜索结果记录)"
echo "  - docs/项目规划清单.md         (项目进度记录)"
echo "  - docs/multi-agent-workflow.md (多 Agent 工作流程)"
echo ""
echo "下一步："
echo "  1. 编辑 .gd32-agent/config.env 确认工具路径"
echo "  2. 编辑 hardware/hardware.md 填写硬件信息"
echo "  3. 在 Claude Code 中输入: gd32-agent init"
echo ""
echo "=========================================="
