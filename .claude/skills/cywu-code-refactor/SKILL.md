---
name: cywu-code-refactor
description: >-
  This skill should be used when the user asks to "重构", "优化代码", "review 一下再重构",
  "提升代码质量", "重复逻辑", "设计问题", "UI是否一致", "性能瓶颈", "补丁叠补丁",
  "重构成最优解", "refactor", "code review and refactor", "clean up this code",
  or when the user has just finished implementing a feature or a round of bug fixes and
  wants the implementation re-reviewed for duplicated logic, design problems, UI
  consistency, or performance bottlenecks. Make sure to use this skill whenever the user
  asks to optimize or restructure already-written code, to consolidate messy incremental
  patches into a clean solution, or says things like "以上实现是否考虑了重复逻辑和设计问题"
  or "看看是不是补丁叠补丁式的修改", even if they do not explicitly use the word "refactor".
version: 1.1.0
---

# 代码重构 Review（Code Refactor）

在需求开发完成、或几轮修补把问题解决之后，对实现代码做一次系统性 review + 重构：消除重复逻辑、修正设计问题、统一 UI 表现、排除性能瓶颈，并把"补丁叠补丁"式的修改收敛成一个干净的最优解。

这个技能存在的意义：功能做完时代码往往"能跑但难看"——赶工留下的重复逻辑、临时补丁、不一致的 UI 细节，当场看都合理，攒下来就是技术债。趁上下文还热，做一次有纪律的收敛重构，成本远低于日后回头再改。

## 两种模式

| 模式 | 适用场景 | 典型话术 |
|------|----------|----------|
| **full**（全面 review + 重构） | 需求开发完成后 | "以上实现的代码是否考虑了重复逻辑和设计问题，UI是否一致，是否存在性能瓶颈，请对实现代码进行优化 review 和重构" |
| **cleanup**（补丁收敛重构） | 几轮修改刚把问题解决后 | "现在问题解决了，但请你重新 Review 一下今天的几轮修改，看看是不是补丁叠补丁式的修改，如果是的话，重构成最优解" |

**自动识别**：用户提到"重复逻辑 / 设计问题 / UI 一致 / 性能瓶颈 / 优化 review"→ full；提到"几轮修改 / 补丁 / 刚修完 / 收敛 / 最优解"→ cleanup。两者都沾或都不沾时，用用户输入工具问一次，不要猜。

## User Input Tools

When this skill prompts the user, follow this tool-selection rule (priority order):

1. **Prefer built-in user-input tools** exposed by the current agent runtime — e.g., `AskUserQuestion`, `request_user_input`, `clarify`, `ask_user`, or any equivalent.
2. **Fallback**: if no such tool exists, emit a numbered plain-text message and ask the user to reply with the chosen number/answer for each question.
3. **Batching**: if the tool supports multiple questions per call, combine all applicable questions into a single call; if only single-question, ask them one at a time in priority order.

Concrete `AskUserQuestion` references below are examples — substitute the local equivalent in other runtimes.

## 三条底线

重构的目标是让代码变好，而不是让代码"看起来不同"。所有步骤都受这三条约束：

1. **行为保持** — 除非用户明确要求修 bug 或改行为，重构不改变任何外部可观察行为。想顺手修 bug？单独列出来问用户，不混进重构提交。

   "外部可观察行为"包括但不限于：函数返回值与副作用、命令行输出文本、HTTP 响应、错误文案、以及 UI 上可见的任何字符串与交互。**所以"统一两套不一致的渲染标记（如 `[x]`↔`√`）""改写错误提示措辞""调整日志格式"这类看似只是"整理"的改动，本质上都属于行为变更**——它们会让依赖这些输出的测试或下游消费方失效，也改变用户实际看到的东西。这类一致性发现按下面方式处理：在报告里如实记录（维度：UI 一致性），但**不自动修**，归入"不动的部分"等用户确认；用户确认后单独以行为变更提交，不混进纯重构 commit。判断不准时宁可问。
2. **步步验证** — 每个重构步骤之后都跑验证（测试 / 构建 / 类型检查）。没有验证手段的重构等于盲改，宁可先补最小验证再动手。
3. **小步可退** — 按逻辑单元小步提交，任何一步出问题都能单独回退，不做大爆炸式重写。

## Workflow

### Step 0: 加载项目约定

重构以项目自己的规范为准，不是以通用最佳实践为准。先读：

- 项目 `CLAUDE.md` / `AGENTS.md`、`.claude/rules/`（如存在）——代码风格、文件大小上限、不可变性要求等都在这里
- 现有代码的既有模式（相邻文件怎么组织、命名习惯、错误处理惯例）

后续所有发现和建议都引用项目约定作为依据；项目没约定的地方才用通用最佳实践，并在报告中标注"项目未约定"。

### Step 1: 确定 Review 范围

| 模式 | 范围来源 |
|------|----------|
| full | 优先 `git diff <base>...HEAD`（base 通常是 main/master，用实际存在的分支）圈出本次需求的全部改动；用户指定了文件/模块则以用户为准 |
| cleanup | `git log` + `git diff` 分析最近几轮修复的提交（今天的、或用户提到的几轮），先弄清每个补丁分别修了什么、为什么当时那样修 |

范围过大（约 >20 个文件或 >2000 行 diff）时，先问用户聚焦哪部分——全面但浅的 review 不如聚焦且深。

### Step 2: 多维度 Review

对范围内代码逐维度审查。各维度的具体检查项见 [references/review-checklist.md](references/review-checklist.md)（**进入本步骤时读取它**）：

| 维度 | 核心问题 |
|------|----------|
| 重复逻辑 | 哪些实现在做同一件事？合并后会不会错误耦合？ |
| 设计 | 职责是否清晰？文件大小/函数长度/嵌套是否超标？抽象层是否漏水？ |
| UI 一致性 | 同类控件/状态展示是否与项目既有模式一致？（仅含 UI 的项目） |
| 性能 | 热路径上有无 O(n²)、N+1、无谓重算？（要证据，不猜） |
| 补丁痕迹（仅 cleanup） | 哪些是 workaround？根因是什么？删掉补丁后正确的一次性解法是什么？ |

有子代理能力（Agent 工具）时，各维度并行 review——每个维度一个子代理，返回结构化发现列表，最后汇总去重。

### Step 3: 输出 Review 报告

**ALWAYS use this exact template**，先给用户看报告，确认后再动代码：

```markdown
## 重构 Review 报告

**范围**：<diff 区间 / 文件清单>　**模式**：full / cleanup

### 发现（按优先级）
| # | 维度 | 位置 | 问题 | 影响 | 建议 | 优先级 |
|---|------|------|------|------|------|--------|

### 重构计划（每项对应一个 commit）
1. <做什么 + 为什么>
2. ...

### 不动的部分（及原因）
- ...
```

优先级标准：**P0** 明显重复/设计缺陷/已证实的性能热点/补丁堆叠的根因；**P1** 值得修但收益一般；**P2** 锦上添花。"不动的部分"一节同样重要——明确告诉用户哪些看似可改但刻意不改，避免过度重构。

### Step 4: 确认重构计划

用一次 AskUserQuestion 批量确认：修哪些项（默认 P0+P1）、有无禁区、commit 粒度偏好。用户说"都按你说的来"就直接按默认执行。

### Step 5: 执行重构

具体手法与安全规则见 [references/refactor-playbook.md](references/refactor-playbook.md)（**进入本步骤时读取它**）。要点：

- 动手前确认基线是绿的（测试/构建当前通过）；完全没测试就先对要动的行为补最小验证
- 每个逻辑重构一个 commit（`refactor:` 前缀），每个 commit 后跑验证
- cleanup 模式特有：从需求出发重新推导干净实现，替换整条补丁链，而不是在链上再加一层

### Step 6: 验证与对比

跑完整测试/构建，与基线对比。有行为差异必须能解释（来自用户确认过的项），否则回退排查。

### Step 7: 总结报告

```markdown
## 重构完成

**提交**：<commit 列表，每条一句话说明>
**Before → After**：行数 / 文件数 / 重复块数量 / 其他相关指标
**验证**：<测试/构建结果>
**遗留**：<P2 未修项 + 原因>
```

## Preferences (EXTEND.md)

可选的用户偏好文件，按优先级查找，第一个存在的生效：

| 优先级 | 路径 | 作用域 |
|--------|------|--------|
| 1 | `.cywu-skills/cywu-code-refactor/EXTEND.md` | 项目 |
| 2 | `$HOME/.cywu-skills/cywu-code-refactor/EXTEND.md` | 用户主目录 |

找到则读取并应用（可配置：默认 base 分支、跳过的 review 维度、commit 前缀风格、默认修复优先级阈值等）；未找到则直接用内置默认值继续，不打断用户。

## References

- [references/review-checklist.md](references/review-checklist.md) — 各维度详细检查清单（Step 2 读取）
- [references/refactor-playbook.md](references/refactor-playbook.md) — 重构手法、commit 策略与安全规则（Step 5 读取）

## Extension Support

Custom configurations via EXTEND.md. See **Preferences (EXTEND.md)** section for paths and supported options.
