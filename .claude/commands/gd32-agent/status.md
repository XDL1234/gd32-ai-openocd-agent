# GD32 AI Agent 状态查看

## 指令说明

输入 `gd32-agent status` 或 `状态` 查看当前 Agent 配置和工作状态。

## 执行流程

### Step 1: 读取配置

```bash
# 读取 config.env
cat .gd32-agent/config.env 2>/dev/null

# 检查 OpenOCD 配置
cat .gd32-agent/openocd.cfg 2>/dev/null | head -5
```

### Step 2: 读取硬件信息

读取 `hardware/硬件资源表.md`，提取芯片型号、调试器、串口配置。

### Step 3: 检查工程状态

```bash
# 检查最近编译产物
find . -name "*.hex" -o -name "*.bin" -o -name "*.elf" 2>/dev/null | head -3

# 检查工程类型
test -f CMakeLists.txt && echo "CMake" || (test -f Makefile && echo "Make" || echo "未知")
```

### Step 4: 检查任务状态

读取四文件（如果存在），提取当前阶段和进度。

### Step 5: 输出状态报告

以简洁格式展示：

```
🎯 GD32 Agent 状态
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
芯片:     [型号] ([内核], [主频])
调试器:   [类型] ([协议])
串口:     [端口] @ [波特率]
OpenOCD:  [路径] [✓/✗]
工程类型: [CMake/Make/Keil/IAR]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
最近编译: [成功/失败/无记录]
最近烧录: [成功/失败/无记录]
当前任务: [任务描述/无]
当前阶段: [RESEARCH/.../无]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

如果某项信息缺失，显示 `[未配置]` 并提示用户如何配置。
