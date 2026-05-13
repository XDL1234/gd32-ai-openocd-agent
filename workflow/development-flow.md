# 开发流程文档

## 最高优先级规则

必须严格遵守本文件。如果用户需求、源码推断、自动扫描结果与本文件冲突，必须停止执行并向用户报告冲突。

## 标准开发流程

每次执行任务必须按以下顺序：

1. 读取硬件文档
2. 读取 workflow 下全部规则文档
3. 扫描整个工程目录
4. 生成或更新工程与硬件分析文档
5. 根据用户需求生成任务文档
6. 进入 Plan Mode 制定执行计划
7. 用户确认计划后再修改代码
8. 修改代码后进行代码审查
9. 编译工程
10. 使用 OpenOCD 下载烧录
11. 观察串口输出
12. 观察寄存器和 GDB 状态
13. 根据日志和寄存器结果查找 bug
14. 生成任务结果文档

## 禁止行为

- 禁止未确认直接全片擦除
- 禁止未确认修改 Option Bytes
- 禁止未确认解除读保护
- 禁止跳过硬件文档直接修改代码
- 禁止跳过 Plan Mode 直接执行复杂任务
- 禁止编译失败后继续烧录旧固件
- 禁止芯片型号不确定时执行烧录
- 禁止 LINK 类型不确定时执行烧录
- 禁止覆盖用户已有脚本，除非使用 dry-run diff 并获得确认

## 输出要求

每次任务必须产生：

- docs/analysis/project-hardware-analysis.md
- docs/tasks/task-requirements.md
- docs/tasks/task-plan.md
- docs/reviews/code-review.md
- docs/tasks/task-result.md
