# 架构设计

## 设计理念

Agent-Orchestra 是一套 skills 包，不是流程引擎。它定义三件事：

- 角色该做什么，由 role skills 决定
- 外部工具怎么被调用，由 dispatcher skills 决定
- 不同宿主如何进入流程，由 Claude commands 或 Codex 入口 skills 决定

真正的流程执行和 artifact 状态管理仍然由 OpenSpec 负责。Agent-Orchestra 负责在其之上增加角色边界和编排规则。

## 命名约定

- `openspec-*`：角色 skills
- `dispatch-*`：调度 skills
- `orchestra-*`：宿主入口，在 Claude 中表现为 command，在 Codex 中表现为 skill

## 组件概览

```text
agent-orchestra/
├── skills/
│   ├── roles/          ← 角色 skills
│   ├── dispatchers/    ← 调度 skills
│   └── entrypoints/    ← Codex 入口 skills
├── .orchestra/
│   ├── contracts/      ← 共享 command contract
│   └── config.json     ← 集中运行时配置
├── commands/           ← Claude command 入口
├── schemas/            ← OpenSpec schema 扩展
├── templates/          ← 配置模板
├── install.sh          ← 安装脚本
└── uninstall.sh        ← 卸载脚本
```

宿主入口与运行时 skill 的区别：

- Claude command 决定流程在 Claude 中何时启动，以及接受哪些参数
- Codex 入口 skill 提供同一套流程在 Codex 中的启动方式
- 角色 skill 与调度 skill 决定流程启动后各角色如何执行

## 角色 Skills

每个角色 skill 定义一个角色的行为和权限边界。

| Skill | 角色 | 负责内容 |
|-------|------|---------|
| `openspec-interviewer` | 澄清需求 | `brief.md` |
| `openspec-implementer` | 编写代码 | 产品代码与验证 bundle |
| `openspec-supervisor` | 编排一次任务尝试 | checkbox、evidence、bookkeeping |
| `openspec-verifier` | 执行验证 | Evidence 行 |
| `openspec-committer` | 确认通过 | `feature_list.json` 更新与 checkpoint commit |
| `openspec-researcher` | 解阻失败任务 | `unblock-note.md` |
| `openspec-feature-tracker` | 维护 feature ledger | `feature_list.json` |

关键原则：角色 skills 之间不直接相互调用，而是由 supervisor 统一协调。

## 调度 Skills

每个 dispatcher skill 定义实现任务如何被发送给外部执行器。

| Skill | 工具 | 机制 |
|-------|------|------|
| `dispatch-codex` | Codex CLI | `codex exec --full-auto` |
| `dispatch-subagent` | Claude Code | Agent tool |
| `dispatch-cli` | 通用 CLI | shell 执行 |
| `dispatch-mcp` | MCP 工具 | MCP tool call |
| `dispatch-manual` | 人工 | 手动交接 |

关键原则：dispatcher 只负责委派 implementer 工作，验证始终由 supervisor 负责。

当你传入 `--dispatcher codex` 时，当前入口最终解析到的是 `dispatch-codex` 这个 skill。

## 角色 × 调度器矩阵

角色与调度器是正交组合关系：

```text
implementer × codex       → 由 Codex 写代码
implementer × subagent    → 由 Claude subagent 写代码
implementer × manual      → 由人工写代码

supervisor × (any)        → supervisor 负责协调，dispatcher 决定实现者是谁
```

## 数据流

```text
tasks.md                feature_list.json      progress.txt
    │                          │                    │
    ▼                          ▼                    ▼
[supervisor reads]      [committer writes]    [supervisor/committer appends]
    │
    ├─ [dispatch] → implementer → 在 tasks.md 中写入 BUNDLE
    │
    ├─ [validate] → verifier → 在 tasks.md 中写入 EVIDENCE
    │
    └─ [commit] → committer → 勾选 checkbox、更新 feature、写入 git
```

## 与 OpenSpec 的集成

Agent-Orchestra 是对 OpenSpec 的扩展，而不是替代。

| OpenSpec 提供 | Agent-Orchestra 提供 |
|---------------|----------------------|
| `openspec init` | `install.sh` / `uninstall.sh` |
| `openspec status` | role skills、dispatcher skills 与宿主入口 |
| Artifact DAG | `opsx-supervised` schema 扩展 |
| `/opsx:apply` | `/orchestra-run`、`/orchestra-supervisor`、`orchestra-run`、`orchestra-supervisor` |
| 标准 artifacts | `brief.md`、`feature_list.json`、`progress.txt`、`unblock-note.md` |
| — | `.orchestra/config.json`（集中运行时配置） |

## 审计轨迹

每一次执行都会留下可审计的记录：

```text
tasks.md:
  - [ ] 1.1 Task description [#R1]
    BUNDLE (RUN #1): ...
    EVIDENCE (RUN #1): ... RESULT: PASS

progress.txt:
  [2024-01-01T12:00:00Z] [COMPLETE] [1.1] RUN #1 | RESULT: PASS | ...

feature_list.json:
  [{"ref": "R1", "feature": "...", "passes": true, "evidence": "..."}]
```
