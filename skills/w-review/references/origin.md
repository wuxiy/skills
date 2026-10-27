# 规则来源映射

本技能每条判定标准的出处。修改技能规则时同步更新此表——经验和技能各说各话，是这类 skill 最常见的腐化方式。

## 通用铁律

| 技能里的规则 | 出处 | 原文要点 |
|---|---|---|
| 无证据不入报告 | [eight-agent-principles](../../../vibe-code/experience/eight-agent-principles.md) 原则 2 | 「让没参与实现的独立 Agent 审查：找反例、遗漏、失败场景，每条意见必须给证据」 |
| 区分事实与推测 + 什么证据会推翻判断 | 同上 原则 7 | 「区分事实与推测；说明什么证据出现会推翻你的判断」 |
| 列出不自信的点 | 同上 原则 5 | 「哪些结论缺证据、哪些场景没测、哪些只是猜测」 |
| 评审者与实现者分离 | [agent-friendly-workflow](../../../vibe-code/experience/agent-friendly-workflow.md) 三·5 | 「交叉对抗性审查 → 问题统一反馈给主编码 Agent 修复并重新验证」 |
| 不得以「建议增强」打回 | [execution-discipline](../../../vibe-code/prompts/execution-discipline.md) | 「review 不得以'建议增强'为由打回」 |
| 禁止过度设计（奥卡姆） | [eight-agent-principles](../../../vibe-code/experience/eight-agent-principles.md) 原则 4 | 「先做最简单能工作的版本，不要预建框架」 |

## 方案评审（plan）

| 技能里的规则 | 出处 | 原文要点 |
|---|---|---|
| 问题定义 / 先钉死问题 | eight-agent-principles 原则 1 | 「先回归事实：问题能否复现、根因是什么、修复前后结果有什么变化」 |
| 隐性假设拷打 | [ai-reliable-engineering](../../../vibe-code/experience/ai-reliable-engineering.md) 1️⃣ | 支付超时怎么回退库存 / 回调重复通知如何幂等 / 多端登录 Token 怎么刷新 |
| 路径四维权衡 | 同上 2️⃣ | 实现复杂性 / 维护复杂性 / 时间与资源成本 / **可逆性** |
| 先 probe 再踩油门 | 同上 2️⃣ | 「先定拓扑，再定具体实现」；spike、示踪弹（Tracer Bullets） |
| ADR（背景-决策-后果） | 同上 2️⃣ | 「明确写下背景-决策-后果与代价」 |
| 消融实验 | eight-agent-principles 原则 3 | 「删掉这条规则/工具/提示词再跑一遍，对比结果」 |
| 验收标准可执行 | [goal-mode](../../../vibe-code/prompts/goal-mode.md) | 「先确认需求 → 出验收清单 → 开发 → 实际运行逐项验证」 |
| 领域模型闭合性（预占/确认/释放、对账留痕） | **来自 2026-10-27 iteration-1 评测**——基线组在扣库存用例里指出「下单未支付期间未占库存，同一件货可被重复下单」「无流水，难与支付账单核对」，技能组原六维全部漏掉。vibe-code 里没有对应条目，属评测反向补进来的盲区 |
| 尺度控制（问够了就开工） | agent-friendly-workflow 三·2 | 「当剩下的问题已经不会显著改变实现方向和验收结果时，就可以开始开发」 |

## 代码 review（code）

| 技能里的规则 | 出处 | 原文要点 |
|---|---|---|
| 先看验收标准再看测试结果 | agent-friendly-workflow 五·1 | 「不能只看测试通过多少，还要看这些测试是否验证了这次需求真正关心的事情」 |
| 精力压在高风险区 | 同上 五·2 | 「重点查权限、状态变化、并发、重试、数据一致性、迁移和回滚；模式稳定的 CRUD 可以少看」 |
| 专审新增抽象 | 同上 五·3 | 「用奥卡姆剃刀再让 AI 审一遍：是否真有必要、有没有更简单的实现」 |
| MR 多时固定流程 | 同上 五·4 | 「把 Git 变更信息 + 预先设计好的审查流程结合起来，形成可重复执行的 Review 能力」 |
| 收敛复核（清理探索痕迹） | [convergence-review](../../../vibe-code/prompts/convergence-review.md) | 「删除或回退探索过程中加入但最终不再需要的临时分支、兜底、重复逻辑和额外刷新/重载」 |
| 非显然约束写中文 WHY 注释 | 同上 | 「说明字段语义、状态生命周期或时序边界，避免后续排查再次沿错误假设扩散」 |
| 测试质量四条 | [business-testing-rules](../../../vibe-code/prompts/business-testing-rules.md) | 测行为不测实现 / 先 BDD 场景 / 禁 mock / 盯失败路径 / 规则写成 lint |
| Review 门禁 + 3 遍上限 | execution-discipline | 「每完成一条立即 review，有问题先修复并复审通过才能进下一条；同一条最多 3 遍」 |

## 由评测反向补入的规则

有些规则不是从 vibe-code 抄来的，是被评测打出来的。这类必须在表里标清来源，否则下一次改技能会以为它本来就在经验库里、删了也无所谓。

- **领域模型闭合性**（七维检查表第 7 条）：iteration-1 中基线组优于技能组的地方，见上表

## 未纳入本技能的内容

以下经验同样有价值，但属于"实现"而非"评审"，没有塞进来，避免技能变重：

- [design-restraint](../../../vibe-code/prompts/design-restraint.md) — 界面设计方向，评审时可作为 UI 维度的参考，但不作为硬标准
- [module-split-by-change](../../../vibe-code/experience/module-split-by-change.md) — 模块划分方法，属于设计阶段决策
- [git-knowledge-loop](../../../vibe-code/experience/git-knowledge-loop.md) — commit 知识循环，属于流程建设
