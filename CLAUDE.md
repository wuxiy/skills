# CLAUDE.md

Claude Code marketplace plugin: a skills library plus vibe-code knowledge (`cywu-skills`) by wuxiy. Version: **0.1.0**.

## Architecture

Skills live at the repo root under `skills/<name>/` and are exposed through the single `cywu-skills` plugin defined in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) (plugin metadata, version, and skill paths). This is a **distribution layout** — skills are NOT under `.claude/skills/` here; that path is a project-local install target, not the library layout.

Each skill is self-contained: `SKILL.md` (YAML frontmatter + docs) plus optional `references/`, `scripts/`, `evals/`.

### Skills

| Skill | Purpose |
|-------|---------|
| **cywu-code-refactor** | Post-implementation review + refactor. Two modes: `full` (review a just-finished feature for duplicated logic / design / UI consistency / performance, then refactor) and `cleanup` (re-review a stack of fix patches, consolidate into the optimal solution). Guardrails: behavior preservation, verify every step, small reversible commits. |
| **skill-creator** | Vendored from [anthropics/skills](https://github.com/anthropics/skills) (MIT). Author, modify, evaluate, and benchmark skills. |

## Vibe Code 经验与技巧

仓库除了 skills，还维护 vibe coding 的经验与 prompt 技巧，见 [`vibe-code/`](vibe-code/README.md)（含"场景导览"快速入口）：
- **prompts/**：可复用的 prompt 模板与规则（需求对齐、执行纪律、设计克制、commit 规范）
- **experience/**：实战经验（代码不腐化、模块划分、上下文管理、Git 知识循环、AI 可靠工程、Codex 三件套 Skills）

另维护第三方仓库收录 [ai-repos/](ai-repos/README.md)（每仓一篇：定位 / 安装 / 用法 / 效果 / 注意点）。

这些是直接可读、可复制的文档，**不经过插件加载**，也不受"技能自包含"约束（可自由链接 `vibe-code/` 内部文件）。

## Skill Loading

Install the whole library as a plugin, or copy a single skill into a project's `.claude/skills/` or `~/.claude/skills/`. See [README.md](README.md).

## Skill Self-Containment

Each skill under `skills/` is distributed and consumed independently — the folder may be extracted, copied into another project, or loaded without the rest of this repo. Therefore:

- **Never link from `SKILL.md` or its `references/` to files outside the skill's own directory.** This includes `docs/`, sibling skills, and the repo root. Relative paths like `../../docs/foo.md` break when the skill is used standalone.
- **Inline any shared convention** directly in the skill rather than referencing an out-of-skill doc.
- Docs under `docs/` are for **repo-author guidance only** — reference them from `CLAUDE.md` and `docs/creating-skills.md`, NOT from any `SKILL.md`.

## Evaluating Skills

Skills with an `evals/` directory ship test cases and fixture projects. Fixtures that contain their own git history are gitignored and must be regenerated:

```bash
bash skills/<skill>/evals/setup-fixtures.sh   # e.g. skills/cywu-code-refactor/evals
```

Eval evidence (benchmark summaries, grading, reports) under `evals/iteration-N/` is committed; the bulky refactored project copies under `**/outputs/work/` and regenerated `fixtures/` are gitignored.

## Adding New Skills

All skills MUST use the `cywu-` prefix. Full guide: [docs/creating-skills.md](docs/creating-skills.md).

## Reference Docs

| Topic | File |
|-------|------|
| Creating / structuring a new skill | [docs/creating-skills.md](docs/creating-skills.md) |
| Vibe-code 经验与技巧索引 | [vibe-code/README.md](vibe-code/README.md) |

## Commit Message 约定

本仓库提交遵循「WHY 化」规范（详见 [vibe-code/prompts/commit-message.md](vibe-code/prompts/commit-message.md)）：

- **类型**: `feat` / `fix` / `chore` / `refactor` / `docs` / `perf` / `test`
- **Subject**: 中文动词开头，≤50 字，一句说清"做了什么"。
- **Body**: 大改动（改架构 / 改抽象 / 有取舍）必须补 WHY，用 `why: ` 起句讲动机，
  不复述 Subject。小改动（拼写/格式）允许一句到底，不强行加结构。
- **Decision 块**: 极重要的架构 / 取舍类提交，补（不必每项都填）：
  `MODULE / WHY / ALTERNATIVES / CHOSEN / TRADEOFFS / RISKS / SUPERSEDES`
- **判断标准**: `git log` 铺开扫一眼，只读 Subject 就能懂"这行为什么存在"，即达标。

---

## Licensing

MIT (see [LICENSE](LICENSE)). Vendored skills keep their own license file alongside them (e.g. `skills/skill-creator/LICENSE.txt`). Contributed code must remain MIT-compatible.
