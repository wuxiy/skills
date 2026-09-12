# nektos/act

**一句话定位**：在本地跑你的 GitHub Actions——"Think globally， act locally"。改 `.github/workflows/` 不用 commit/push，直接用 Docker 容器在本地执行验证。

## 基本信息
- **GitHub**: https://github.com/nektos/act
- **协议**: MIT
- **Star**: 约 72k（老牌权威，长期活跃）
- **技术栈**: Go（Go 1.20+ 可源码构建）
- **官网 / 文档**: https://nektosact.com

## 定位 / 它解决什么
两个核心价值：
1. **Fast Feedback（快速反馈）**：每次改 `.github/workflows/`（或内嵌的 GitHub Actions），不必反复 commit/push 到远端等 CI 跑。`act` 在本地直接跑，且**环境变量和文件系统都按 GitHub 提供的来配置**，行为与线上一致。
2. **Local Task Runner（本地任务执行器）**：如果你嫌 Makefile 重复造轮子，可以用 `.github/workflows/` 里定义的 Actions 替代 Makefile，一套配置本地/CI 通吃。

## 工作原理
`act` 读取 `.github/workflows/` → 通过 Docker API 拉取或构建 workflow 定义的镜像 → 按依赖关系算出执行路径 → 用 Docker 运行每个 action 的容器。环境变量与文件系统都对齐 GitHub runner。

> 依赖 Docker：`act` 需要 Docker Engine API 来跑容器。（若不需要容器隔离，也可把 windows/macOS job 直接跑在宿主机，见 [Runners](https://nektosact.com/usage/runners.html)；目前不官方支持 podman 等替代后端。）

## 安装 / 用法

**一键 curl（预编译二进制）：**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```
**包管理器：**
```bash
brew install act            # macOS / Linux
choco install act           # Windows (Chocolatey)
scoop install act           # Windows (Scoop)
winget install act          # Windows (WinGet)
gh extension install nektos/gh-act   # 或 GitHub CLI 扩展方式(全平台)
```
**源码构建（Go 1.20+）：**
```bash
git clone https://github.com/nektos/act.git && cd act
make build   # 或 go build ...
```

**基本用法（从项目根目录，含 `.github/workflows/`）：**
```bash
act                 # 按默认事件跑所有 workflow
act -l              # 列出可用 job
act -n              # 干跑(dry-run)：不真执行，只打印执行计划
act -j <job-id>     # 只跑指定 job
act push            # 指定事件(如 push)
act pull_request    # 跑 PR 事件
act -W .github/workflows/build.yml   # 指定 workflow 文件
```

## 使用场景
- **本地快速测 workflow**：改 CI 配置后本地先验证，省掉"推远端→等 CI→失败→再改"的漫长循环
- **开发环境复刻 CI**：本地环境变量/文件系统对齐 GitHub runner，行为可信
- **替代 Makefile**：用 `.github/workflows/` 当统一任务执行器，本地和 CI 共用一套
- **CI 行为调试**（与本库 [ai-code-evolution](../vibe-code/experience/ai-code-evolution.md) 的 "GitHub Actions 兜底、别只信一个绿色结果" 呼应）：交付前本地跑通再推，减少"源码对但线上旧文件/CI 黄了"的意外
- 可视化管理：官方推荐 VS Code 扩展 [GitHub Local Actions](https://sanjulaganepola.github.io/github-local-actions-docs/)

## 注意点
- **强依赖 Docker**：绝大多数场景要本机装有 Docker（Desktop/Engine）。不想装 Docker 时，仅限不需要容器隔离的 job 可直接跑宿主机
- 不支持 podman 等容器后端（可能有兼容问题，官方不保证）
- 与远程 GitHub Actions 的行为细节可能略有差异（runner 环境、缓存、secret 注入方式），复杂流水线仍需以线上 CI 为准
- 相比 [agentic-design-patterns](agentic-design-patterns.md)（理论教材）、[teamai-cli](teamai-cli.md)（团队编排），act 是**纯本地 CI 工具**——和实践补足线上 CI 盲区

## 一句话
> act = 给你的 GitHub Actions 一个"本地调试器"：CI 失败不用再推 10 次 commit 去试，在你机器上先跑通再说。