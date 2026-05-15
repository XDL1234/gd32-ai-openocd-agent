#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Session Start Hook - GD32 嵌入式工程上下文注入

注入内容：
- <current-state>: git 分支/状态/近期 commit + 硬件资源表/config.env 状态
- <ready>: 简短的会话启动提示

设计原则：
- 不依赖任何外部框架（如 Trellis）
- 注入内容轻量，避免上下文窗口浪费
- 失败时降级为最小注入而不是崩溃
"""

import warnings
warnings.filterwarnings("ignore")

import json
import os
import subprocess
import sys
from io import StringIO
from pathlib import Path

# 强制 Windows stdout 使用 UTF-8
if sys.platform == "win32":
    import io as _io
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[union-attr]
    elif hasattr(sys.stdout, "detach"):
        sys.stdout = _io.TextIOWrapper(sys.stdout.detach(), encoding="utf-8", errors="replace")  # type: ignore[union-attr]


def should_skip_injection() -> bool:
    return (
        os.environ.get("CLAUDE_NON_INTERACTIVE") == "1"
        or os.environ.get("OPENCODE_NON_INTERACTIVE") == "1"
    )


def _git(cmd: list, cwd: Path) -> str:
    try:
        result = subprocess.run(
            ["git"] + cmd,
            capture_output=True, text=True,
            encoding="utf-8", errors="replace",
            timeout=3, cwd=str(cwd),
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except (subprocess.TimeoutExpired, FileNotFoundError, PermissionError):
        return ""


def collect_git_status(project_dir: Path) -> list:
    lines = []
    branch = _git(["branch", "--show-current"], project_dir) or "(detached)"
    status = _git(["status", "--porcelain"], project_dir)
    if status:
        change_count = len(status.splitlines())
        working = f"{change_count} uncommitted change(s)"
    else:
        working = "Clean"
    log = _git(["log", "--oneline", "-5"], project_dir)

    lines.append("## GIT STATUS")
    lines.append(f"Branch: {branch}")
    lines.append(f"Working directory: {working}")
    lines.append("")
    lines.append("## RECENT COMMITS")
    lines.append(log if log else "(no commits)")
    return lines


def collect_hardware_status(project_dir: Path) -> list:
    lines = ["## HARDWARE"]
    hw_path = project_dir / "hardware" / "硬件资源表.md"
    if not hw_path.is_file():
        lines.append("(硬件资源表未生成，可运行: bash .gd32-agent/scan-project.sh 或 init)")
        return lines

    try:
        content = hw_path.read_text(encoding="utf-8")
        # 提取芯片型号、系列、调试器关键信息
        key_lines = []
        for line in content.splitlines():
            stripped = line.strip()
            for keyword in ("芯片型号", "芯片系列", "LINK 类型", "串口号", "波特率"):
                if keyword in stripped and "|" in stripped:
                    key_lines.append(stripped)
                    break
            if len(key_lines) >= 5:
                break
        if key_lines:
            lines.extend(key_lines)
        else:
            lines.append("(硬件资源表存在但未填写关键字段)")
    except (OSError, UnicodeDecodeError):
        lines.append("(硬件资源表读取失败)")
    return lines


def collect_config_status(project_dir: Path) -> list:
    lines = ["## CONFIG"]
    cfg_path = project_dir / ".gd32-agent" / "config.env"
    if not cfg_path.is_file():
        lines.append("(.gd32-agent/config.env 未配置)")
        return lines

    try:
        for line in cfg_path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped and not stripped.startswith("#"):
                lines.append(stripped)
    except (OSError, UnicodeDecodeError):
        lines.append("(config.env 读取失败)")
    return lines


def main():
    if should_skip_injection():
        sys.exit(0)

    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", ".")).resolve()
    output = StringIO()

    output.write("<session-context>\n")
    output.write("GD32 嵌入式开发工程会话启动。\n")
    output.write("请遵循 CLAUDE.md 中的安全红线和 embedded-dev/SKILL.md 的 RIPER-5 协议。\n")
    output.write("</session-context>\n\n")

    output.write("<current-state>\n")
    output.write("=" * 40 + "\n")
    output.write("SESSION CONTEXT\n")
    output.write("=" * 40 + "\n\n")

    for line in collect_git_status(project_dir):
        output.write(line + "\n")
    output.write("\n")

    for line in collect_hardware_status(project_dir):
        output.write(line + "\n")
    output.write("\n")

    for line in collect_config_status(project_dir):
        output.write(line + "\n")
    output.write("\n")

    output.write("=" * 40 + "\n")
    output.write("</current-state>\n\n")

    output.write(
        "<ready>\n"
        "Context loaded. Project state injected above — do NOT re-read it.\n"
        "Wait for the user's first message, then handle it per CLAUDE.md and embedded-dev/SKILL.md.\n"
        "</ready>"
    )

    result = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": output.getvalue(),
        }
    }
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
