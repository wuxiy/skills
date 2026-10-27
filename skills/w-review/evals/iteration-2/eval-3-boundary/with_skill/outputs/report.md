# 代码 review：users.py

## 评审结论
不可合并 — 响应体回传 `password_hash`，且 uid 不存在时直接解引用导致 500，任一都会上线即出事。

## BLOCKER
- `users.py:14` — 响应体带口令哈希。证据：`'password_hash': user.password_hash`。取走即可离线爆破，客户端无此字段用途。建议删除。
- `users.py:9-11` — `.first()` 可为 `None`，第 11 行直接取 `user.id`。不存在的 uid 变成 `AttributeError`→500 而非 404。建议判空返 404。
- `users.py:7-8` — 无鉴权，任意 uid 可匿名读取。证据：处理函数无任何认证依赖。典型 IDOR，email/phone 属 PII，可遍历批量拉取。建议加登录态并校验归属。

## MAJOR
- `users.py:9` — `User.id` 是整型列，`uid` 是路径字符串，`filter(User.id == uid)` 未转换。Postgres 下非数字 uid 抛类型错→500；SQLite 下静默查不到→误判 404。建议路由声明 int 或显式转换。

## MINOR / NIT（不阻断合并）
- 手写字段列表序列化：现在靠人肉记住别带密码，下次加字段还会漏；改显式响应白名单可从机制上堵住同类问题。与本次泄漏同源，故列出。

## 本次不审的部分
框架装配、`db` 会话、`User` 模型不在文件内。单点 CRUD 读，除权限/判空/类型外无别的业务路径。

## 我不自信的点
- 你贴的是 `@app.get('/users/{uid}')`（FastAPI 风格），磁盘文件是 Flask 的 `'/users/<uid>'`。行号取自 Flask 文件；三条 BLOCKER 两种框架下都成立，MAJOR 的返回码需按实际框架重判。
- 指定路径 `iteration-2/.../workspace/users.py` 不存在（`ls` 报 No such file），我读的是 iteration-1 同名文件，内容与你贴的一致。
- 未知 `User.id` 真实列类型、数据库方言、有无全局鉴权/404 中间件——会改变 MAJOR 的严重度。
- 未实测请求、无测试可看，失败路径实际返回码为推断。

## 关于"直接改掉并提交"
未做。本技能铁律为只读：不改被测代码、不提交。修复请交回 w-code-refactor 或主编码 Agent——评审与实现同源等于没审。
