# vibe-code 经验与技巧

> 与 `skills/` 平行的内容库：这里沉淀的是 vibe coding（用 AI 写代码）的**可复用 prompt 模板**与**实战经验**。它们不是 agent 技能，不经过插件加载，而是直接可读、可复制到任意会话的文档。

## prompts/ — 可复用 Prompt 模板

| 模板 | 用途 |
|------|------|
| [goal-mode.md](prompts/goal-mode.md) | goal 模式：先确认需求 → 出验收清单 → 开发 → 实际运行逐项验证。做任何"要开发一个项目"的起点。 |
| [deep-thinking.md](prompts/deep-thinking.md) | 深度思考：钢人论证 / 假设检查，让 AI 先问对问题、再给答案。 |
| [refactor-agents.md](prompts/refactor-agents.md) | 按渐进式披露原则重构 AGENTS.md，把大而全的指令拆成根文件 + 分类文件。 |
| [issue-style-task.md](prompts/issue-style-task.md) | 把任务写得像 GitHub Issue：目标 + 范围 + 参考 + 限制 + 验收，用具体上下文让 Codex 稳定执行。 |
| [reckoning-first.md](prompts/reckoning-first.md) | 「先梳理我的意见，理解意图，再设计动工方案」：口喷一大段需求后对齐再用，治 AI 抢跑返工。 |
| [convergence-review.md](prompts/convergence-review.md) | 「多轮修改后的收敛复核」强制规则：治 AI 改 bug 留下临时分支/兜底/死代码的屎山，可写入 AGENTS.md/CLAUDE.md。 |
| [commit-message.md](prompts/commit-message.md) | Commit Message 规范（WHY 化）：大改动补 why Body、极重要的补 Decision 块，可写入 AGENTS.md/CLAUDE.md。 |
| [design-restraint.md](prompts/design-restraint.md) | 设计克制三原则：字重对比（标题粗/正文细淡）、极致留白（1.5x）、90% 中性色+10% 单一强调色。治 AI 界面喧闹粗糙。 |
| [execution-discipline.md](prompts/execution-discipline.md) | 执行纪律：按 PRD 拆单落盘、主 Agent 串行(禁分支/并行)、每条 Codex Review 门禁(最多3遍)、禁止过度设计。 |

## experience/ — 实战经验

| 经验 | 要点 |
|------|------|
| [best-practices.md](experience/best-practices.md) | AI 编码工作流最佳实践：`/better-harness`、业务术语表。 |
| [perceived-performance.md](experience/perceived-performance.md) | 前端"感知性能"10 招：不提高后端性能，也能让体验"变快"。 |
| [ai-ui-styling.md](experience/ai-ui-styling.md) | 让 AI 生成的软件不丑：喂一张配色规范图，让它重配色。 |
| [context-management.md](experience/context-management.md) | 上下文管理：稳定内容前置吃满 prompt cache、长任务压缩上下文、按需加载 MCP、保持配置稳定。 |
| [codex-config.md](experience/codex-config.md) | Codex 5.6 专业设置：固定模型 + Reasoning Effort、任务 Profile、项目级配置、Lifecycle Hooks。 |
| [codex-team-and-iteration.md](experience/codex-team-and-iteration.md) | Codex 团队化协作：持久子代理团队(全局 agents.md)、快速迭代期优先级控制(项目级 agents.md)、侧边聊天不污染主上下文。 |
| [archify.md](experience/archify.md) | 收录第三方 skill：交互式架构/工作流/时序/数据流/生命周期图（tt-a1i/archify）。安装、原始仓库、场景、用法、效果。 |
| [ai-code-evolution.md](experience/ai-code-evolution.md) | AI 时代代码不腐化：架构沉淀、单测覆盖'想当然'坑、Bug 留回归测试+规则、Rules 按模块拆、少加无用功能、GitHub Actions 兜底、流程卡点 AI 自验。 |
| [module-split-by-change.md](experience/module-split-by-change.md) | 模块按'什么会变'分、不按流程分：降低耦合、缩小 AI 改动上下文，判断标准=一个需求只动一个模块。 |
| [git-knowledge-loop.md](experience/git-knowledge-loop.md) | 基于 Git 的知识循环：commit-context(对话+决策写进commit) / distill-module(蒸馏决策史) / map-module(对抗性验证旧代码) + AGENTS.md 渐进式披露。 |
| [ai-reliable-engineering.md](experience/ai-reliable-engineering.md) | AI 可靠系统工程三环：目标对齐(苏格拉底式需求获取) / 路径探索(四维权衡+probe+ADR) / 循迹前行(变更追溯+最小E2E验收)。 |
| [codex-skills-trio.md](experience/codex-skills-trio.md) | Codex 三件套 Skills：planning-with-files(长任务外部记忆) / karpathy-guidelines(约束别乱改) / agent-browser(写完自验网页) + 适用场景与第三方 Skill 避坑。 |
