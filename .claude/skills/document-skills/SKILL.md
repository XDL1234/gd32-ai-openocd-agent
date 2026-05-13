---
name: document-skills
description: 读取 PDF、Word、Markdown 文档，转换为标准格式。当用户提供文档或需要分析文档时使用。
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Document Skills

## 功能概述

本 Skill 提供文档处理功能：
- 扫描项目文档
- 读取 PDF、DOCX、MD、TXT 文件
- 转换为 Markdown 格式
- 生成文档索引

## 前置条件

1. 已创建 `docs/imported/` 目录

## 扫描文档

扫描以下目录：
- `hardware/`
- `workflow/`
- `docs/`
- 项目根目录

```bash
find hardware/ workflow/ docs/ -name "*.pdf" -o -name "*.docx" -o -name "*.md" -o -name "*.txt"
```

## 读取文档

### PDF 文档

```bash
python3 -c "
import subprocess
result = subprocess.run(['pdftotext', 'input.pdf', '-'], capture_output=True, text=True)
print(result.stdout)
"
```

### DOCX 文档

```bash
python3 -c "
from docx import Document
doc = Document('input.docx')
for para in doc.paragraphs:
    print(para.text)
"
```

### Markdown 文档

```bash
cat input.md
```

## 转换为 Markdown

将文档内容转换为标准 Markdown 格式：

```markdown
# 文档标题

## 章节 1

内容...

## 章节 2

内容...
```

## 生成文档索引

创建 `docs/imported/document-index.md`：

```markdown
# 文档索引

| 原始文件 | 转换文件 | 类型 | 作用 |
|----------|----------|------|------|
| hardware.md | docs/imported/hardware-doc.md | 硬件文档 | 硬件事实源 |
| development-flow.md | docs/imported/development-flow.normalized.md | 流程文档 | 最高优先级规则 |
```

## 提取关键信息

从文档中提取：
- MCU 型号
- 板卡名称
- 调试器类型
- 串口配置
- 引脚映射
- 时钟树
- 禁止操作

## 输出文件

- `docs/imported/*.md` - 转换后的文档
- `docs/imported/document-index.md` - 文档索引

## 安全规则

- 不修改源代码
- 只读取和转换文档
