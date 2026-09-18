# README 结构指南

按项目类型选骨架，不要所有项目套同一个模板。

## 目录

- [通用骨架](#通用骨架)
- [按项目类型](#按项目类型)
  - [库 / 包](#库--包)
  - [CLI 工具](#cli-工具)
  - [Web 应用](#web-应用)
  - [后端服务 / API](#后端服务--api)
  - [Monorepo](#monorepo)
- [常用区块写法](#常用区块写法)
- [Admonition 与徽章](#admonition-与徽章)
- [常见反例](#常见反例)

## 通用骨架

几乎所有 README 都该有的最小骨架：

```markdown
# 项目名
<a href="..." ><img src="logo" width="120"/></a>      <!-- 有 logo 才放 -->

[徽章行：版本 / CI / 许可证]

> 一句话说清这是什么、给谁用。                             <!-- tagline -->

[可选：demo GIF / 截图 —— 视觉比文字快 10 倍]

## Features / 特性            ← 3–6 条，说"能干什么"，别说"用到了什么技术"

## Getting started / 快速开始
### Prerequisites / 前置要求
### Installation / 安装
### Quick start / 最小可用示例   ← 30 秒能跑起来

## Usage / 用法                ← 主要场景，每个配一个代码块

## Configuration / 配置        ← 环境变量用表格：变量 | 说明 | 默认值

## Troubleshooting / 常见问题   ← 可选，但很有用

## License                    ← 一句话 + 链接，不抄正文
```

**顺序原则**：越"我想让读者立刻动手"的内容越靠前。读者从上往下读，前三屏决定他走不走。

## 按项目类型

### 库 / 包

读者关心：**装什么、怎么 import、API 长什么样、和同类比有什么不同**。

必备：安装（包管理器命令）· 最小示例（10 行以内跑通）· 主要 API / 用法分节 · 兼容性（运行的运行时版本）· 相关链接（文档站、示例仓）

加分：同类方案对比表 · 迁移指南（大版本升级时）· 类型/TS 提示

要避免：把整个 API 文档抄进 README。README 只放**入口级**示例，细节留给 docs 站。

### CLI 工具

读者关心：**怎么装、怎么用、有哪些命令**。

必备：安装（多平台：brew / npm / curl / 下载二进制）· 一条最短命令的用法演示（含真实输出）· 命令/选项表格 · 常见工作流示例

参考 [inspiration/run-on-output.md](inspiration/run-on-output.md)：它用"我想做 X → 命令 → 结果"的写法组织示例，非常好读。

### Web 应用

读者关心：**长什么样、怎么本地跑起来、怎么部署**。

必备：截图/GIF（越靠前越好）· 前置要求 · 本地起服务（含 dev server 端口）· 环境变量/密钥配置 · 构建与部署方式

加分：技术栈一览 · 项目结构树 · 部署到各家平台的按钮（若真实可用）

### 后端服务 / API

读者关心：**怎么本地起舞、接口怎么调、怎么部署、怎么观测**。

必备：架构一句话（可选配图）· 依赖（数据库/中间件）· 本地启动（含依赖的 docker-compose 命令）· 环境变量表 · 接口示例（curl 或代码）· 部署与回滚

参考 [inspiration/serverless-chat-langchainjs.md](inspiration/serverless-chat-langchainjs.md)：它把"本地/容器/云端"三条路径分节写清，是服务类 README 的范本。

### Monorepo

读者关心：**这堆包分别是什么、我只想要其中一个怎么办**。

必备：仓库鸟瞰（各 workspace 一句话）· 包的表格（包名 | 作用 | 路径）· 全局开发流程（install / build / test 的根命令）· 如何只跑单个包 · 版本与发布策略

## 常用区块写法

**安装**——给最短路径，多平台并排：

```bash
npm install <pkg>
# 或
brew install <tool>
```

**最小示例**——从零到看见结果，不超过 15 行，注释说明关键参数。

**配置**——用表格，别用散文：

```markdown
| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PORT` | 服务监听端口 | `3000` |
| `DATABASE_URL` | Postgres 连接串（必填） | — |
```

**项目结构**——只列读者需要理解的层级，不用列全：

```text
src/
├── core/       # 领域逻辑
├── adapters/   # 外部依赖适配
└── cli.ts      # 入口
```

## Admonition 与徽章

**GitHub admonition**（GFM 语法，GitHub 及多数渲染器支持）：

```markdown
> [!NOTE]
> 补充信息，读不读都行。

> [!TIP]
> 更省事的做法。

> [!IMPORTANT]
> 不照做会出错的关键信息。

> [!WARNING]
> 需要立刻注意的问题。

> [!CAUTION]
> 会造成不可逆后果的操作。
```

用法建议：一篇 README 里 admonition 控制在 1–3 处。全部加粗等于全部不加粗——提示多了就没人看了。

**徽章**——只放**真实存在**的：

```markdown
[![npm version](https://img.shields.io/npm/v/<pkg>.svg)](https://www.npmjs.com/package/<pkg>)
![Node version](https://img.shields.io/node/v/<pkg>.svg)
[![CI](https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg)](https://github.com/<owner>/<repo>/actions)
```

没有 CI workflow 文件就别放 CI 徽章；没有 `LICENSE` 文件就别放 license 徽章。徽章写着"passing"而实际从没跑过，是 README 里最常见的谎言。

## 常见反例

| 反例 | 为什么糟 | 改成 |
|------|---------|------|
| 只有一句 "TODO: write README" | 等于没有 | 至少写清"是什么 + 怎么跑" |
| `npm install my-project` 但包名根本不同 | 照做会失败 | 核实 `package.json` 的 `name` |
| 抄了 200 行 API 文档 | 正文失焦，维护成本高 | 只留入口示例，细节指向 docs |
| 一堆 `🚀✨🎉🔥` | 读起来吵，显得不专业 | 顶多标题一个，或全不用 |
| 大段 LICENSE 正文 | 与 `LICENSE` 文件重复 | 一句话 + 链接 |
| 提到"配置你的 API key"但没说变量名 | 读者卡住 | 给出变量名与示例值 |
| 截图用了不存在/已删除的文件 | 图裂 | 确认资源文件在仓库里 |
| 所有命令写成一行长串 | 难以复制和排错 | 分步代码块 |
