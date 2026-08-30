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
