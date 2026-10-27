# 代码 Review：取消订单流程

## 评审结论
**不可合并** — 这个 diff 不是「优化取消流程」，而是删掉了后端鉴权，并引入了一个永不失效的缓存；两者叠加 = 越权取消 + 重复退款。

## BLOCKER

1. **越权取消（IDOR）** — 证据：`cancelOrder(id, userId)` 的 `userId` 全程未使用；diff 自带注释 `// 权限判断改到前端，后端不再校验 userId`。任何人拿到 orderId 即可取消他人订单并触发退款。前端判断不是鉴权，删掉 `{canCancel && ...}` 等于把闸门交给调用方。建议：后端用会话内的 userId 与 `order.userId` 比对，失败 403。

2. **缓存永不失效 → 重复退款** — 证据：`getOrder` 写入 `cache`，`cancelOrder` 里 `db.order.update({ status: 'CANCELLED' })` 之后没有任何 `cache.delete`。同实例内再次 `getOrder(id)` 仍返回 `status:'PAID'`，条件再次成立 → 二次 `POST /refund`。建议：状态变更后失效缓存，或取消流程直接读 DB 不走缓存。

3. **退款结果未校验、非原子** — 证据：`await fetch('https://pay.internal/refund', {...})` 返回值无人读取，HTTP 500 后照样 `update` 置 CANCELLED；反向（退款成功、update 失败）也无补偿，请求无幂等键。建议：检查 `res.ok`，加幂等键，走 `PENDING_CANCEL` 状态机/事务。

4. **并发双取消** — 证据：先 `getOrder`（读缓存）再 `update`，两步之间无锁、无 `where: { status: 'PAID' }` 条件。两请求可同时判定 PAID 并各退一次。建议：条件更新 `updateMany({ where: { id, status: 'PAID' } })`，按 `count` 决定是否退款。

## MAJOR
- 缓存实现本身：`Map<string, Order>` 无 TTL/容量上限，无界增长；`db` 返回 `null` 时 `cache.set(id, null)` 与类型不符（TS 报错），且 `has` 为 true 使空结果永久命中，随后 `order.status` 直接崩。多实例/Serverless 下各副本不一致。
- 前端永远渲染取消按钮：已 CANCELLED / 已完成订单仍有取消入口，点了才失败。UI 状态判断不该跟着权限判断一起删。
- 语义耦合：把一个带副作用的读缓存塞进 `getOrder`，取消流程的状态机正确性被绑在缓存行为上。

## MINOR（不阻断合并）
- `cache.has` + `cache.get` 双查；`fetch` 缺 `Content-Type`、超时与内部鉴权头；`userId` 成死参数，lint 会报。

## 本次不审的部分
仅审 diff 展示的 `api/order.ts` 与 `OrderDetail.tsx` 片段；周边状态机、退款服务、调用方、测试都不在 diff 内。

## 我不自信的点
- 若 `/refund` 服务自身按 orderId 幂等，BLOCKER 2/4 从资金风险降为多余请求 —— 需退款接口文档或代码确认。
- 若确认为单实例部署，缓存的跨副本不一致不成立，但无界增长与失效缺失仍成立。
- 「改动不大」与 diff 内容不符是事实；是否还藏了未展示的改动，无证据可判。
