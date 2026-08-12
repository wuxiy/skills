# CLAUDE.md

Claude Code marketplace plugin: a skills library (`cywu-skills`) by wuxiy. Version: **0.1.0**.

## Architecture

Skills live at the repo root under `skills/<name>/` and are exposed through the single `cywu-skills` plugin defined in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) (plugin metadata, version, and skill paths). This is a **distribution layout** — skills are NOT under `.claude/skills/` here; that path is a project-local install target, not the library layout.

Each skill is self-contained: `SKILL.md` (YAML frontmatter + docs) plus optional `references/`, `scripts/`, `evals/`.

### Skills

| Skill | Purpose |
|-------|---------|
| **cywu-code-refactor** | Post-implementation review + refactor. Two modes: `full` (review a just-finished feature for duplicated logic / design / UI consistency / performance, then refactor) and `cleanup` (re-review a stack of fix patches, consolidate into the optimal solution). Guardrails: behavior preservation, verify every step, small reversible commits. |
| **skill-creator** | Vendored from [anthropics/skills](https://github.com/anthropics/skills) (MIT). Author, modify, evaluate, and benchmark skills. |

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

## Licensing

MIT (see [LICENSE](LICENSE)). Vendored skills keep their own license file alongside them (e.g. `skills/skill-creator/LICENSE.txt`). Contributed code must remain MIT-compatible.
