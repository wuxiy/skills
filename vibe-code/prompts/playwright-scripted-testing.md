# 让 Agent 写 Playwright 脚本，而不是让 Agent 自己去点页面

> 一条 E2E 测试理念的反转：**别让模型当"点击员"，让它当"测试脚本作者"。** Agent 只负责写可重复跑的 Node.js + Playwright 脚本，真正执行交给 Playwright runner，而不是让 Agent 用浏览器工具/MCP 一轮轮现场点页面验证。

## 核心对比

| 方式 | Agent 自己测 | Playwright 测 |
|------|-------------|---------------|
| 做法 | 看截图 → 思考 → 点一下 → 再看截图 | 写一次脚本，`npx playwright test` 几秒跑完 |
| Token | 贵 | 几乎不花 |
| 速度 | 慢 | 快 |
| 稳定性 | 不稳定 | 稳定 |
| 资产 | 测完留不下 | 可回归、进 CI，留得下 |

## 1. 项目里先装好 Playwright

```bash
npm init playwright@latest
# 或
pnpm create playwright
```

常见结构：
```text
tests/
  auth.spec.ts
  checkout.spec.ts
playwright.config.ts
```

`playwright.config.ts` 让它自己起本地服务：
```ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## 2. 把规则写进 AGENTS.md / CLAUDE.md / .cursorrules

这是这条帖子真正要你"怎么做"的部分。可直接贴：

```md
## 测试规则

1. 禁止给 UI 写单元测试（按钮渲染、className、快照这类）。
2. 禁止用 browser MCP / Playwright MCP / computer use 自己点页面做 E2E。
   原因：浪费 token、速度慢、结果不稳定。
3. 任何新功能或 bugfix，必须同时补 Node.js Playwright 脚本（tests/**/*.spec.ts）。
4. 验证方式只能是：
   - npx playwright test
   - 或跑指定文件：npx playwright test tests/xxx.spec.ts
5. 测试失败时：
   - 先保证脚本能稳定复现问题
   - 再给页面/接口加日志、把步骤拆小
   - 然后改业务代码，直到脚本变绿
6. 选择器优先用 getByRole / getByTestId，不要用脆弱的 CSS 层级。
```

原帖语境补充：
- @meetqy：禁止 UI 单测，只列出受影响 UI + Todo，人来验
- @supezen：不要让 Agent 主动做 E2E
- @xicilion：E2E 用 Node.js + Playwright；**每个功能和修复都要写脚本**。脚本能复现后，Agent 自己加日志、拆步骤、修到过

## 3. 让 Agent 写的是"这种脚本"，不是"自己去点"

登录示例：
```ts
import { test, expect } from '@playwright/test';

test('用户可以登录并进入工作台', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('邮箱').fill('demo@example.com');
  await page.getByLabel('密码').fill('password123');
  await page.getByRole('button', { name: '登录' }).click();
  await expect(page).toHaveURL(/\/dashboard/);
  await expect(page.getByRole('heading', { name: '工作台' })).toBeVisible();
});
```

前端补稳定锚点：
```tsx
<button data-testid="checkout-submit">提交订单</button>
```
```ts
await page.getByTestId('checkout-submit').click();
```

## 4. 实际工作流（"具体怎么做"）

1. 你提需求：加一个"忘记密码"功能
2. Agent 改业务代码，同时新建 `tests/forgot-password.spec.ts`
3. 你或 Agent 只跑命令：`npx playwright test tests/forgot-password.spec.ts`
4. 失败了，**不要让它开浏览器 MCP 瞎点**。正确做法是让它：
   - 看 Playwright 失败截图 / trace
   - 给关键请求、状态、时序打日志
   - 把一个大测试拆成更小步骤
   - 修代码后再跑同一条脚本

> 原话：以前手测，回归一堆细节问题，复杂 UI 时序几乎没法迭代。后来要求 Agent 任何功能和修复都必须写 Node.js Playwright 脚本；只要能复现，它就会自己加日志、拆分，最后修好，人不用参与。

## 5. 和"Playwright Agents"区分开

Playwright 新版有 Planner / Generator / Healer 这类 Agent——那是"帮你生成/修复测试代码"。

这条帖子反对的是另一件事：**让编码 Agent 当场扮演测试员，用工具一轮轮操作真实页面来验证**。

你要的分工：
- **Agent = 写测试代码 + 改产品代码**
- **Playwright runner = 执行测试**

## 6. 一个可直接用的提示词

需求后面加上：
```text
不要自己打开页面点来点去验证。
请直接写 Playwright 测试到 tests/ 目录，用 npx playwright test 验证。
如果失败，先让脚本稳定复现，再加日志/拆步骤，然后修代码，直到测试通过。
不要写 UI 单元测试。
```

---

## 与本书库的关系

- 与 [codex-skills-trio](experience/codex-skills-trio.md) 的 **agent-browser** 形成对照：agent-browser 让 Agent 用浏览器 CLI 自验，本条主张**写脚本让 runner 测**——后者更省 token、可回归。二者可结合：复杂一次性验证用 agent-browser，长期回归用 Playwright 脚本
- 与 [ai-reliable-engineering](experience/ai-reliable-engineering.md) 的"最小可用 E2E 验收（BDD 思路）"同源——都反对 AI 为过测试硬凑代码、都强调交付硬指标；本条给出具体落地（脚本作者 vs 点击员）
- 与 [execution-discipline](prompts/execution-discipline.md) 的 Review 门禁呼应：脚本能复现 → 就是"一个需求只动一个模块/一次做对"的可验证闭环

> **一句话**：脚本能复现，后续修复、回归、CI 就都便宜且稳定了——让模型去写脚本，别让模型去点屏幕。