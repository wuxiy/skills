# Tencent/teamai-cli

**一句话定位**：腾讯开源的"让每个团队 AI 原生"的 CLI——用一个共享 git 仓作为单一事实源，把团队的 skills / rules / hooks / MCP / env / 知识一键分发同步到 Claude Code、Codex、Cursor、CodeBuddy、OpenCode 等所有 Agent。

## 基本信息
- **GitHub**: https://github.com/Tencent/teamai-cli
- **协议**: MIT
- **Star**: 约 2k（腾讯官方，更新活跃）
- **工具链**: TypeScript，npm 全局安装

## 定位 / 它解决什么
团队里每个人都在用不同的 AI Agent（有人 Claude Code、有人 Codex、有人 Cursor），各自的 skills、规则、MCP 配置、团队知识散落各处，改一处要手动同步 N 个工具、N 个成员——这就是"团队不 AI 原生"的痛点。

teamai 的方法是：**团队资源(resources)统一收进一个 git 仓，通过 `init / pull / push` 分发到每个成员的本地 Agent**。管理员改一次推上去，成员下次开 AI 会话自动拉到最新，无需手动同步。

产品架构三层：
- **Team Execution（让每个 Agent 按团队方式干活）**：skills / rules / agents / hooks / MCP / env
- **Team Context（让每个 Agent 理解团队）**：recall、learnings、codebase graph、teamwiki
- **Team Improvement（让每次执行反哺团队）**：friction-based share-learnings、sessions、digest、dashboard

## 安装 / 用法

**安装：**
```bash
npm install -g teamai-cli
```

**团队管理 / 单人：**
```bash
# 先建一个"共享体验仓"（GitHub/GitLab/GitCode/CNB/TGit 或私有），给成员写权限
teamai init https://github.com/yourorg/yourrepo
```
> 没有团队仓？可从 [teamai-hub](https://github.com/teamai-hub) 的模板起步（预置 production-ready skills/rules/review agents），`Use this template` 再 init。

**团队成员（选一种作用域）：**
```bash
# 项目级（默认，装到项目目录下）
cd /path/to/my-project
teamai init https://github.com/yourorg/yourrepo
# 或用户级（装到 ~/ 下）
teamai init https://github.com/yourorg/yourrepo --scope user
```

初始化后，每个 AI 会话启动时（SessionStart hook）自动 `teamai pull` 同步最新资源，无需手动同步。

**日常循环：**
```bash
teamai push   # 改完资源后推送：建分支 + MR，reviewer 通过后合并（重复 push 会原地更新，不重复开 PR）
teamai pull   # 拉最新资源到本地（SessionStart 自动触发）
```
skills 会同步到 `~/.claude/skills/`、`~/.codex/skills/`、`~/.cursor/skills/`、`~/.codebuddy/skills/` 等；项目级安装会先建各工具的项目根（如 `<project>/.claude`）。

**团队 Hook（自定义）：**
```yaml
# hooks/hooks.yaml
hooks:
  - id: block-secret
    description: Scan for secrets before commit
    event: PreToolUse
    matcher: Bash
    command: 'bash -lc "~/.teamai/team-scripts/scan-secret.sh" || true'
    tools: [claude, cursor]
```
```bash
teamai hooks list      # 查看生效的 hooks
teamai hooks inject    # 重新注入到每个已装工具
teamai hooks remove    # 移除所有 teamai 管理的 hooks
```

**团队 MCP：**
```yaml
# mcp/mcp.yaml，一次声明，teamai pull 写入各工具原生配置；${VAR} 放密钥
servers:
  - name: gpu-analysis
    transport: http     # stdio | http | sse
    url: https://example.com/api/mcp
    headers:
      Authorization: Bearer ${GPU_ANALYSIS_TOKEN}
```

**包管理：**
```bash
teamai packages install typescript            # 团队通用依赖
teamai packages install typescript@5.9.2 --npm
```

## 使用场景
- **团队基建统一**：一套 skills/rules/hooks/MCP 分发给全员所有 Agent，消除碎片化
- **开新 Agent 即装即用**：成员换工具/新同事入职，init 一下就同步完团队上下文
- **AI 原生协作**：push/MR 流程让团队资源像代码一样走 review + 版本管理
- **团队知识沉淀**：learnings / teamwiki / share-learnings 反哺日常执行

## 注意点
- **依赖 git 仓作单一事实源**，需要成员对共享仓有写权限；私有/公司网络需确认 git 服务可达
- 与 [archify](archify.md) / [OfficeCLI](officecli.md) 这类单机工具不同，teamai 是**团队级资源编排**——它管"团队的 Agent 配置怎么统一"，不替代具体干活工具
- 与本库 [ai-repos](README.md) 其它条目互补：可作为团队版"skills + rules 的统一 git 分发层"

## 一句话
> teamai 把"团队怎么用 Agent"本身变成了一份可版本化、可 review、可同步的 git 资产——**让团队的默契（skills/rules/知识）像代码一样被管理和演进**。