# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`cywu-skills` is a skills library (技能库) for Claude Code. There is no application code, build system, or test suite at the repo root — skills are the product. Check the actual tree before assuming any toolchain conventions.

## Project Skills

Skills live in `.claude/skills/<skill-name>/`, each with a `SKILL.md` (YAML frontmatter: `name`, `description`) plus optional supporting files (`references/`, `scripts/`, `assets/`). Skill names use the `cywu-` prefix by convention.

Installed skills:

- **cywu-code-refactor** (`.claude/skills/cywu-code-refactor/`) — post-implementation review + refactor skill. Two modes: `full` (review the just-finished feature for duplicated logic / design / UI consistency / performance, then refactor) and `cleanup` (re-review a stack of fix patches and consolidate into the optimal solution). Held to three guardrails: behavior preservation, verify every step, small reversible commits. Details in its `references/`.
- **skill-creator** (`.claude/skills/skill-creator/`) — vendored from [anthropics/skills](https://github.com/anthropics/skills) (MIT). Use via the `skill-creator` skill to create, modify, evaluate, and benchmark skills. Its eval/benchmark scripts (`scripts/*.py`, `eval-viewer/generate_review.py`) require Python 3.10+ (Homebrew `python3.14` works; the system `python3` is 3.9 and will fail on `dict | None` annotations).

## Evaluating skills

Each skill that has an `evals/` directory ships test cases and (where needed) fixture projects. Fixtures that contain their own git history are gitignored and must be regenerated:

```bash
bash .claude/skills/<skill>-workspace/setup-fixtures.sh   # e.g. cywu-code-refactor-workspace
```

Eval results (benchmark summaries, grading, reports) under `<skill>-workspace/iteration-N/` are committed as evidence; the bulky refactored project copies under `**/outputs/work/` are gitignored.

## Licensing

MIT license (see LICENSE). Any contributed or vendored skill code must remain MIT-compatible; keep each vendored skill's own LICENSE file alongside it.
