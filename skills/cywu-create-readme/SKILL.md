---
name: cywu-create-readme
description: >-
  This skill should be used when the user asks to 写 README、生成 README、补一个 README、
  完善/更新项目说明、「README 帮我写一下」、「给这个项目写个说明文档」、"create a readme"、
  "draft README.md", "write a readme for this project", "update the README", or when the
  project is missing a README or the existing one is stale, empty, or full of placeholders.
  Produces an appealing, accurate, well-structured README.md by first reading the actual
  codebase, then verifying every command, path and link it claims. Make sure to use this
  skill whenever the user mentions README, even casually like "这项目该有个 README 了".
version: 1.0.0
---

# 撰写 README（Create README）

产出一份**准确、吸引人、好读**的项目 README：先真正读懂项目，再按项目类型选结构，最后逐条验证写下的每一句话。

**核心原则：准确 > 漂亮。** 一份编造了不存在命令的漂亮 README，比没有 README 更糟——它会让第一个照做的人踩坑。所以本技能有一条不可跳过的验证步骤（Step 4）。

## 工作流程

### Step 1: 通读项目，搞清楚它是什么

不要凭目录名猜。按需读这些地方（有哪个读哪个）：

| 找什么 | 去哪看 |
|--------|--------|
| 项目定位、技术栈 | `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `pom.xml` |
| 真实可跑的命令 | 上述文件里的 `scripts`、`Makefile`、`justfile`、`Taskfile`、`compose.yaml` |
| 目录结构与模块划分 | 顶层目录、`src/`、`apps/`、`packages/` |
| 现有说明 | 已有 README、`docs/`、`.env.example`、`CONTRIBUTING.md`、`LICENSE` |
| 对外接口 | `bin`/`main`/`cli`/`server` 入口、公开 API、截图或 demo 资源 |
| 谁在用 | issue/PR 模板、`CHANGELOG`、示例目录 |

读完后你应该能一句话回答：**这个项目解决什么问题、给谁用、怎么跑起来。**

### Step 2: 判定项目类型与读者

README 的结构取决于项目类型——库、CLI、Web 应用、服务和 monorepo 的读者关心的事完全不同。先判定类型（拿不准就问用户），再选骨架。各类型的结构模板、必写区块、常见变体见 [references/structure.md](references/structure.md)（**进入本步骤时读取**）。

读者决定了写作口吻和信息密度：面向使用者的开源库要突出"安装 + 最小可用示例"，面向团队的内部服务要突出"怎么本地起舞 + 部署与配置"。

### Step 3: 起草

按 [references/structure.md](references/structure.md) 的骨架写。行文要求：

- **开头三件套**：标题（有 logo/icon 就放上）→ 一行 tagline（`>` 引用块，说清"这是什么"）→ 徽章（只放真实存在的：npm 版本、CI 状态、许可证）
- **给一个 30 秒上手**：最短的安装 + 运行路径，读者能立刻看到东西跑起来
- **用真实的例子**：命令、输出、截图、代码片段都从项目里来，不编
- 想要更贴语气时，可挑 1–2 篇 [references/inspiration/](references/inspiration/) 里的参考 README 看看——**不要通读全部 4 篇**，挑与项目类型最接近的那篇就够

### Step 4: 自检（强制，不可跳过）

逐条核对，任何一条不过就改到过：

- [ ] **每条命令都真的存在**：出现在 README 里的脚本名/二进制/子命令，能在 `package.json` scripts、`Makefile`、CLI 入口里找到出处
- [ ] **每个路径都真的存在**：引用的文件、目录、示例路径都在仓库里
- [ ] **每个徽章/链接都有效**：仓库地址、包名、许可证类型与项目实际一致；没有许可证文件就不要放 license 徽章
- [ ] **没有占位符残留**：`<your-org>`、`TODO`、`XXX`、`TODO: 补充` 一律不许留下（模板里明确要用户填的除外，且要标清楚）
- [ ] **代码块都标了语言**（```bash / ```ts / ```json …）
- [ ] **不含被排除的章节**（见下）
- [ ] 通读一遍：有没有夸大其词、有没有和实际不符的承诺

## 硬性要求

**不要包含这些章节**——它们各有专门文件，塞进 README 只会稀释信息：

- LICENSE / 许可证正文（有 `LICENSE` 文件即可，最多在末尾一句话提一下）
- CONTRIBUTING（指向 `CONTRIBUTING.md`）
- CHANGELOG（指向 `CHANGELOG.md`）
- 长篇版权/Trademarks 声明

**格式规范**：

- 用 **GFM**，适当用 **GitHub admonition** 承载提示（写法见 references/structure.md）
- **克制 emoji**——标题里顶多一个，正文里别撒
- 表格适合放"命令 ↔ 说明""环境变量 ↔ 默认值"这类对照
- 长文用二级标题分节，别写出 500 行的平坦列表

## 已经存在 README 时

**改进，而不是推倒重来。** 先读懂原 README：作者想强调什么、哪些内容是有意为之（比如特殊的部署流程、内部约定）。保留有价值的部分，只修：过期信息、占位符、缺失的上手路径、混乱的结构。大幅改动前先跟用户说清你打算改哪些、为什么。

如果用户只是让你"补一个 README 章节"，就只补那一节，别顺手重写全文。

## 交付

写完把文件写到项目根的 `README.md`（用户指定了别的路径除外），然后简短汇报：**写了哪些章节、哪些信息是从代码里核实来的、有没有需要用户补充的地方（如项目 logo、截图、真实账号示例）**。不要为了显得完整而编造这些内容——留空并明确告诉用户，比编一个假的强。

## References

- [references/structure.md](references/structure.md) — 各项目类型的结构骨架、必写区块、admonition/徽章写法（Step 2–3 读取）
- [references/inspiration/](references/inspiration/) — 4 篇参考 README（Azure serverless 示例 ×2、sinedied/run-on-output、sinedied/smoke），想对齐语气时挑 1–2 篇参考
