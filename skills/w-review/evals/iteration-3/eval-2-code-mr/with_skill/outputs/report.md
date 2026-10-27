# 代码 Review：取消订单流程改动

## 评审结论
**不可合并。** 一句话理由：这次改动实际做的是「删除后端越权校验」+「引入无失效的进程内全局缓存」，两条都会直接造成线上资金与数据事故，与 MR 描述的「优化取消流程」不符。

## BLOCKER（会导致线上事故）
- `api/order.ts` → `cancelOrder(id, userId)` — **水平越权（IDOR）**：`userId` 进了签名却从未参与任何校验，任何登录用户（甚至未登录，取决于路由中间件）只要拿到 orderId 就能取消他人订单并触发退款。证据：函数体内 `userId` 无任何出现；diff 注释「权限判断改到前端，后端不再校验 userId」。前端 `OrderDetail.tsx` 把 `canCancel &&` 去掉后，UI 对所有人展示取消按钮。建议：后端按 `order.userId === userId` 校验并返回 403，前端按钮展示只是 UX，不构成安全边界。
- `api/order.ts` → `getOrder` 的模块级 `const cache = new Map<string, Order>()` — **缓存永不失效**：`cancelOrder` 里 `db.order.update(... status: 'CANCELLED')` 之后没有 `cache.delete(id)`，后续 `getOrder` 继续返回旧的 `PAID` 快照；重复取消会重复打 `pay.internal/refund`（叠加下面无幂等的问题＝重复退款）。另：Map 无 TTL、无容量上限，进程常驻内存无限增长；多实例部署时各副本缓存互相不一致。建议：要么删掉这层缓存（当前需求看不出它解决的问题），要么在状态变更处显式失效，且不要用无界缓存存订单。
- `api/order.ts` → `getOrder` 中 `cache.set(id, order)` — 未命中时 `findUnique` 返回 `null`，也会被写入 `Map<string, Order>` 并原样返回；返回类型 `Order` 与实际可能为 `null` 不一致，且**负缓存永不失效**（订单创建后仍一直返回 null）。
- `api/order.ts` → `cancelOrder` 的退款段 — **无幂等、无事务、失败被静默吞掉**：`fetch` 不检查 `res.ok`、无超时、无 `Idempotency-Key`、失败不抛出；即使退款接口返回 500，下一行照样把订单改成 `CANCELLED` → 状态显示已取消但钱没退，或钱退了但 update 失败导致订单仍是 `PAID`。建议：退款请求带业务幂等键（如 `orderId` + 尝试序号）；先落「取消中/退款中」中间态并留流水，退款确认后才置 `CANCELLED`；失败要有可见错误与重试入口。

## MAJOR（潜在风险，不单独阻断但需在同一 MR 处理）
- **状态机不完整**：只判了 `PAID` 才退款，但没判当前状态是否允许取消；`CANCELLED` 订单可被再次取消，`PENDING` 与 `PAID` 走同一分支。建议显式列出合法迁移（`PENDING|PAID → CANCELLED`，其余 409）。
- **无审计留痕**：`userId` 被丢弃后，取消动作没有操作人、没有时间线、没有退款流水，事后无法与支付侧对账，出问题查不出来。
- **测试缺失**：描述与 diff 都没有测试。「测试全绿但测无关路径」在这里升级为「没有测试」——权限、并发双取消、退款失败回滚这三条是必须覆盖的失败路径。
- **描述与实现不一致**：「改动不大，主要是优化了取消流程」掩盖了两处安全/一致性改动。建议 MR 描述里显式写清鉴权策略变更，便于评审与回滚。

## MINOR / NIT（不阻断合并）
- 退款 URL `https://pay.internal/refund` 硬编码在业务函数里，应走配置（NIT）。
- `cache` 命名过于笼统，任何读 `getOrder` 的调用方都会拿到陈旧数据，无 WHY 注释说明其生命周期约束（NIT）。

## 本次不审的部分
无。改动本身小，且全落在权限、状态变化、外部调用、数据一致性这四个高风险区，逐条看完；`OrderDetail.tsx` 之外的前端联动（谁写入 `onCancel`、路由层是否有鉴权中间件）不在 diff 内，未审。

## 我不自信的点
- **只有 diff 片段，没有仓库上下文**：无法确认路由层是否有服务端鉴权中间件兜住（若已有，IDOR 的严重度可降到 MAJOR）。**推翻方法**：给出 `cancelOrder` 的调用方/handler 与鉴权中间件代码。
- **行号无法给出**：输入是纯 diff，没有 `文件:行`，证据只能指向函数段落。**推翻方法**：给 `git diff --stat` 与实际文件。
- **类型是否编译失败未知**：`Map<string, Order>` 里塞 `null` 在 `strictNullChecks` 下应报错；若项目关了 strict 则只是运行期隐患。**推翻方法**：`tsconfig.json` + CI 输出。
- 未实测并发双请求下的实际退化路径（重复退款是否真会发生，取决于支付侧是否自己有幂等），这条是**推测**而非结论。
- 未确认 `canCancel` 这个变量是否还有其他用途（比如状态文案），删除是否留下未使用变量未知。
