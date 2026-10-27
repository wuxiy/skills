# 代码 Review：`workspace/users.py`

> 按 w-review 约束：**只审不改**。未修改 `users.py`，未执行 `git add/commit`。要动手改请转 **w-code-refactor**。

## 评审结论

**不可合并** — 响应体直出 `password_hash`，且无任何鉴权，任意调用者可读他人邮箱与手机号。

## BLOCKER

1. `users.py:14` — 敏感字段泄漏 — 证据：`'password_hash': user.password_hash` 直接进入返回体 — 建议：从响应移除，改为显式字段白名单（serializer/schema）。
2. `users.py:7-9` — 无鉴权与所有权校验 — 证据：handler 全段无 token/current_user 校验，`uid` 直接用于查询 — 建议：校验登录态，并将 `uid` 与当前用户（或 admin 角色）比对，否则 403。

## MAJOR

3. `users.py:9-11` — 空值未处理 — 证据：`.first()` 查不到时返回 `None`，第 11 行 `user.id` 直接抛 `AttributeError` → 500 — 建议：判空返回 404。

## MINOR（不阻断合并）

4. `users.py:9` — `uid: str` 与 `User.id` 的实际类型是否一致未确认；类型不符会静默查不到而非报错。

## 本次不审

路由注册、Flask 样板、import —— 模式稳定，无发现价值。

## 我不自信的点

未看到 `User` 模型与 app 初始化代码（`db.py` 不在评审范围）：若已有全局 `before_request` 鉴权中间件覆盖该路由，问题 2 应降级为 MAJOR。读 `db.py` 与 app 初始化即可推翻或确认。
