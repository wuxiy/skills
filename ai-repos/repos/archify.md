# Archify —— 交互式架构图 Agent Skill（收录）

> 把代码库或系统描述，在对话里直接转成**精美的交互式系统图**（HTML/SVG，带流畅动效、清晰导出）。来自第三方项目 `tt-a1i/archify`，这里只做收录，方便检索。**不是你本仓库自研的 skill。**

---

## 原始仓库

- **GitHub**: https://github.com/tt-a1i/archify（MIT 协议，约 23k+ star）
- **项目页 / Proof Lab**: https://tt-a1i.github.io/archify/ · 画廊 https://tt-a1i.github.io/archify/gallery.html
- **定位**: Cursor / Claude Code / Codex CLI / OpenCode 的 Agent skill，Node.js 渲染 + 确定性校验

## 安装方法

推荐一行命令（装到全局，所有项目可用）：

```bash
npx skills add tt-a1i/archify -g
```

各 Agent 的安装落点：

| 平台 | 安装位置 |
|------|---------|
| Claude Code | `~/.claude/skills/` 或 `.claude/skills/` |
| Codex CLI | `~/.agents/skills/` 或 `.agents/skills/` |
| Cursor | 用显式命令：`npx -y skills add tt-a1i/archify --skill archify --agent cursor --global --copy --yes` |
| opencode | `~/.config/opencode/skills/` 等 |
| Raven | 手动解压 `archify.zip` 到 `~/.raven/workspace/skills/` |

**先试不装**：`npx skills use tt-a1i/archify@archify --agent codex`

装完问一句：`Use archify to map this repository's runtime architecture.`

## 使用场景

当你想给系统画"能给非技术人讲清楚的图"时，别再用 Mermaid 挤一坨箭头。适合：

- **架构图**：组件、服务、存储、信任边界（8–12 个核心组件、一条主路径）
- **工作流**：CI/CD、审批、工具调用、Runbook
- **时序图**：API 调用、缓存回退、鉴权、异步链路
- **数据流**：管线、血缘、PII、消费者
- **生命周期**：状态、重试、等待、终止结果
- **PR/设计评审**：Before / Delta / After 三态对比，拿机器校验收据
- **现场演示**：演示模式、导出 PNG/SVG/WebM 与 1200×630 分享图

## 如何使用

**1. 要一个"有边界"的视图**（别让它自由发挥画一屏）：

> Analyze this repository, then use archify to create a high-level runtime architecture diagram.
> Show 8–12 core components, one primary path, external dependencies, and trust boundaries.
> Put supporting detail in cards instead of adding more edges.

**2. 对话里迭代**：`add Redis`、`move auth to the left`、`highlight the rollback path`——它保留类型化的 JSON 源，能精准改单点，不重画整图。

**3. 按图表类型在 prompt 里说清要素**：

| 类型 | 让它在 prompt 里包含 |
|------|---------------------|
| Architecture | 范围、核心组件、主路径 |
| Workflow | 参与者、顺序、分支、异常 |
| Sequence | 调用方、被调用方、返回、时序 |
| Data Flow | 源、转换、存储、边界 |
| Lifecycle | 状态、事件、重试/取消路径 |

**4. 命令行**（零依赖 CLI，装完后在仓库内可直接跑）：

```bash
node archify/bin/archify.mjs doctor                          # 体检
node archify/bin/archify.mjs demo /tmp/archify-demo          # 生成示例
node archify/bin/archify.mjs guide "Kafka topics + replay"   # 选图建议
node archify/bin/archify.mjs deliver workflow xxx.json /tmp/o.html --quality showcase --open --json  # 校验+交付
```

**查看器快捷键**：`/` 搜节点、`R` 追路由、`L` 对比角色、`P` 播放引导故事、`F` 演示模式、`S/T/E` 换风格/主题/导出。

## 使用效果

- **布局有判断力**：智力选择层级、间距、路由、强调，自动端点分散排布，不堆箭头
- **交付前原子校验**：schema、布局、HTML/SVG、路由、标签全部通过才替换产物，失败返回"修复收据"（稳定规则码+可操作修复项）
- **协作可验证**：focus/上下游 reach/精确路由/角色对比都用作者声明的节点关系，不凭空发明拓扑，也不夸大运行时影响
- **一个文件可分享**：自包含 HTML + PNG/SVG/WebM + 分享图，导出不带临时查看器状态

> **一句话**：它不是一个通用绘图编辑器，也不是 Mermaid 换皮——把"技术意图"变成"可沟通的产物"，适合给技术负责人、非技术干系人和评审会讲清架构。