# cywu-skills

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Claude Code 技能库 + AI 时代工程知识库。可安装的技能、可直接复制的 prompt 与实战经验、值得收藏的第三方仓库索引——都在一个仓库里。

## 这个仓库装了什么

| 目录 | 内容 | 使用方式 |
|------|------|----------|
| [`skills/`](skills/) | 可安装技能（技能包） | 走 plugin 加载，装进 Claude Code 后用 `/` 或自然语言触发 |
| [`vibe-code/`](vibe-code/README.md) | prompt 模板 + 实战经验（11 篇模板 / 12 篇经验） | **纯文档**，直接读、直接复制到任意 AI 会话，不经插件加载 |
| [`ai-repos/`](ai-repos/README.md) | 第三方实用仓库收录（6 个） | 纯文档，每个仓库一篇：定位 / 安装 / 用法 / 效果 / 注意点 |

> [!TIP]
> 只想用文档、不想装插件？`vibe-code/` 和 `ai-repos/` 都是纯 Markdown，复制进任意 AI 会话即可生效，不依赖这个仓库被加载。

## 快速开始

**装整个技能库（推荐）**——在 Claude Code 里：

```text
/plugin marketplace add wuxiy/skills
/plugin install cywu-skills
```

**只装某一个技能**——把 `skills/<skill-name>/` 复制到项目的 `.claude/skills/`，或用户级 `~/.claude/skills/` 即可（技能自包含，可独立分发）。

## 技能

| Skill | 说明 |
|-------|------|
| **cywu-code-refactor** | 需求开发完成后的 review + 重构。两种模式：`full`（审查刚完成功能的重复逻辑 / 设计 / UI 一致性 / 性能后重构）与 `cleanup`（复盘几轮补丁式修改，收敛成最优解）。守住三条底线：行为保持、步步验证、小步可退。 |
| **cywu-create-readme** | 为项目撰写 README：先通读代码库搞清"是什么、怎么跑"，再按项目类型选结构起草，最后逐条核实命令 / 路径 / 徽章真实存在。准确优先于漂亮，输出 GFM + GitHub admonition。 |
| **skill-creator** | 技能创作与评测工具，vendored 自 [anthropics/skills](https://github.com/anthropics/skills)（MIT）。 |

**触发示例**：`重构一下以上实现` · `看看是不是补丁叠补丁式的修改` · `给这个项目写个 README`

## 知识库

### vibe-code/ —— prompt 模板与实战经验

按痛点直达（完整导览见 [vibe-code/README.md](vibe-code/README.md)）：

| 想解决 | 先看 |
|--------|------|
| 需求说不清、AI 抢跑 | goal-mode · reckoning-first · issue-style-task |
| AI 乱改乱加、堆屎山 | execution-discipline · convergence-review |
| 代码腐化、长任务失控 | ai-code-evolution · module-split-by-change · git-knowledge-loop |
| 界面丑、没呼吸感 | design-restraint · ai-ui-styling · perceived-performance |
| 我给 AI 写了功能要验证 | business-testing-rules · playwright-scripted-testing |
| 想建立 Agent 工作哲学 | eight-agent-principles（8 原则，每点可直接粘贴给 Agent） |

- **prompts/**（11 篇）：需求对齐 / 执行纪律 / 设计方向 / 工程规范
- **experience/**（12 篇）：代码质量与架构 / 上下文与知识管理 / 前端体验与设计 / 工作流与 Codex 生态

### ai-repos/ —— 实用仓库收录

收录标准：对 AI 编码工作流有真实增效、解决 AI 时代特有痛点、社区验证度高。已收录 6 个——UI 设计对齐（awesome-design-md）、架构图（archify）、Office 文档自动化（OfficeCLI）、团队 Agent 编排（teamai-cli）、设计模式教材（Agentic-Design-Patterns）、本地 CI（act）。详见 [ai-repos/README.md](ai-repos/README.md)。

## 技能评测

带 `evals/` 的技能附带测试用例与 fixture 项目。需要 git 历史的 fixture 被 gitignore，用脚本再生：

```bash
bash skills/cywu-code-refactor/evals/setup-fixtures.sh
```

`cywu-code-refactor` 首轮评测（2026-08-12，3 个用例）：有技能组断言 **100%** 通过，无技能基线 **94%**。分数差异集中在报告规范，真正的价值在 qualitative 行为差异——无技能基线会越界引入行为变更和新功能，有技能组则把这类改动明确列入"不动的部分（行为变更需确认）"，守住了行为保持底线。详见 [`evals/iteration-1/benchmark.md`](skills/cywu-code-refactor/evals/iteration-1/benchmark.md)。

## 目录结构

```text
cywu-skills/
├── .claude-plugin/marketplace.json   # 插件注册（技能在此登记）
├── docs/creating-skills.md           # 新增技能指南
├── skills/                           # 可安装技能
│   ├── cywu-code-refactor/           # SKILL.md + references/ + evals/
│   ├── cywu-create-readme/           # SKILL.md + references/（结构骨架 + 参考 README）
│   └── skill-creator/                # vendored 创作工具
├── vibe-code/                        # 经验技巧库（README 含场景导览）
│   ├── prompts/                      # 模板与规则：需求对齐 / 执行纪律 / 设计克制 / commit 规范
│   └── experience/                   # 实战：代码质量 / 上下文管理 / 前端体验 / Codex 生态
├── ai-repos/                         # AI 时代实用仓库收录
│   └── repos/                        # 每仓一篇
├── CLAUDE.md
└── README.md
```

## 新增技能

技能必须使用 `cywu-` 前缀（`skill-creator` 为 vendored 例外），并登记到 [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)。完整规范见 [docs/creating-skills.md](docs/creating-skills.md)。

---

MIT，见 [LICENSE](LICENSE)。
