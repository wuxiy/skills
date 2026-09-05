# iOfficeAI/OfficeCLI

**一句话定位**：全球首个专为 AI Agent 打造的 Office 套件 CLI——让 AI 用一行命令读写、编辑、自动化 Word / Excel / PowerPoint，免费开源、单一二进制、无需安装 Office。

## 基本信息
- **GitHub**: https://github.com/iOfficeAI/OfficeCLI
- **协议**: Apache-2.0
- **Star**: 约 30k
- **工具链**: C# 编写，.NET 运行时已内嵌（单一自包含二进制，无需装运行时）

## 定位 / 它解决什么
AI Agent 处理 Office 文档（.docx / .xlsx / .pptx）过去极痛苦：要么一个个啃 python-docx / openpyxl / python-pptx 三个库，五六十行代码才能做个 PPT；要么依赖本机装的 Office 套件做 UI 自动化，重、慢、还要授权。OfficeCLI 给 AI Agent 一个**统一的命令行入口 + XPath 式文档定位器**，读改 Office 文件就像操作一个文档树：

- **Create**：从空白或带内容创建文档
- **Read**：读文本、结构、样式、公式（纯文本或结构化 JSON）
- **Analyze**：检查格式问题、样式不一致、结构缺陷
- **Modify**：改任意元素——文本、字体、颜色、布局、公式、图表、图片
- **Reorganize**：跨文档增删移复元素

Word / Excel / PPT 三者在 Read / Modify / Create 上全支持 ✅。

## 安装 / 用法

**一行安装（macOS / Linux）：**
```bash
curl -fsSL https://raw.githubusercontent.com/iOfficeAI/OfficeCLI/main/install.sh | bash
```
其他方式：
```bash
brew install officecli        # macOS / Linux
npm install -g @officecli/officecli   # 全平台，自动拉对应平台的原生二进制
# Windows (PowerShell): irm https://raw.githubusercontent.com/iOfficeAI/OfficeCLI/main/install.ps1 | iex
```
验证：`officecli --version`

**典型用法**（以创建 PPT 为例）：
```bash
officecli create deck.pptx
officecli add deck.pptx / --type slide --prop title="Q4 Report" --prop background=1A1A2E
officecli add deck.pptx '/slide[1]' --type shape \
  --prop text="Revenue grew 25%" --prop x=2cm --prop y=5cm \
  --prop font=Arial --prop size=24 --prop color=FFFFFF
officecli view deck.pptx outline     # 文本大纲预览
officecli view deck.pptx html        # 浏览器渲染预览（无需服务器）
officecli get deck.pptx '/slide[1]/shape[1]' --json   # 取任意元素的结构化 JSON
officecli close deck.pptx            # 落盘关闭
```
核心心智：**`officecli <子命令> <文件> <XPath定位> --prop 键=值`**。`save` 用于刷新落盘、`set` 用来改元素属性、`add`/`remove` 增删元素。

**Agent 集成**：安装脚本会自动把 `officecli` skill 装进它检测到的每个 coding agent（Claude Code、Cursor、Windsurf、Copilot 等），装完 AI 就能立刻代你创建/读写 Office 文档，零额外配置。

## 使用场景
- **AI Agent**：根据用户 prompt 生成 PPT / 报告；从文档提取结构化数据成 JSON；交付前校验文档质量
- **开发者**：数据库/API 自动生成报告；批量文档处理（全局查找替换、样式更新）；CI/CD 里从测试结果生成文档
- **容器/无头**：Docker 里无头 Office 自动化（无需装 Office）
- **团队**：克隆文档模板批量填充数据；CI 里自动文档校验

## 能力亮点（Deep）
- **Word**：完整 i18n/RTL（阿拉伯语、印地语、泰语、CJK）、修订/追踪更改、LaTeX 公式、mermaid 图 → 原生可编辑形状、批注/脚注/水印/TOC/书签/域（22 种零参域 + MERGEFIELD/REF/IF…）
- **Excel**：350+ 内置函数自动求值（含动态数组）、数据透视表 + 切片器、条件格式、Sparklines、OLE、公式引用在行列插入时的自动改写
- **PPT**：动画/转场/3D 模型(.glb)/SmartArt 往返、mermaid 流程图/时序图 → 原生形状、主题、视频音频、分组
- 查改统一用类 XPath 定位器，如 `/slide[1]/shape[1]`、`row[Salary>5000 and Region=EMEA]`

## 注意点
- **save / close 语义**：officecli 自带 resident session 机制——它自己的读总是最新，但**外部程序（python-docx、Word、上传）读取前要先 `officecli save` 刷落盘**，避免读到未落盘的编辑
- 功能极多、命令面广，建议第一次用时让 AI agent 查 `officecli help` / wiki 而非凭记忆硬敲（wiki：github.com/iOfficeAI/OfficeCLI/wiki）
- 与 [archify](archify.md) 这类"产图/基建"类 repo 不同，OfficeCLI 是**纯 Office 文档自动化**方向，两者互补不冲突