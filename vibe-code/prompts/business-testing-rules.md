# 业务项目怎么写测试：6 条规则

> 来源：Gangqiang Yao @yaogangqiang（2026-09-15）https://x.com/yaogangqiang/status/2099757363519709283
> 姊妹篇：[playwright-scripted-testing](playwright-scripted-testing.md)（谁执行测试）· 本篇解决（测试该怎么写）

## 前置论断（上一条推文）

> 随着 vibe coding 产出大量代码，**大部分项目质量并没有提高**。整个软件研发历史里，写代码一直是最容易的环节，有了 AI 之后只是让这个环节变得更容易了。
>
> 有人说"那你让 AI 写测试啊"——现实是，**不做任何调教，AI 写出来的全都是充满 mock 的、测试实现细节的脆弱测试**，而不是验证行为的测试。更残酷的是：**即使你教会 AI 写对测试，照样不能保证软件质量**。
>
> 因为测试从来不是高质量软件的关键：**Quality is designed in, not tested in.**

**所以：先把测试写对，是基础。** 下面是针对业务项目的 6 条。

---

## 6 条规则（原文 + 解读）

### 1️⃣ 测试行为，不测试实现

> 比如重复下单不会重复扣款，而不是某个方法调用了几次。业务没变，重构一下测试就碎一地，那多半写错了。**AI 特别容易写这种测试。**

- ✅ `重复下单不会重复扣款`（业务行为）
- ❌ `orderService.create() 被调用了 2 次`（实现细节）
- **自检标准**：业务没变、只重构内部实现，测试如果碎一地 → 测试写错了

### 2️⃣ 用 BDD，先写验收场景，再写代码

> 测试描述统一用 user 开头，用 Given / When / Then 描述，用户和 PM 也能看懂。**别让 AI 写完代码，再照着自己的实现证明自己没错。**

- 描述格式统一：`user 可以...` / Given / When / Then
- 顺序很关键：**先场景后代码**。反过来就成了"照着自己的实现证明自己没错"，测试沦为橡皮图章
- 好处：用户和 PM 能读懂 → 需求对齐多一道人工闸门

### 3️⃣ 禁止 mock

> Redis、PostgreSQL 能用真的就用真的，外部系统不好接就注入 fake，但要校验它和真实系统的契约。时间逻辑用 fake timer，别 sleep 几秒再祈祷。**AI 真的太喜欢随手 mock 了。**

- 能用真的依赖就用真的（Redis / PostgreSQL 等）
- 外部系统接不了 → 注入 **fake**（不是 mock），且**要校验 fake 与真实系统的契约**
- 时间逻辑用 **fake timer**，不要 `sleep(3)` 然后祈祷

### 4️⃣ 大部分写 E2E，测试分级

> 从用户入口走到可见结果，外部依赖可以 fake，实在不合适再写其他测试。测试多了就分级，**按改动和依赖关系精准测试，定期完整跑**。别改两行代码，等 CI 半天。

- 默认倾向：E2E（用户入口 → 可见结果）
- 测试规模上来了要**分级**：日常按改动/依赖关系精准跑，定期完整跑
- 反模式：改两行代码就让 CI 跑半天

### 5️⃣ 覆盖率是第二步，重点是"为什么没测"

> 前面做好了，再看分支覆盖率，先定个 90%。但**重点是剩下的为什么没测，尤其是失败路径**，别让 AI 为了凑数字再写一堆垃圾测试。

- 覆盖率是**结果指标，不是目标**（前面几条做不到，覆盖率毫无意义）
- 盯"剩下没覆盖的是什么"，特别是**失败路径**
- 明确禁止"为凑数字写垃圾测试"

### 6️⃣ 前边的规则尽量都写成 lint

> （原文第 6 条）

- 规则写在 prompt 里靠自觉，**写进 lint 才靠得住**——机器检查优于口头约定
- 可 lint 化的例子：禁止 mock 调用（`mock(`/`jest.mock` 白名单）、禁止 `sleep`、禁止断言调用次数、测试命名以 `user` 开头、禁止 UI 单测等

---

## 落地方式

**① 写进 AGENTS.md / CLAUDE.md / .cursorrules**（示例）：

```md
## 测试规则

1. 测试行为不测试实现：断言业务结果（重复下单不重复扣款），不断言调用次数。
2. BDD 优先：先写 Given/When/Then 验收场景再写代码；描述以 user 开头。
3. 禁止 mock：能用真的依赖就用真的；外部系统用 fake 并校验契约；时间用 fake timer，禁止 sleep。
4. 默认写 E2E（用户入口 → 可见结果）；测试分级，按改动精准跑、定期全量跑。
5. 覆盖率是第二步：关注未覆盖的失败路径，禁止为凑数字写测试。
```

**② 把能自动化的规则做成 lint**（第 6 条的重点）：

- 禁止 `jest.mock` / `vi.mock` 出现（或限定白名单）
- 禁止测试里 `sleep` / `setTimeout` 等待
- 禁止断言 `toHaveBeenCalledTimes`
- 测试用例命名必须以 `user` 开头

---

## 与本书库的关系

| 本条规则 | 呼应 |
|---------|------|
| 1️⃣ 测试行为不测试实现 | [ai-code-evolution](../experience/ai-code-evolution.md)（单测要覆盖"想当然"的坑，而非实现细节） |
| 2️⃣ 先场景后代码 | [ai-reliable-engineering](../experience/ai-reliable-engineering.md)（BDD + 最小可用 E2E 验收，防 AI 为过测硬凑） |
| 4️⃣ 大部分写 E2E | [playwright-scripted-testing](playwright-scripted-testing.md)（E2E 由 runner 跑，Agent 只写脚本） |
| 5️⃣ 别为凑数字 | [execution-discipline](execution-discipline.md)（禁止过度设计，只做要求的） |
| 6️⃣ 写成 lint | [commit-message](commit-message.md)/[convergence-review](convergence-review.md)（规则固化进工具链，不靠自觉） |

> **一句话**：AI 写的测试默认不可信（充满 mock、测实现细节、为凑覆盖率凑数）——先把"测行为、先场景、禁 mock、重 E2E、盯失败路径、写成 lint"这 6 条立起来，测试才配叫"基础"。