# 入门指南

## 命名与入口

`openspec-*` 和 `dispatch-*` 是共享的运行时 skills，`orchestra-*` 是宿主入口。

- `openspec-*`：角色 skills，例如 `openspec-supervisor`、`openspec-implementer`
- `dispatch-*`：调度 skills，例如 `dispatch-codex`、`dispatch-manual`
- 在 Claude 中：`orchestra-*` 是命令入口，例如 `/orchestra-run`、`/orchestra-supervisor`
- 在 Codex 中：`orchestra-*` 是 skill 入口，例如 `orchestra-run`、`orchestra-supervisor`

Claude 和 Codex 可能会在界面里把 skills 和 commands 一起展示。共享的是底层运行时 skills，入口类型则由宿主决定。

## 前置条件

详见 **[前置依赖](prerequisites.md)**，简要说明：

- 已安装 [OpenSpec CLI](https://openspec.dev)，且可在 `PATH` 中使用
- 已安装 Claude Code CLI 和/或 Codex CLI
- 已安装 Node.js + npm（安装脚本会自动注册 MCP 工具）

安装脚本会自动把 `context7` 和 `playwright` MCP 工具注册到 `~/.claude/settings.json`。

## 安装

说明：Agent-Orchestra 依赖 OpenSpec。请先安装 OpenSpec CLI，再把本包安装到目标项目中。

```bash
bash /path/to/agent-orchestra/install.sh /path/to/your/project
```

将安装全部 skills、commands、contracts、schema 和配置文件。

如果已安装，会报错退出。如需重装：

```bash
bash /path/to/agent-orchestra/uninstall.sh /path/to/your/project
bash /path/to/agent-orchestra/install.sh /path/to/your/project
```

## 配置

安装后可编辑 `.orchestra/config.json` 来调整调度器、超时等运行时参数：

```bash
cat /path/to/your/project/.orchestra/config.json
```

详见[配置说明](config-schema.zh.md)。常用配置示例：

```json
{
  "dispatchers": {
    "codex": {
      "timeout_seconds": 900,
      "model": "o3"
    }
  },
  "governance": {
    "max_attempts": 5
  },
  "actions": {
    "auto_commit": true
  }
}
```

## 使用 Codex 全自动执行

```bash
# 1. 安装 skills
bash install.sh ./my-project

# 2. 初始化并创建 change
cd my-project
openspec init

# 3. 自动执行整个 change
# 在 Claude Code 中：
/orchestra-run my-change-001 --dispatcher codex
# 或在 Codex 中：
# 使用 `orchestra-run` skill，并传入 change-id `my-change-001` 与 dispatcher `codex`
```

`--dispatcher codex` 表示 supervisor 会把实现任务交给 `dispatch-codex`，再由它调用 Codex CLI 作为实现者。

## 手动编排

```bash
# 1. 安装 skills
bash install.sh ./my-project

# 2. 在 Codex 中使用 implementer skill
# Codex 完成实现并写入 BUNDLE 行

# 3. 在 Claude 中做验证
/orchestra-supervisor my-change-001 --dispatcher manual --task 1.1
```

手动编排适合你希望把"实现"和"验证"分开控制的场景。

## 工作流步骤

### 第一步：澄清需求

当需求存在歧义时，先使用 interviewer skill：

```text
# 在 Claude Code 中：
让 Claude 使用 openspec-interviewer skill
```

### 第二步：初始化 change

```bash
openspec init
# 在 openspec/changes/<change-id>/ 下创建 change
# 创建带 checkbox 和 [#R1] 样式 ref 的 tasks.md
# 按需生成 feature_list.json
```

### 第三步：执行任务

方案 A：全自动

```text
/orchestra-run my-change --dispatcher codex
# 或在 Codex 中使用 `orchestra-run`
```

方案 B：逐个任务执行

```text
/orchestra-supervisor my-change --dispatcher codex --task 1.1
/orchestra-supervisor my-change --dispatcher codex --task 1.2
# 或在 Codex 中使用 `orchestra-supervisor`
```

方案 C：混合执行

```text
# 由 Codex 通过 openspec-implementer 实现
# 再回到 Claude 中验证：
/orchestra-supervisor my-change --dispatcher manual --task 1.1
```

入口壳与运行时 skill 的关系：

- 在 Claude 中，`/orchestra-run` 和 `/orchestra-supervisor` 是 command 入口壳
- 在 Codex 中，`orchestra-run` 和 `orchestra-supervisor` 是 skill 入口壳
- `openspec-supervisor`、`openspec-implementer`、`dispatch-codex` 是两边共用的底层运行时 skills

### 第四步：查看进度

```bash
openspec status --change my-change
cat openspec/changes/my-change/progress.txt
```

### 第五步：处理失败

如果任务失败：

1. 查看 `tasks.md` 里的 `REVIEW GUIDANCE`
2. 按需触发 `openspec-researcher`
3. 如果任务已经 `MAXED`，查看 `unblock-note.md` 并补充 `UNBLOCK GUIDANCE`
4. 重新运行 supervisor

## Skills 索引

### 角色 Skills

| Skill | When to use | 使用时机 |
|-------|-------------|---------|
| `openspec-interviewer` | Before writing tasks, clarify ambiguous requirements. | 在编写 tasks 之前，用来澄清模糊需求。 |
| `openspec-implementer` | Give this to the coding agent such as Codex or a subagent. | 分配给编码执行者，例如 Codex 或 subagent。 |
| `openspec-supervisor` | Orchestrate one task attempt end to end. | 负责单次 task attempt 的端到端编排。 |
| `openspec-verifier` | Run standalone validation after manual implementation. | 在人工实现后，单独执行验证。 |
| `openspec-committer` | Finalize bookkeeping and commitment after verification passes. | 在验证通过后，负责记账和最终提交。 |
| `openspec-researcher` | Investigate repeated failures and unblock the next attempt. | 在任务反复失败时分析原因并辅助解阻。 |
| `openspec-feature-tracker` | Generate or repair `feature_list.json`. | 用于生成或修复 `feature_list.json`。 |

### 调度 Skills

| Dispatcher | Best for | 适用场景 |
|-----------|---------|---------|
| `dispatch-codex` | Automated Codex execution. | 适合用 Codex 全自动执行实现任务。 |
| `dispatch-subagent` | Claude Code subagent isolation. | 适合通过 Claude Code subagent 隔离执行实现任务。 |
| `dispatch-cli` | Other AI CLI tools such as aider. | 适合接入其他 AI CLI 工具，例如 aider。 |
| `dispatch-mcp` | Custom MCP-based tools. | 适合接入自定义 MCP 工具链。 |
| `dispatch-manual` | Human implementation with AI supervision. | 适合人工实现、AI 负责监督和验收。 |

## 卸载

```bash
bash /path/to/agent-orchestra/uninstall.sh /path/to/your/project
```

只删除安装脚本安装的文件，不会删除 OpenSpec 数据或用户创建的内容。

## 故障排查

- dispatch 后没有 `BUNDLE`：通常是 implementer 没有遵循 contract
- 多次失败后进入 `MAXED`：用 `openspec-researcher` 分析并补充 unblock guidance
- `feature_list.json` 漂移：运行 `openspec-feature-tracker`
- dispatcher 选错：调整 `--dispatcher` 参数
- 超时太短：在 `.orchestra/config.json` 中调整 `dispatchers.<name>.timeout_seconds`
