# 执行器扩展指南：新增自定义 Dispatcher

这份文档说明如何为任意外部工具或服务新增一个 dispatcher skill。

dispatcher skill 是共享的运行时 skill，可以被以下入口复用：

- Claude 的入口 command，例如 `/orchestra-run`
- Codex 的入口 skill，例如 `orchestra-run`

## Dispatcher 命名

- 用户在入口中传入：`--dispatcher <name>`
- 实际的 skill 目录名：`dispatch-<name>`

例如：

- 入口参数：`--dispatcher codex`
- 流程实际加载的 skill：`skills/dispatchers/dispatch-codex/`

## Dispatcher 是做什么的

dispatcher skill 只回答一个问题：如何把 `TASK_PROMPT` 发送给外部执行器，并拿回一个可供 supervisor 验证的 bundle。

dispatcher 不负责：

- 构造 `TASK_PROMPT`
- 验证执行结果
- 处理重试、`MAXED` 或流程恢复

## Dispatcher Contract

一个合规的 dispatcher 必须做到：

1. 接收一个 `TASK_PROMPT` 字符串
2. 用这个 prompt 调用外部工具
3. 产生以下两类结果之一：
   - 在 `tasks.md` 中出现新的 `BUNDLE (RUN #n)` 行
   - 返回明确的失败信号，例如非零退出码
4. 不直接修改 `tasks.md` 的流程状态，除了由 implementer 写入 bundle 行

## 文件结构

```text
skills/dispatchers/dispatch-<name>/
├── SKILL.md
└── agents/
    └── openai.yaml
```

`SKILL.md` 是必需的。`agents/openai.yaml` 是可选的，用来改善它在 Codex 风格界面中的展示效果。

## SKILL.md 模板

```markdown
---
name: dispatch-<name>
description: <Brief description of what tool this dispatches to and when to use it.>
---

# <Name> Dispatcher

## Applicable Scenarios

Use when: <specific conditions>

## Prerequisites

<How to verify the tool is available.>

## Dispatch Steps

1. <Step 1>
2. <Step 2>
...
N. Re-read `tasks.md` directly to verify the BUNDLE line.

## Configuration

所有设置从 `.orchestra/config.json` → `dispatchers.<name>` 读取：

| 设置 | 配置键 | 默认值 |
|------|--------|--------|
| 超时 | `dispatchers.<name>.timeout_seconds` | `300` |
| ... | ... | ... |

## Timeout Handling

<How timeouts are detected and what exit code they produce.>

## Error Handling

<What constitutes CRASH vs SILENT_FAILURE for this tool.>

## Notes

<Any tool-specific quirks the supervisor should know.>
```

## 必填字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | 是 | 必须与目录名匹配 |
| `description` | 是 | 用于 dispatcher 选择界面 |
| `## Dispatch Steps` | 是 | supervisor 的编号步骤 |
| `## Timeout Handling` | 是 | 超时如何判断 |
| `## Error Handling` | 是 | 失败如何归类 |

## 示例：`dispatch-my-tool`

```markdown
---
name: dispatch-my-tool
description: Dispatch tasks to MyTool API for AI-assisted code generation.
---

# MyTool Dispatcher

## Applicable Scenarios

Use when the team has a MyTool API key configured and wants to use MyTool for implementation.

## Prerequisites

Verify the MyTool CLI is available:
```bash
mytool --version
```

Set `MYTOOL_API_KEY` environment variable.

## Dispatch Steps

1. 按 supervisor 的 dispatch protocol 构造 `TASK_PROMPT`
2. 将 prompt 写入 `/tmp/orchestra-prompt.txt`
3. 执行：
   ```bash
   mytool run --prompt-file /tmp/orchestra-prompt.txt --output-mode auto
   ```
4. 记录退出码
5. 清理临时 prompt 文件
6. 重新读取 `tasks.md`，确认 `BUNDLE` 行是否出现

## Configuration

超时时间从 `.orchestra/config.json` → `dispatchers.my-tool.timeout_seconds` 读取（默认：300）。

## Timeout Handling

如果进程超过配置的超时时间，则杀掉它，并将退出码 `137` 视为超时。

## Error Handling

- 退出码 `0` 但没有 bundle 行 → `SILENT_FAILURE`
- 退出码 `1` → `CRASH`
- 退出码 `137` → `TIMEOUT`
```

## 安装自定义 Dispatcher

1. 在 `skills/dispatchers/` 下创建目录
2. 编写 `SKILL.md`
3. 按需补充 `agents/openai.yaml`
4. 在 `templates/config-template.json` 的 `dispatchers.<name>` 下添加默认配置
5. 重新安装到目标项目：

```bash
bash uninstall.sh /path/to/project
bash install.sh /path/to/project
```

5. 使用方式：

```text
在 Claude 中：/orchestra-run my-change --dispatcher my-tool
在 Codex 中：使用 `orchestra-run` skill，并传入 dispatcher `my-tool`
```

## 测试你的 Dispatcher

至少覆盖以下四类测试：

1. 可用性检查
2. 正常路径
3. 超时归类
4. 静默失败识别
