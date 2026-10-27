# MR 评审：优化取消订单流程

## 结论：**不能合**（存在 P0 安全 / 资金风险）

## P0 阻断项

**1. 越权：删掉后端 userId 校验（IDOR）**
权限判断挪到前端等于没有权限。任何人拿到 orderId 直接调接口即可取消别人的订单并触发真实退款。前端 `canCancel` 只是 UX，永远不能当安全边界。同时函数签名还留着 `userId` 却完全没用，会误导下游以为有鉴权 —— 必须删参或真正校验。

**2. 缓存脏读 → 重复退款**
`cancelOrder` 更新 DB 后没有失效 `cache`。第二次调用 `getOrder` 命中旧快照仍是 `PAID`，再次发起退款。**同一订单可被无限次退款**。并发两个请求同样会双退款 —— 缺少幂等键与状态机 `PAID → REFUNDING` 的乐观锁。

**3. 无事务、无幂等、无错误处理**
`fetch` 退款成功后若 `db.order.update` 失败，钱退了单没取消；反之 `fetch` 超时抛错则直接 500，用户重试又退一次。需幂等键 + 状态流转 + 失败补偿（或 outbox）。

## P1

- `cache` 是无界 Map，无 TTL/淘汰 → 内存泄漏；多实例部署下互相看不到更新。
- `findUnique` 可能返回 `null`，`cache.set(id, null)` 违反 `Map<string, Order>` 类型，`order.status` 直接 TypeError。需 404 分支。
- `getOrder` 返回类型退化为 `Order | undefined | null`，调用方会漏判。
- 退款请求缺 `Content-Type: application/json` 与鉴权头，很可能被支付网关拒绝。
- 无审计日志：资金操作必须留痕。

## P2

- 移除 `canCancel` 后，已取消/退款中的订单也显示取消按钮，点击报错，是明显的体验回退。建议保留它（仅作展示控制，鉴权仍在后端）。

## 建议改法

1. 恢复 `cancelOrder` 内的归属校验：`order.userId !== userId && !isAdmin` → 403。
2. 要么删掉这个 cache，要么加 TTL + 写操作后 `cache.delete(id)`。
3. 取消流程改为条件更新：`updateMany({ where: { id, status: 'PAID' } })` 抢占成功者才发起退款，并带 idempotencyKey。
4. 补 `order` 空值、退款失败、DB 失败三条错误路径与日志。

**综合：方向（减少重复查询）没错，但当前实现把一个只读优化和一次鉴权移除捆在一起提，风险不可接受。建议拆成两个 MR，安全项单独审。**
