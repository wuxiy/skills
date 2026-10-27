# MR Review：取消订单流程"优化"

**结论：不能合。打回（Request changes）。**

这次改动表面是"优化取消流程"，实际做了一次**鉴权下沉到前端**的安全降级，并引入**重复退款**的资金风险。三处 P0 必须先修。

---

## P0 — 阻断级

### 1. 越权（IDOR）：后端不再校验 userId

```ts
export async function cancelOrder(id: string, userId: string) {  // userId 已成死参数
```

权限判断被移到 `OrderDetail.tsx`，后端完全信任前端。任何人构造 `cancelOrder(任意订单id, 自己的id)` 就能取消别人的订单，并触发真实退款。前端校验不是校验——它只是 UI 提示，攻击者根本不经过它。

`getOrder(id)` 同样没有 `userId` 归属校验，读接口一起漏。这是安全回归，不是优化。

### 2. 重复退款（TOCTOU 竞态）

```ts
const order = await getOrder(id);          // 读到 PAID
if (order.status === 'PAID') { await fetch(refund) }   // 中间无原子性
await db.order.update({ ... status: 'CANCELLED' })
```

"读状态 → 判状态 → 退款"三步不原子。两个并发请求都能读到 `PAID`，都会调用退款接口。前端按钮又没有 disabled（见 P2），用户双击就能复现。

必须改成条件更新抢占状态：先 `updateMany({ where: { id, status: 'PAID' }, data: { status: 'CANCELLING' } })`，`count === 1` 才继续退款。

### 3. 退款结果未校验，无幂等、无补偿

- `await fetch(...)` **对 4xx/5xx 不抛异常**。退款失败会静默通过，订单照样被改成 `CANCELLED`——钱没退，单已取消。
- 反向：退款成功、`db.order.update` 失败 → 钱退了，单还是 `PAID`，用户可再取消一次。
- 无幂等键、无超时、无重试、无补偿任务。支付类调用这三样至少要有两样。

---

## P1 — 高

### 4. 缓存永不失效

`cancelOrder` 改完状态**没有清缓存**，`getOrder` 仍返回旧的 `PAID`。且模块级 `Map` 在多实例/Serverless 下各自一份，跨实例直接读到脏数据。`Map` 无上限、无 TTL、无淘汰策略，长期运行就是内存泄漏。

### 5. null 被缓存

`findUnique` 可能返回 `null`，会被 `cache.set` 写进去并长期命中（负缓存无过期）。同时 `cache.get` 返回 `Order | undefined`，与函数返回类型不符，类型是假的。

### 6. 缺状态机校验

不校验当前状态就直写 `CANCELLED`：已 `CANCELLED`/`REFUNDED`/`PENDING` 的订单都能被再次"取消"。也没有任何审计日志——出资金问题无法追溯。

---

## P2 — 中

- 前端改成无条件渲染 `<CancelButton />`，`canCancel` 被删 → 已取消订单仍显示取消按钮，无 disabled / loading 态，放大了上面的并发问题。正确做法是让服务端返回"能力位"，前端只负责展示。
- `fetch` 缺 `Content-Type: application/json`，内部支付网关很可能直接 415。
- 死参数 `userId` 留在签名里，注释还写"后端不再校验"——后人会以为这是有意设计，掩盖了回归。

---

## 需要作者补充回答

1. 权限下沉到前端，是产品决策还是临时绕过？网关/网关层有没有兜底？
2. 退款接口本身是否幂等？失败补偿谁来做？
3. 这个缓存是性能必需还是顺手加的？如果是必需，失效策略和容量上限是什么？
4. **MR 描述与改动不匹配**：写的是"改动不大，优化取消流程"，实际移除了鉴权、改了退款路径。这种改动需要单独的风险评估和回滚方案，不能夹在"小优化"里过。

---

## 最小可合条件

1. 恢复后端鉴权（`order.userId === userId` 或走策略层），`getOrder` 同步加归属校验。
2. 用原子条件更新抢占状态，抢占成功才发起退款。
3. 退款加幂等键 + 响应码校验 + 超时，失败回滚状态并告警。
4. 写入/更新后失效缓存；或直接去掉这个缓存。
5. 前端保留 `canCancel`（来自服务端），按钮加 disabled。
6. 补测试：越权取消、并发双取消只退一次款、退款失败时不改状态。

---

## 值得肯定的

把"取消"拆成"退款 + 状态变更"两步、意识到 `PAID` 才需要退款——方向是对的，问题出在顺序、原子性和信任边界上。
