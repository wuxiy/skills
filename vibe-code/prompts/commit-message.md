# Commit Message 规范（WHY 化）

> 一套可直接写进 `AGENTS.md`（Codex）/ `CLAUDE.md`（Claude Code）的提交信息规范。思路来自[《基于 Git 的最小知识循环系统》](../experience/git-knowledge-loop.md)：提交不只要说"做了什么"，更要补"为什么"。

## 规范原文（复制即用，写进全局/项目规则）

```markdown
### Commit Message 约定
- 类型: feat | fix | chore | refactor | docs | perf | test （沿用现有）
- Subject: 中文动词开头，≤50 字，一句说清"做了什么"。
- Body: 大改动（改架构 / 改抽象 / 有取舍）必须补 WHY，以「why: 」起句讲动机，
  不复述 Subject。小改动（拼写/格式）允许一句到底，不强行加结构。
- Decision 块: 极重要的架构/取舍类提交，补如下字段（不必每项都填）：
    MODULE / WHY / ALTERNATIVES / CHOSEN / TRADEOFFS / RISKS / SUPERSEDES
- 判断标准: git log 铺开扫一眼，只读 Subject 就能懂"这行为什么存在"，即达标。
```

## 完整示例（架构类提交）

```markdown
feat: 收录 Archify 交互式架构图 skill

why: 本项目要持续收录 AI 时代有价值的仓库，为编码工作流沉淀可复用资源，
     避免每次对话都从头解释 Archify 是什么、怎么装。

## Files Modified
- ai-repos/README.md — 新增收录索引
- ai-repos/repos/awesome-design-md.md — 新收录条目

## Decision 1
- MODULE:       ai-repos
- WHY:          给定一个小而清晰的板块，收录成本增量最小
- ALTERNATIVES: 放 skills/ 当插件 / 只贴 README 外链
- CHOSEN:       ai-repos/ 独立板块 + 收录模板（_template.md）
- TRADEOFFS:    不是可加载 skill，需手动复制；换来结构清晰、零维护成本
- RISKS:        条目版本漂移会过时，需周期性刷新
- SUPERSEDES:   无
```

## 轻量示例（日常 feat）

```markdown
feat: 新增「先对齐再动手」提示词经验

why: 之前 AI 口喷需求后直接开工，常漏用户真正在意的点、把次要条件当主线，
     导致返工；加这句强制先对齐再动手。
```

## 与知识循环的关系

- **WHY Body** 是 commit-context 的"穷版"——不建 `.codex/` 结构，也能先把"为什么"留在 git 历史里
- 想上完整的[知识循环](../experience/git-knowledge-loop.md)（decisions / maps / AGENTS.md 渐进式披露）时，从这套约定平滑升级即可