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

仓库除了 skills，还维护 vibe coding 的经验与 prompt 技巧，见 [`vibe-code/`](vibe-code/README.md)：
- **prompts/**：可复用的 prompt 模板（goal 模式、深度思考、重构 AGENTS.md）
- **experience/**：实战经验（前端感知性能 10 招、AI 界面配色、AI 编码工作流最佳实践、Codex 5.6 专业配置）

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

## Licensing

MIT (see [LICENSE](LICENSE)). Vendored skills keep their own license file alongside them (e.g. `skills/skill-creator/LICENSE.txt`). Contributed code must remain MIT-compatible.
