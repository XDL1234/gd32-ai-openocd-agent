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

# 检查是否在 gd32-agent 仓库目录下运行
if [ "$SCRIPT_DIR" = "$CURRENT_DIR" ]; then
    echo "❌ 请不要在 gd32-agent 仓库目录下运行此脚本"
    echo ""
    echo "正确用法："
    echo "  1. 克隆 gd32-agent 仓库到任意位置"
    echo "  2. 进入你的 GD32 工程目录"
    echo "  3. 运行: bash /path/to/gd32-agent/install.sh"
    exit 1
fi

# 检查是否已经安装
if [ -d ".gd32-agent" ] || [ -d ".claude/skills/gd32-openocd" ]; then
    echo "⚠️ 检测到已存在 GD32 AI Agent 配置"
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
echo "创建目录结构..."
mkdir -p .gd32-agent/logs
mkdir -p hardware
mkdir -p workflow
mkdir -p docs/{imported,analysis,tasks,reviews,bugs,testing}
mkdir -p .claude/commands/gd32-agent
mkdir -p .claude/skills

# 复制 .gd32-agent 脚本
echo "复制 gd32-agent 脚本..."
cp "$SCRIPT_DIR/.gd32-agent/check-env.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/scan-project.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/build.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/flash.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/serial.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/debug.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/log-with-timestamp.sh" .gd32-agent/
cp "$SCRIPT_DIR/.gd32-agent/openocd.cfg" .gd32-agent/

# 复制 Claude 命令
echo "复制 Claude 命令..."
cp "$SCRIPT_DIR/.claude/commands/gd32-agent/init.md" .claude/commands/gd32-agent/

# 复制 Skills
echo "复制 Skills..."
cp -r "$SCRIPT_DIR/.claude/skills/gd32-openocd" .claude/skills/ 2>/dev/null || echo "  gd32-openocd 已存在或不存在"
cp -r "$SCRIPT_DIR/.claude/skills/hardware-analysis" .claude/skills/ 2>/dev/null || echo "  hardware-analysis 已存在或不存在"

# 复制 CLAUDE.md（如果不存在）
if [ ! -f "CLAUDE.md" ]; then
    echo "复制 CLAUDE.md..."
    cp "$SCRIPT_DIR/CLAUDE.md" .
else
    echo "CLAUDE.md 已存在，跳过"
fi

# 设置执行权限
echo "设置执行权限..."
chmod +x .gd32-agent/*.sh

# 复制文档模板
echo "复制文档模板..."
if [ ! -f "docs/bugs/bug-fix-template.md" ]; then
    cp "$SCRIPT_DIR/docs/bugs/bug-fix-template.md" docs/bugs/
fi

if [ ! -f "docs/testing/user-test-template.md" ]; then
    cp "$SCRIPT_DIR/docs/testing/user-test-template.md" docs/testing/
fi

# 复制四文件模板（工作记忆机制）
echo "复制四文件模板..."
if [ ! -f "hardware/硬件资源表.md" ]; then
    cp "$SCRIPT_DIR/templates/硬件资源表.md" hardware/
fi

if [ ! -f "docs/编辑清单.md" ]; then
    cp "$SCRIPT_DIR/templates/编辑清单.md" docs/
fi

if [ ! -f "docs/研究发现.md" ]; then
    cp "$SCRIPT_DIR/templates/研究发现.md" docs/
fi

if [ ! -f "docs/项目规划清单.md" ]; then
    cp "$SCRIPT_DIR/templates/项目规划清单.md" docs/
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
echo ""
echo "已创建的文件："
echo "  - CLAUDE.md                    (Agent 规则)"
echo "  - .gd32-agent/*.sh             (工具脚本)"
echo "  - hardware/硬件资源表.md       (硬件资源记录)"
echo "  - docs/编辑清单.md             (代码修改记录)"
echo "  - docs/研究发现.md             (搜索结果记录)"
echo "  - docs/项目规划清单.md         (项目进度记录)"
echo ""
echo "下一步："
echo "  1. 在 Claude Code 中输入: gd32-agent init"
echo "  2. 或输入: 初始化这个 GD32 工程"
echo ""
echo "=========================================="
