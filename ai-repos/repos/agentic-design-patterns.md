# evoiz/Agentic-Design-Patterns

**一句话定位**：《Agentic Design Patterns: A Hands-On Guide to Building Intelligent Systems》（Antonio Gulli 著）的完整配套教材仓——21 章 PDF + 逐章 Jupyter notebook，系统讲清构建 Agent 系统的设计模式。

## 基本信息
- **GitHub**: https://github.com/evoiz/Agentic-Design-Patterns
- **作者**: Antonio Gulli（书籍作者，版税全捐 Save the Children）
- **协议**: Educational（**注意：非标准开源协议**，见下方注意点）
- **Star / Fork**: 约 3.4k / 529
- **技术栈**: Jupyter Notebook（Python 3.8+），大量 LangChain / OpenAI 示例
- **形态**: 教材仓 —— PDF 章节（共 ~400 页）+ `chapter_notebooks/` 可运行代码

## 定位 / 它解决什么
AI 时代绝大多数"怎么构建 Agent"的知识是碎片化的博客/推特。这个仓把 Agent 设计的**模式语言**系统化成一本书 + 可跑代码：从提示链、路由、并行，到记忆、MCP、A2A、护栏、评估，形成一套完整的设计模式目录。

**21 章四大部**：

| 部 | 章 | 内容 |
|----|----|------|
| **Part 1 基础模式** | 1-7 | Prompt Chaining（提示链）· Routing（动态路由）· Parallelization（并行）· Reflection（自省）· Tool Use（工具调用）· Planning（规划）· Multi-Agent（多 Agent） |
| **Part 2 进阶模式** | 8-11 | Memory Management（状态持久化）· Learning & Adaptation · **MCP**（标准化接口）· Goal Setting & Monitoring |
| **Part 3 生产模式** | 12-14 | Exception Handling & Recovery · **Human-in-the-Loop** · **RAG**（知识检索） |
| **Part 4 企业模式** | 15-21 | **A2A**（Agent 间通信）· Resource-Aware Optimization · Reasoning Techniques · **Guardrails/Safety** · Evaluation & Monitoring · Prioritization · Exploration & Discovery |
| 附录 | — | 74 页附录 + 结论与参考文献 |

> 注意：这些是**设计模式目录**（pattern language），不是某个框架的 API 手册——价值在于"遇到问题知道该用哪种模式"，跨框架通用。

## 安装 / 用法

**准备环境：**
```bash
# 需要 Python 3.8+
git clone https://github.com/evoiz/Agentic-Design-Patterns.git
cd Agentic-Design-Patterns
python -m venv venv && source venv/bin/activate
pip install jupyter notebook
pip install pandas numpy matplotlib openai langchain   # 或用 requirements.txt
```

**跑某一章：**
```bash
cd chapter_notebooks
jupyter notebook Chapter_01_Prompt_Chaining.ipynb
```
每章 notebook 的 cell 按顺序执行即可。

## 三种用法（原仓建议）
- **自学**：读 PDF 章节 → 开对应 notebook → 跑例子 → 改着玩 → 做练习
- **教学**：章节当讲义，notebook 当实验课
- **研究**：直接引用其中的实现模式

## 使用场景
- 想**系统补齐 Agent 设计模式**的知识地图（而不是零散看博客）
- 设计自己的 Agent 系统时，对照"这个场景该用哪个模式"
- 给团队做 Agent 工程培训时的现成教材
- 与本库 [eight-agent-principles](../experience/eight-agent-principles.md)、[ai-reliable-engineering](../experience/ai-reliable-engineering.md) 互补：那两篇是**工作方法论**，这个仓是**模式百科/教科书**

## 注意点
- **协议是 Educational 而非 MIT/Apache**——用于学习/教学/研究没问题，**商用或再分发前先确认授权**
- 内容量极大（~400 页 + 21 个 notebook），适合**按需查阅**而非一次读完；建议先读 Part 1 建立骨架
- 示例多用 LangChain / OpenAI API，跑代码需要相应 key 与网络；不想配环境时可只读 PDF + notebook 文本
- 仓库是书籍配套，**不是可安装的库/工具**——别指望 `pip install` 一个包就用上

## 一句话
> 如果你想搞懂"Agent 到底该怎么设计"，这是目前最系统的一份公开教材——把散落的最佳实践收拢成一本可查、可跑、可教的模式目录。
