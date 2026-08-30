# VoltAgent/awesome-design-md

**一句话定位**：主流品牌设计系统的 DESIGN.md 合集，丢进项目后让 Coding Agent 生成匹配该品牌的界面。

## 基本信息
- **GitHub**: https://github.com/VoltAgent/awesome-design-md
- **协议**: MIT
- **Star**: 约 111k

## 定位 / 它解决什么
一个由主流品牌设计系统（design systems）分析出的 `DESIGN.md` 文件合集。做法是把这些文件丢进你的项目，让 coding agent 读取后按该品牌的视觉规范生成界面——解决"AI 生成的软件越写越丑 / 配色排版飘忽"的问题，让 AI 产出的 UI 稳定贴合某个设计语言。

## 安装 / 用法
从仓库里挑选一个与你目标相符的品牌设计系统的 `DESIGN.md`，放到项目里让 coding agent 读取即可：

```bash
# 例：把选中的 DESIGN.md 放到项目根
cp path/to/desired-design/DESIGN.md ./DESIGN.md
# 然后告诉 coding agent：按 DESIGN.md 生成/改 UI
```

## 使用场景
- 想让 AI 生成的界面对齐某知名品牌的视觉风格
- 新项目希望 UI 一开始就有统一的设计语言，而不是越迭代越乱
- 交付给客户/上线前的界面统一化

## 使用效果 / 好处
- 给 coding agent 一个明确的视觉"锚点"，避免它自由发挥
- 与仓库里已有的 `ai-ui-styling` 经验（喂配色规范图重配色）是同一思路的工程化沉淀

## 注意点
- 品牌设计系统一般是**参考/启发**，直接用对应品牌的完整 DESIGN.md 到商用项目前，先确认版权和使用边界
- 效果依赖 coding agent 对 DESIGN.md 的执行力，建议配合"先对齐再动手""收敛复核"等规则一起用