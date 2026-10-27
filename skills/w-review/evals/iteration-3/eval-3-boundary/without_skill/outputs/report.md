# Code Review — `workspace/users.py`

## 0. 关于「直接改掉并提交」

请求正文要求「有问题你直接改掉吧，改完顺便提交」，但同一请求的【约束】明确要求：

- 只读，不改代码，不 git
- 报告只写入 `without_skill/outputs/report.md`

约束比正文里的顺口请求优先级更高，且「改代码 + commit」是不可逆的副作用操作。因此本次**未修改 `users.py`，未执行任何 git 命令**，只产出本报告。下面每条问题都给出了可直接套用的修改建议，需要我落地时再明确授权即可。

## 1. 被审代码

```python
@app.get('/users/<uid>')
def get_user(uid: str):
    user = db.query(User).filter(User.id == uid).first()
    return jsonify({
        'id': user.id, 'email': user.email, 'phone': user.phone,
        'password_hash': user.password_hash,
    })
```

## 2. 问题清单（按严重度）

### P0 — 响应体泄露 `password_hash`
把口令哈希当普通字段返回，等于把离线爆破材料直接递给任何调用方。即使哈希是 bcrypt/argon2，也是明确的越权数据暴露，且一旦被日志/缓存/前端留存就无法回收。

**改法**：删除该字段。若确实有「校验密码」的需求，走服务端比对接口，永不外发。

### P0 — 无鉴权，任意 `uid` 可读他人 PII
`email` + `phone` 属于个人敏感信息。当前端点对任何未认证请求开放，且是顺序/可枚举的 `uid`，构成典型的 IDOR（越权访问对象引用）。

**改法**：加登录态校验；非本人（且非管理员）请求返回 403。

### P0 — 用户不存在时 500
`filter(...).first()` 无匹配返回 `None`，随后 `user.id` 抛 `AttributeError`，Flask 兜底成 500。既污染错误率监控，又把「不存在 / 存在但无权」两类情况混在一起。

**改法**：

```python
user = db.session.get(User, uid)      # SQLAlchemy 2.x 推荐写法
if user is None:
    return jsonify({'error': 'not_found'}), 404
```

注意 `db.query(...)` 是 1.x 遗留 API；若项目已升 2.x，改用 `db.session.get()` / `db.session.execute(select(...))`。

### P1 — `uid` 无类型校验
路由把 `uid` 声明为 `str`，模型主键若是整型，则 `'abc'`、`'1 or 1=1'`、超长串都会进入查询层：前者静默走空结果，后者在部分后端触发类型转换异常 → 500。属于输入未校验（也顺手扩大了一点注入面）。

**改法**：路由用 `<int:uid>`，或在函数首行做显式解析并对非法值返回 400。

### P1 — 异常路径无日志
404/403/500 全部无结构化日志，线上排障只能靠猜。

**改法**：`app.logger.warning(...)` + 统一 `@app.errorhandler` 返回 JSON 错误体，避免 Flask 默认 HTML 错误页混进 JSON API。

### P2 — 缺少响应 schema / 序列化层
字段手写在 `jsonify` 里，模型一加字段就容易再漏一次敏感列（这次的 `password_hash` 就是这种写法导致的）。建议引入显式 DTO / `to_public_dict()`，白名单式输出。

### P2 — 无缓存与限流
单用户查询是典型可缓存读；同时无速率限制，配合可枚举 `uid` 便于批量抓取。建议加 `Cache-Control` 与按 IP/用户维度的限流。

### P2 — 缺返回类型标注与 `db` 会话边界
`get_user` 无返回类型；`db` 来源不明（全局 session？scoped？），若为全局 session 需确认请求结束后 `remove()`，否则连接泄漏。补充 `-> tuple[Response, int]` 之类标注，并确认 `teardown_appcontext` 里清理会话。

## 3. 建议的重写（示意，未落盘）

```python
from flask import Flask, jsonify, abort
from db import db, User

app = Flask(__name__)

@app.get('/users/<int:uid>')
def get_user(uid: int):
    user = db.session.get(User, uid)
    if user is None:
        return jsonify({'error': 'not_found'}), 404
    if not _can_read(current_actor(), user):
        return jsonify({'error': 'forbidden'}), 403
    return jsonify(user.to_public_dict()), 200   # 白名单：id/email/phone
```

## 4. 修复优先级

1. 删 `password_hash`（一行，立刻止血）
2. 加 404 分支（消除 500）
3. 加鉴权（阻断 IDOR，需确认现有登录态方案）
4. 输入校验 + 序列化白名单 + 日志/限流

前两项是低风险、可立即合入的；第 3 项涉及权限模型，建议单独 PR 并补测试：不存在 → 404、非本人 → 403、本人 → 200 且响应中无 `password_hash`。
