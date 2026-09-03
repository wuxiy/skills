# Codex 三件套 Skills：外部记忆 / 行为约束 / 浏览器验收

> 来源：云析 @yunxi0623《没装这 3 个 Skills，你的 Codex 只用了一半》https://x.com/yunxi0623/status/2095111383490957404（2026-09）
>
> 一句话：模型只是 Coding Agent 的一部分，真正缺的是**任务不跑偏、代码别乱改、结果能自己验证**。三个第三方社区 Skill（非 OpenAI 官方内置）刚好各管一段：

| Skill | 补的能力 | 阶段 |
|-------|---------|------|
| `planning-with-files` | 长任务状态管理（外部工作记忆） | Planning |
| `karpathy-guidelines` | 约束 Coding 行为（别乱扩需求） | Coding |
| `agent-browser` | 写完自己打开真实网页验收 | Browser 验收 |

> ⚠️ 作者强调：没有任何可信 benchmark 支持"装完性能翻倍"，它们补的是能力边界，不是速度。

---

## 01｜agent-browser：写完以后自己开网页验证（Vercel Labs）

浏览器自动化 CLI，官方写明可配合 Claude Code / Codex / Cursor / Gemini CLI / Copilot / OpenCode。能力：打开网页 → 读元素 → 点击 → 填表单 → 截图 → 抓信息 → 复查页面状态。

**核心用法不是"帮我打开 Google"，而是 Web 功能写完后自己做验收**。例：刚写完登录页，直接续：

> 使用 agent-browser 测试 http://localhost:3000/login。分别测试空密码、错误密码和正确账号。检查错误提示、页面跳转和最终登录状态。失败场景保存截图。不要修改测试账号以外的数据。

典型工作流：
```
写代码 → 启动项目 → 打开网页 → 填账号 → 点登录 → 查结果 → 发现问题 → 修改 → 重测
```

操作方式：先 `agent-browser snapshot -i` 拿到交互元素引用（@e1、@e2），再 `agent-browser click @e1` / `agent-browser fill @e2 "hello"`，页面变化后重新 snapshot。

**安装**：
```bash
npm install -g agent-browser
agent-browser install        # 下载 Chrome for Testing
npx skills add vercel-labs/agent-browser   # 给 Agent 装对应 Skill
```

> 点睛：Coding Agent 真正开始好用，不只是因为它能写，而是因为它**开始能够验证自己写的东西**。

## 02｜planning-with-files：给复杂任务装"外部工作记忆"（OthmanAdi）

解决现实问题：任务越长，原始目标越容易被挤出上下文（几十次 Tool Call 后开始重复调查、重踩坑、偏离需求）。

方法朴素但有效：**重要状态别全存在模型上下文里，写到文件**。作者自比：`Context Window = RAM，Filesystem = Disk`。

维护 3 个 Markdown：

| 文件 | 内容 |
|------|------|
| `task_plan.md` | 目标、阶段、下一步 |
| `findings.md` | 调研结果、关键发现、决策 |
| `progress.md` | 做过什么、测试结果、错误记录 |

任务经历长会话 / 上下文压缩 / 重新进入项目后，Agent 先读文件恢复状态即可。

**安装**：
```bash
npx skills add OthmanAdi/planning-with-files --skill planning-with-files -g
```

**使用**：
> 使用 planning-with-files 完成这个任务。先建立任务计划，再开始实现。重要发现写入 findings.md。每完成一个阶段更新 progress.md 和 task_plan.md。

> 与本库 [execution-discipline](prompts/execution-discipline.md)（拆单落盘、续跑以清单为进度真相）是同一思路的 Skill 版，两者可混用。

## 03｜karpathy-guidelines：约束 Coding Agent 别乱写（multica-ai）

**先纠正**：这不是 Karpathy 官方发布的 Skill，而是社区根据他对 LLM Coding 常见问题的公开观察整理的行为指南。专治"让你修按钮，他把整个组件重构了""让你修 Bug，顺手加了好几个抽象层"。

核心四条：
1. **Think Before Coding**：先搞清楚再写。有歧义不偷偷替用户做决定——目标？假设？有没有多种理解？有没有更简单方案？
2. **Simplicity First**：只写解决当前问题需要的代码。50 行能解决，就不要为"未来扩展"提前造 200 行框架。
3. **Surgical Changes**：只改完成任务真正需要改的地方。让你改 `LoginForm.tsx`，不要顺手重构整个 Auth / 换 CSS 架构 / 改十几个变量名 / 加三个辅助类。每一处修改都要能回答"这和当前需求有什么关系？"
4. **Goal-Driven Execution**：把"修复这个 Bug"变成「先复现 → 建立可验证条件 → 修改 → 跑测试 → 确认 Bug 消失 → 确认无回归」。Agent 越明确"什么叫完成"，越不容易写了一堆代码却没解决问题。

**安装**：
```bash
npx skills add https://github.com/multica-ai/andrej-karpathy-skills --skill karpathy-guidelines
```

**使用**：
> 使用 karpathy-guidelines 修复这个 Bug。只修改完成任务必要的文件。不进行顺手重构。不增加没有要求的功能。先复现问题，修改后运行相关测试验证。

> 与本库 [convergence-review](prompts/convergence-review.md)（最终行为最小改动）、[execution-discipline](prompts/execution-discipline.md)（禁止过度设计）高度同源，可互为印证。

## 04｜三个一起用：分阶段闭环

```
需求 → Planning(planning-with-files) → Coding(karpathy-guidelines)
     → Tests → Browser 验收(agent-browser) → 记录结果
```

**组合示例**（加邮箱注册功能）：
> 使用 planning-with-files 和 karpathy-guidelines 完成这个任务。目标：增加邮箱注册。第一阶段只分析项目并建立计划，不写代码。成功标准：正常邮箱能注册；重复邮箱被拒绝；非法邮箱不能提交；注册成功后进入 Dashboard；新增及现有测试全部通过。修改时只动必要文件，不顺手重构。完成后使用 agent-browser 在本地页面实际完成一次正常注册和两个失败案例。最后记录测试结果和遗留问题。

## 05｜不是所有任务都启动三件套

| Skill | 适合 | 不适合 |
|-------|------|--------|
| agent-browser | Web 项目、E2E、表单、后台系统、Browser Automation | — |
| planning-with-files | 复杂研究、3+ 阶段任务、大量 Tool Call、跨长 Session | 改颜色、修错别字、解释函数、写正则 |
| karpathy-guidelines | Debug、老项目维护、局部修改、重构 | 简单任务（它自己提醒：指南倾向谨慎，简单任务别机械套用） |

## 06｜避坑：第三方 Skill 不要无脑安装

OpenAI Skill 规范允许 `SKILL.md` + `scripts/` + `references/` + `assets/`，其中 **scripts 可以是真正可执行的 Python/Bash**。所以第三方 Skill 会真正扩大 Agent 的能力边界，和装普通 Prompt 不是一回事。

安装前至少看：**SKILL.md、scripts/、Hooks、调用了哪些外部工具、会执行什么命令**。尤其带浏览器控制 / 文件修改 / Shell / Hooks / 账号登录 / 外部 API 的，**优先看源码再决定是否长期启用**。

---

> **一句话**：planning-with-files 管"任务不跑偏"，karpathy-guidelines 管"代码别乱改"，agent-browser 管"结果能自己验证"——三者合起来，Codex 才从"代码生成器"变成"能自己验收的交付者"。