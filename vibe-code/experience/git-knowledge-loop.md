# 基于 Git 的最小知识循环系统（Git Knowledge Loop）

> 来源：Matthew Lee《基于 Git 的最小知识循环系统》https://mthli.xyz/git-knowledge-loop/（2026-08，经社区发布）。解决 AI 时代人类对项目掌控力下降、模型各自反推逻辑不一致、检索代码库烧 token 的痛点。**无需任何外挂知识库（Obsidian/Notion/飞书），一切知识都活在 `git log` 里，新同事 clone 就能直接干活。**

---

## 核心问题

AI 写的代码变多，三类问题随之而来：

1. **掌控力下降**：项目初期还能把控全局，半年后基本改不动 AI 写的代码
2. **反推不一致**：不同模型上下文窗口/能力不一致，从代码反推出的逻辑对不上
3. **检索烧 token**：没有好的索引，每次 AI 检索代码库都要消耗大量 token

→ 需要一套**上下文管理系统**，既提升 AI 编程效率，也辅助人类理解项目。

## 三个 Skill（Codex 版）

| Skill | 作用 | 产出 |
|-------|------|------|
| `commit-context` | 提交当前 diff，并附上对话上下文 + 决策（Decision） | 写在 **git commit message** 里 |
| `distill-module` | 把 git 里的 Decision 记录**蒸馏**成模块决策史 | `.codex/decisions/<id>.md` |
| `map-module` | 用 **subagent 研究 + 对抗性验证**，核实旧代码逻辑 | `.codex/maps/<id>.md` |

三者通过**模块 ID** 关联起来（`MODULE` 参数字段，ID 中的 `/` 对应子目录）。可在 [mthli.xyz](https://mthli.xyz/git-knowledge-loop/) 取最新版，或让 AI 改成你熟悉的 harness 版本。

## commit-context：把"为什么"写进 commit

对话 + 决策 + 代码 三者齐全，就能还原当时的上下文。运行 `$commit-context`，AI 自动把对话和决策写进 commit message。模板：

```markdown
# Conversation Log
- User:      <关键请求、约束或澄清>
- Assistant: <关键动作或用户可见的结果>

# Decisions
## Decision 1
- MODULE:       <来自 .codex/MODULES.md 的精确 ID>
- WHY:          <一行动机>
- ALTERNATIVES: <考虑过的方案，用 " / " 分隔>
- CHOSEN:       <最终实现的方案>
- TRADEOFFS:    <这个选择放弃了什么>
- RISKS:        <需要盯着的风险>
- SUPERSEDES:   <可选：被替代的决策摘要与 commit hash>

# Files Modified
- <路径> — <该暂存改动的语义描述及其目的>

# Token Usage
- Input/Output/Reasoning/Cache read/Cache creation tokens …
- Total cost + Models used  （作者私心：统计这个需求花了多少钱）
```

> MODULE = 业务模块（相机、选图、首页…）。若新模块不存在，`commit-context` 自动建 ID 并注册进 `.codex/MODULES.md`。不是所有改动都要跑它，大改动才值得记录。

## distill-module：蒸馏成决策史

让 AI 每次检索 git log 效率低，所以在大需求完成或发版本后跑一次，把分散的 Decision 蒸馏成 `.codex/decisions/<id>.md`：

```markdown
# <模块显示名> Decisions
> 当前共识快照。演化过程见：`git log --grep="MODULE: <id>"`
> 最近蒸馏时间：<YYYY-MM-DD>（HEAD = <短 sha>）

## Active
### D1: <改写后的简短标题>
- **What**:      <一句话说明当前采用的做法>
- **Why**:       <一句话说明动机>
- **Tradeoffs**: <一句话说明接受了哪些代价>
- **Watch out**: <一句话说明风险>
- **Source**:    <短 sha 1>, <短 sha 2>

## Superseded
- ~~<旧决策>~~ → 已被 **D1** 取代，见 <短 sha>（<YYYY-MM-DD>）
```

会自动压缩，防止决策文件无限膨胀。

## map-module：研究 + 对抗性验证旧代码

前两套对**新项目**够用；但很多**前 AI 时代的老仓库**需要探索机制。`$map-module` 用 subagent 研究源码 + 「对抗性验证」（借自 Claude Code 的 Dynamic Workflows）核实。产出 `.codex/maps/<id>.md`：

```markdown
# <module-id> Map
> 静态理解快照，不是决策史。配对的决策史见 .codex/decisions/<module-id>.md
> Verified: YYYY-MM-DD（验证摘要）

## Responsibilities / Key types / Public entry points
## Data flow / lifecycle / Dependencies (inbound / outbound)
## Invariants and gotchas / Confirmed bugs / technical debt
## Open questions / To verify
```

> 历史悠久的项目首次运行可能要几小时，推荐下班挂着、第二天验收。可提供外部依赖源码路径，`map-module` 自动探索。

## 循环闭环：AGENTS.md 渐进式披露

AGENTS.md 不必写得又长又重（>200 行会触发 Lost in the Middle，注意力下降）。现代模型指令遵循能力强，只需让它**按需逐级获取上下文**。首次跑 `commit-context` 会自动注入这段约定：

```markdown
## 知识循环约定

### 编写代码之前
1. 通过 .codex/MODULES.md 解析本次改动涉及的每个模块；ID 中的 / 对应子目录。
2. 对每个受影响模块，读取存在的 .codex/maps/<module>.md 与 .codex/decisions/<module>.md。
   不要加载无关模块的文件。
3. 对即将改动的文件运行 git log --oneline -10 -- <path>。
4. 若近期提交含有 MODULE: <当前模块>，用 git show 查看这些提交的正文。

### 完成任务之后
- 若实现改动使现有 module map 失准（职责/入口点/生命周期/数据流/依赖/不变量/局限），
  用 $map-module 定向刷新；否则报告 map 已过期。影响范围无法界定则全量刷新。
  若 map 陈述仍成立，不要改动它。
- 用 $commit-context 时，为每条 Decision 填 MODULE / WHY / ALTERNATIVES / CHOSEN / TRADEOFFS / RISKS。
- 当新 Decision 取代 decisions/ 中某条时，补 SUPERSEDES。
```

**到此循环成立**：写代码前渐进式取上下文 → 写完后 commit 带决策 → 蒸馏成 decisions → 老代码用 maps 核实 → maps/decisions 又反向供给下次修改。

## 生态与边界

- **运行验证**：公司+个人项目跑了半年多，整体健壮；作者私心记录了 API 耗 token（$30000+）
- **可延伸**：基于这套可构建自动化测试——测试同学提的 bug 可直接转给 AI 修；服务端可拉起容器让 agent 在仓库里自跑测试，零额外依赖
- **自知局限**：还没处理"模块拆分"等问题，但都可由 AI 辅助解决

> **一句话**：知识不在外挂文档里，而在 git log 里——commit 保存"为什么"，distill 压缩成决策史，map 核实老逻辑，AGENTS.md 只做渐进式披露的入口。