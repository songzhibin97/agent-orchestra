# Agent-Orchestra

一套用于将 agent 角色与执行后端解耦的 OpenSpec 编排包。

## OpenSpec 集成关系

Agent-Orchestra 是构建在 OpenSpec 之上的扩展层。

- OpenSpec 提供 change artifacts、schema 执行能力和流程状态管理
- Agent-Orchestra 提供角色 skills、调度 skills，以及同时面向 Claude 与 Codex 的编排入口
- 这个仓库不是为了替代 OpenSpec，也不会重新实现一套独立流程引擎

## 核心原则

- 只提供 skills 和编排规则，不重复造流程引擎
- artifact DAG 与流程状态依赖 OpenSpec
- 角色与调度器正交组合，可以自由搭配

## 架构

```text
Claude commands / Codex 入口 skills  角色 skills               调度 skills
┌──────────────────────────────┐    ┌──────────────────────┐  ┌───────────────────────┐
│ /orchestra-run               │    │ openspec-interviewer │  │ dispatch-codex        │
│ /orchestra-supervisor        │    │ openspec-implementer │  │ dispatch-subagent     │
│ orchestra-run                │ ─× │ openspec-supervisor  │  │ dispatch-cli          │
│ orchestra-supervisor         │    │ openspec-verifier    │  │ dispatch-mcp          │
└──────────────────────────────┘    │ openspec-researcher  │  │ dispatch-manual       │
                                    │ openspec-feature-    │  └───────────────────────┘
                                    │ tracker              │
                                    │ openspec-committer   │
                                    └──────────────────────┘
```

## 使用方式

### 全自动

```text
/orchestra-run <change-id> --dispatcher codex
```

这会自动推进整个 change 的执行循环。

### 逐步编排

```text
/orchestra-supervisor <change-id> --dispatcher codex --task 1.1
```

这会只执行一次单任务 supervisor attempt。

## 命名与入口

### Skills

- `openspec-*` 是角色 skills，例如 `openspec-supervisor`、`openspec-implementer`
- `dispatch-*` 是调度 skills，例如 `dispatch-codex`、`dispatch-manual`
- 在 Codex 中，`orchestra-run` 和 `orchestra-supervisor` 也会作为入口 skill 安装
- Claude 和 Codex 可能会把 skills 与 commands 一起展示，但它们不是同一种入口

### Commands

- 在 Claude 中，`orchestra-*` 是可直接执行的 command 入口
- `/orchestra-run <change-id> --dispatcher <name>` 会自动执行整个 change，直到完成或遇到终止条件
- `/orchestra-supervisor <change-id> --dispatcher <name> [--task <task-id>]` 只会执行一次单任务 supervisor attempt

### 关系

- Claude command 和 Codex 入口 skill 都只是宿主侧入口壳
- 角色 skill 与调度 skill 才是可复用的运行时行为与边界定义
- 两边入口最终都会读取并遵循同一套底层 skills

## 安装

说明：安装和后续运行都依赖 OpenSpec。在执行 `install.sh` 之前，请先安装好 OpenSpec CLI。

```bash
bash install.sh /path/to/project
```

安装脚本会：

1. 检测 Claude 和 Codex 的宿主环境
2. 复制角色 skills 与 dispatcher skills 到 `.claude/skills/` 和 `.codex/skills/`
3. 为 Codex 安装入口 skills：`orchestra-run` 与 `orchestra-supervisor`
4. 安装共享 command contract 到 `.orchestra/contracts/commands/`
5. 为 Claude 安装 commands：`/orchestra-run` 与 `/orchestra-supervisor`
6. 安装 `opsx-supervised` schema
7. 生成 `.orchestra/config.json` 默认配置
8. 写入 `.orchestra/manifest.json` 供卸载使用

如果已经安装过，安装脚本会报错退出。请先执行 `uninstall.sh` 卸载。

## 卸载

```bash
bash uninstall.sh /path/to/project
```

只删除安装脚本安装的文件，不会删除 OpenSpec 数据或用户创建的文件。

## 配置

所有运行时配置集中在 `.orchestra/config.json`。详见[配置说明](docs/config-schema.zh.md)。

可配置项包括：
- 调度器配置：命令、超时、模型、prompt 传递方式
- 治理策略：最大重试次数、最大研究源数量
- 动作开关：自动提交
- Bundle：基础路径、文件夹命名、必需文件
- 验证：GUI 工具选择

## 目录结构

```text
agent-orchestra/
├── schemas/opsx-supervised/     # OpenSpec schema 扩展
├── skills/
│   ├── roles/                   # 角色 skills
│   ├── dispatchers/             # 调度 skills
│   └── entrypoints/             # Codex 入口 skills
├── contracts/commands/          # 共享 command contract
├── templates/                   # 配置模板
├── commands/                    # Claude command 入口
├── docs/                        # 用户文档
├── install.sh                   # 安装脚本
└── uninstall.sh                 # 卸载脚本
```

## 文档

- [入门指南](docs/getting-started.zh.md)
- [架构设计](docs/architecture.zh.md)
- [配置说明](docs/config-schema.zh.md)
- [执行器扩展指南](docs/executor-guide.zh.md)

## 依赖

- [OpenSpec CLI](https://openspec.dev)
- Claude CLI 和/或 Codex CLI
