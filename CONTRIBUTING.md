# 贡献指南

感谢你对 GD32 AI Agent 项目的关注！我们欢迎任何形式的贡献。

## 如何贡献

### 报告 Bug

1. 在 [GitHub Issues](https://github.com/XDL1234/gd32-ai-openocd-agent/issues) 创建一个新 Issue
2. 使用 Bug 报告模板
3. 提供详细的复现步骤
4. 附上相关的日志和截图

### 提交功能请求

1. 在 [GitHub Issues](https://github.com/XDL1234/gd32-ai-openocd-agent/issues) 创建一个新 Issue
2. 使用功能请求模板
3. 详细描述你想要的功能
4. 说明使用场景

### 提交代码

1. Fork 项目
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的修改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建一个 Pull Request

## 开发规范

### 代码风格

- Shell 脚本使用 [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Markdown 使用 [Markdownlint](https://github.com/DavidAnson/markdownlint) 规范

### 提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型：**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行的变动）
- `refactor`: 重构（既不是新功能，也不是修改 bug 的代码变动）
- `perf`: 性能优化
- `test`: 增加测试
- `chore`: 构建过程或辅助工具的变动

**示例：**
```
feat(serial): 添加串口模拟触发功能

- 添加 BUTTON_PRESS 命令支持
- 添加 SENSOR_VALUE 命令支持
- 添加自动化测试脚本

Closes #123
```

### 分支规范

- `main`: 主分支，保持稳定
- `develop`: 开发分支
- `feature/*`: 功能分支
- `fix/*`: 修复分支
- `docs/*`: 文档分支

### 测试

提交代码前请确保：

1. 所有脚本都能正常运行
2. 没有语法错误
3. 文档格式正确

## Skills 贡献

如果你想添加新的 Skills：

1. 在 `.claude/skills/` 目录下创建新目录
2. 创建 `SKILL.md` 文件
3. 遵循 [Skills 规范](https://github.com/anthropics/skills/blob/main/spec/SPEC.md)
4. 提交 Pull Request

## 文档贡献

文档贡献同样重要：

1. 修正错别字
2. 改进文档结构
3. 添加使用示例
4. 翻译文档

## 行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们作为贡献者和维护者承诺：

- 尊重所有参与者
- 接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 我们的标准

积极行为包括：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

不可接受的行为包括：

- 使用性暗示的语言或图像
- 恶意评论或人身攻击
- 公开或私下骚扰
- 未经许可发布他人的私人信息

## 联系方式

- GitHub: [XDL1234](https://github.com/XDL1234)
- Issues: [GitHub Issues](https://github.com/XDL1234/gd32-ai-openocd-agent/issues)

## 许可证

通过贡献代码，你同意你的贡献将在 [MIT 许可证](./LICENSE) 下授权。
