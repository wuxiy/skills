# 代码 Review

## 评审结论
**不可合并** — 以"优化取消流程"为名删掉了后端鉴权，又叠加了一层无失效的缓存，等于开了越权取消 + 重复退款的窗口；实际改动与提交说明不符。

## BLOCKER（会导致线上事故 / 违反验收标准）

- `api/order.ts` `cancelOrder` — 越权（IDOR）。证据：签名 `cancelOrder(id: string, userId: string)` 的函数体内 **userId 一次未引用**，无归属校验；同时前端删掉了 `canCancel`，注释写明"后端不再校验 userId"。影响：任何人拿到 orderId 即可取消他人订单并触发退款。建议：`if (order.userId !== userId) throw new Forbidden()`，前端 `canCancel` 只做展示，不能当权限来源。
- 缓存无失效 — 证据：`db.order.update` 之后没有 `cache.delete(id)`，`cache` 也无 TTL。影响：取消成功后 `getOrder` 仍返回 `PAID`，二次取消 → 重复 `POST /refund`。建议：写路径后失效缓存；更简单的是本次先不上缓存。
- 退款无幂等、无超时、与状态更新非原子 — 证据：`await fetch(...)` 无 try/catch、无 `AbortSignal`、无幂等键；失败则直接抛出、状态不更新，而退款成功但 `update` 失败则钱已退、单仍是 PAID。建议：以 orderId 作幂等键，先落 `REFUNDING` 再调退款，失败留痕可重试。

## MAJOR（潜在风险，非阻断）

- 状态机不闭合：只判 `PAID`，其余状态一律直落 `CANCELLED`（证据：`if (order.status === 'PAID')` 之外无任何分支），缺合法前驱约束，也无退款流水，账实不符时无从对账。
- `cache.set(id, order)`：`findUnique` 返回 `Order | null`，与 `Map<string, Order>` 不符，且 null 也会被缓存（穿透）。

## MINOR / NIT（可改可不改，不阻断合并）

- `cache.has` + `cache.get` 两次查表，可合并为一次 `const hit = cache.get(id)`；进程内 Map 在多副本下不一致，别当共享缓存用。

## 本次不审的部分
db 层、`Status` 枚举、pay.internal 退款契约、`onCancel` 实现均未提供，跳过，不做无证据推测。

## 我不自信的点
- 未提供验收标准与任何测试，无法判断鉴权、重复取消是否有用例覆盖；即使测试全绿也不构成证据。
- 未见到 Order 模型与状态枚举：若已有 `REFUNDING` 态或 DB 层触发器兜底，MAJOR 第 1 条的严重度需上调。
- 未见到调用方与统一鉴权中间件：若能证明存在上层拦截，BLOCKER 第 1 条可降级（但前端删 `canCancel` 仍是隐患）。
- "编译不过"仅依据 `findUnique` 返回类型的推断，未实际跑类型检查。
