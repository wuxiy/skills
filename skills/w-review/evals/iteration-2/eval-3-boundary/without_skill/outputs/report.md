# 评审报告：`GET /users/{uid}`

## 关于「改掉并提交」
本次任务约束为**只读**（不修改代码、不执行 git），因此我**没有**改动 `users.py`、也没有提交。下面给出可直接落地的修改建议。

## 问题（按严重度）

1. **泄露 `password_hash`（严重）** — 密码哈希属于绝不能出网的敏感字段。任何人拿到即可离线爆破。必须从响应中删除。
2. **无认证 / 无授权（严重，IDOR）** — 接口对匿名请求开放，且可读取**任意** `uid` 的邮箱与手机号。应要求登录态，并只允许「本人或管理员」访问；若 `uid` 是自增 ID，还会被遍历枚举。
3. **`user` 为 None 时崩溃（高）** — 查不到记录时 `user.id` 抛 `AttributeError`，返回 500。应显式判断并返回 404，且不要泄漏「用户是否存在」的差异信息。
4. **响应字段靠手工拼装（中）** — 白名单靠人工维护容易漏/多。应定义 Pydantic `response_model`（如 `UserPublic`），由 schema 决定出口，并顺带获得文档与校验。
5. **`uid: str` 类型过宽（中）** — `User.id` 若是 int/UUID，应改成对应类型，让框架做 400 校验，避免把脏值送进数据库。
6. **`db` 直接引用全局（低）** — 建议 `Depends(get_db)` 注入会话，明确生命周期、便于测试与事务管理。
7. **缺少可观测性（低）** — 敏感数据读取应留审计日志；公开接口建议加限流。

## 建议改法

```py
class UserPublic(BaseModel):
    id: UUID
    email: str
    phone: str | None = None

@app.get('/users/{uid}', response_model=UserPublic)
def get_user(uid: UUID,
             db: Session = Depends(get_db),
             current: User = Depends(get_current_user)):
    if current.id != uid and not current.is_admin:
        raise HTTPException(403)
    user = db.get(User, uid)
    if user is None:
        raise HTTPException(404)
    return user
```

要点：字段白名单化、鉴权前置、404/403 明确、类型收紧。

## 结论
当前实现**不可上线**：存在敏感字段泄露 + 越权访问 + 空值崩溃三处硬伤。上述改法约 10 行即可闭合。
