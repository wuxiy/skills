# cywu-skills

Claude Code 技能库 / A skills library for [Claude Code](https://claude.ai/code).

## 包含的技能 / Included Skills

| Skill | 说明 |
|-------|------|
| **cywu-code-refactor** | 需求开发完成后的 review + 重构。两种模式：`full`（审查刚完成功能的重复逻辑 / 设计 / UI 一致性 / 性能后重构）与 `cleanup`（复盘几轮补丁式修改，收敛成最优解）。守住三条底线：行为保持、步步验证、小步可退。 |
| **skill-creator** | 技能创作与评测工具，vendored 自 [anthropics/skills](https://github.com/anthropics/skills)（MIT）。 |

## 安装 / Install

**方式一：作为插件安装整个技能库**（推荐）

在 Claude Code 中：

```
/plugin marketplace add wuxiy/cywu-skills
/plugin install cywu-skills
```

**方式二：单独安装某个技能**

把 `skills/<skill-name>/` 目录复制到你的项目 `.claude/skills/` 或用户级 `~/.claude/skills/` 即可。

## 评测技能 / Evaluating Skills

带 `evals/` 的技能附带测试用例和 fixture 项目。需要 git 历史的 fixture 被忽略，用脚本再生：

```bash
bash skills/cywu-code-refactor/evals/setup-fixtures.sh
```

`cywu-code-refactor` 的首轮评测：有技能组断言 100% 通过 vs 无技能基线 94%，价值集中在行为保持纪律。详见 `skills/cywu-code-refactor/evals/iteration-1/benchmark.md`。

## Vibe Code 经验与技巧 / Vibe Code Knowledge

仓库还沉淀 vibe coding 的经验与 prompt 技巧，见 [vibe-code/](vibe-code/README.md)：

- **prompts/**：可复用的 prompt 模板 —— goal 模式（验收清单驱动开发）、深度思考、重构 AGENTS.md
- **experience/**：实战经验 —— 前端"感知性能"10 招、AI 界面配色、AI 编码工作流最佳实践、Codex 5.6 专业配置

这些是直接可读、可复制的文档，不经过插件加载。

## AI 时代实用仓库收录 / AI-Era Repo Index

收录经过验证、值得收藏的第三方 GitHub 仓库（定位 / 用法 / 效果 / 注意点），见 [ai-repos/](ai-repos/README.md)。

## 目录结构 / Structure

```
cywu-skills/
├── .claude-plugin/marketplace.json   # 插件注册
├── docs/creating-skills.md           # 新增技能指南
├── skills/
│   ├── cywu-code-refactor/           # SKILL.md + references/ + evals/
│   └── skill-creator/                # vendored 创作工具
├── vibe-code/                        # 经验技巧库：prompts/ 模板 + experience/ 实战
│   ├── prompts/                      # goal-mode / deep-thinking / refactor-agents
│   └── experience/                   # perceived-performance / ai-ui-styling / best-practices
├── ai-repos/                         # AI 时代实用仓库收录（索引 + 每仓一篇）
├── CLAUDE.md
└── README.md
```

新增技能约定用 `cywu-` 前缀，完整规范见 [docs/creating-skills.md](docs/creating-skills.md)。

## License

MIT
