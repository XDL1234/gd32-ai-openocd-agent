# 更新日志

本项目的所有重要更改都将记录在此文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本控制](https://semver.org/lang/zh-CN/)。

## [未发布]

### 变更
- 删除废弃的 `hardware/hardware.md`，统一使用 `hardware/硬件资源表.md`
- 更新 README_EN.md：修复步骤编号重复、硬件配置改为表格格式、补充完整脚本列表和 Skills 表格
- 更新 CONTRIBUTING.md：修复旧仓库名 `gd32-ai-openocd-agent` → `gd32-agent`
- 更新 `docs/user-guide.md`：安装步骤改为 install.sh 方式、硬件配置改为表格格式、补充全部脚本说明
- `install.sh` 补充 `debug-loop.sh` 的复制

## [1.0.0] - 2026-05-13

### 新增
- 初始化指令 `/gd32-ai-agent init`
- 环境检查脚本 `check-env.sh`
- 工程扫描脚本 `scan-project.sh`
- 带时间戳的日志脚本 `log-with-timestamp.sh`
- 烧录脚本 `flash.sh`
- 串口脚本 `serial.sh`
- 调试脚本 `debug.sh`
- OpenOCD 配置文件 `openocd.cfg`
- 硬件文档模板 `hardware/硬件资源表.md`（统一硬件信息入口）
- 开发流程文档 `workflow/development-flow.md`
- 任务需求文档模板 `docs/tasks/task-requirements.md`
- 任务计划文档模板 `docs/tasks/task-plan.md`
- 任务进度文档模板 `docs/tasks/task-progress.md`
- 任务结果文档模板 `docs/tasks/task-result.md`
- 代码审查文档模板 `docs/reviews/code-review.md`
- Bug 修复文档模板 `docs/bugs/bug-fix-template.md`
- 用户测试文档模板 `docs/testing/user-test-template.md`
- 工程分析文档 `docs/analysis/project-hardware-analysis.md`
- 用户指南 `docs/user-guide.md`
- 方案设计文档 `docs/方案设计.md`
- 需求对比分析文档 `docs/需求对比分析.md`
- 任务审查报告 `docs/task-review.md`

### Skills 集成
- document-skills (anthropics/skills)
- superpowers-skills (obra/superpowers)
- find-skills (vercel-labs/skills)
- pua-skills (tanweai/pua)
- gd32-openocd (自定义)
- hardware-analysis (自定义)

### 文档
- README.md (中文)
- README_EN.md (英文)
- LICENSE (MIT)
- CONTRIBUTING.md (贡献指南)
- CHANGELOG.md (更新日志)

## [0.1.0] - 2026-05-13

### 新增
- 项目初始化
- 基础目录结构
- 基础文档模板

---

## 版本说明

### 版本号格式

- **主版本号 (MAJOR)**: 不兼容的 API 修改
- **次版本号 (MINOR)**: 向下兼容的功能性新增
- **修订号 (PATCH)**: 向下兼容的问题修正

### 变更类型

- **新增 (Added)**: 新功能
- **变更 (Changed)**: 对现有功能的变更
- **弃用 (Deprecated)**: 不久将被移除的功能
- **移除 (Removed)**: 已移除的功能
- **修复 (Fixed)**: 任何 Bug 修复
- **安全 (Security)**: 安全相关的更改
