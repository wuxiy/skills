# todo-app 重构报告

## 重构 Review 报告

**范围**：全仓库（`src/store.js`、`src/api.js`、`src/cli.js`，共 220 行；单一提交 `99c51d7 feat: 实现命令行 todo 工具`，无增量 diff 可圈定，故全量 review）
**模式**：full（用户提到"重复 / 函数臃肿 / 性能问题"）
**项目约定**：项目内无 CLAUDE.md/AGENTS.md，无 EXTEND.md 偏好文件——涉及风格判断处按全局编码规范处理，并在下文标注"项目未约定"。

### 发现（按优先级）

| # | 维度 | 位置 | 问题 | 影响 | 建议 | 优先级 |
|---|------|------|------|------|------|--------|
| 1 | 重复逻辑 | api.js:7 vs cli.js:7 | normalizeTitle 逐字重复两份，两处注释均自认（"TODO: cli.js 里好像也有一份" / "与 api.js 中的实现重复"） | 改归一化规则要动两处，必然漂移 | 合并到 api 层，cli 复用 | P0 |
| 2 | 重复逻辑 | api.validateTitle vs cli.handleAdd | 空标题/超长(100)校验规则各写一遍，仅错误文案差"错误："前缀 | 规则漂移风险；"cli 与 api 校验一致"靠人肉保证 | handleAdd 委托 api.validateTitle，只保留展示层包装 | P0 |
| 3 | 设计 | cli.renderList（40 行） | 过滤×状态×优先级组合被逐分支复制 4 遍，同一格式串出现 8 次，嵌套深达 5 层 | 加一种 filter 或改格式要动 4-8 处 | 过滤与格式化解耦：filter + 提取 formatTodo | P0 |
| 4 | 设计（死代码） | cli.formatDateLegacy | 无调用方、未导出，注释自述"已经没有地方使用" | 误导读者 | 删除 | P0 |
| 5 | 性能 | store.getStats | 双重循环两两比较标题（n²/2 次比较），命中后再 indexOf 查重——最坏 O(n³)。n=1000 时约 50 万次比较，全同名时每次命中还要线性扫 duplicateTitles | 数据量上千后 stats 明显变慢 | Map 计数单遍 O(n) | P0 |
| 6 | 设计 | api.addTodo/toggleTodo/removeTodo | push/splice/原地翻转 done，原地 mutate（项目未约定，按全局规范业务层宜不可变） | 隐式副作用，不利于后续扩展/调试 | 改 spread/map/filter 不可变更新 | P1 |
| 7 | 输出一致性 | cli.renderStats | √/× 与列表的 [x]/[ ] 标记不一致（原注释"回头统一"） | 观感不统一 | 不改（见"不动的部分"） | P2 |
| 8 | 健壮性 | store.readTodos | JSON 解析失败静默返回 []，吞掉文件损坏信号；也不校验解析结果是否为数组 | 数据损坏被掩盖 | 不改（见"不动的部分"） | P2 |
| 9 | CLI | cli.main | done <非法 id> 等业务异常未捕获，直接打印堆栈 | 用户体验差 | 不改（见"不动的部分"） | P2 |
| 10 | 设计 | 'high'/'normal' 魔法字符串 | 分散在 api 与 cli 两处 | 有限 | 不改（见"不动的部分"） | P2 |

### 重构计划（每项对应一个 commit）

1. 删除死代码 formatDateLegacy（#4）
2. 合并重复的 normalizeTitle + 校验收敛到 api 层（#1 #2）
3. renderList 简化为 filter + formatTodo（#3）
4. getStats O(n²)→O(n)（#5）
5. api 层不可变更新（#6）

### 不动的部分（及原因）

- **#7 √/× 与 [x]/[ ] 统一**：会改变 CLI 输出文本，属外部可观察行为。重构底线是行为保持，原注释虽有意愿但无用户确认，记录在案不擅自改。
- **#8 readTodos 吞解析错误**：改成抛错会改变行为（损坏文件时从"当作空列表"变为"命令报错"），且无测试覆盖该路径。属潜在 bug 而非重构项，单列给作者决定。
- **#9 main 不捕获异常**：加 try/catch 会改变 stderr 输出内容，同属行为变更，不在本次范围。
- **#10 优先级魔法字符串**：仅 2 处、语义清晰，提取常量收益低于改动成本（"宁可标记两次重复观察第三次"）。
- **cli add 不支持 priority 参数**（api 层已有该参数但 CLI 未暴露）：功能缺口不是重构问题，不在范围。
- **测试文件**：测试本身职责清晰（每用例独立数据文件），不动。

---

## 重构完成

**提交**（每个 commit 后均通过 npm test）：

```
b466829 refactor(api): 增删改用不可变更新替代原地修改
01c4232 refactor(store): getStats 重复标题检测从 O(n²) 优化为单遍 O(n)
98d1507 refactor(cli): renderList 由 40 行 5 层嵌套简化为 filter+format
5cfa49a refactor(api,cli): 合并两处重复的标题归一化与校验逻辑
ff14034 refactor(cli): 删除无调用方的 formatDateLegacy 死代码
99c51d7 feat: 实现命令行 todo 工具（原基线）
```

**Before → After**：

| 指标 | Before | After |
|------|--------|-------|
| src 总行数 | 220（api 55 / cli 109 / store 56） | 179（api 52 / cli 67 / store 60），净 -41 |
| diff | — | +36 / -77 |
| 重复块 | 2 处（normalizeTitle、校验规则） | 0 |
| renderList | 40 行、5 层嵌套、格式串复制 8 份 | filter+formatTodo 共 16 行、最深 2 层 |
| getStats 复杂度 | O(n²)、最坏 O(n³) | O(n)，单遍计数 |
| 死代码 | formatDateLegacy | 已删除 |

**验证**：

- 基线：改动前 npm test 12/12 通过
- 过程：每个 commit 后 npm test 均 12/12 通过
- 终态：npm test **12 passed**，0 失败
- 附加端到端冒烟：add（含空白归一化）/done/list [all|done|todo]/stats/search/空列表 全部手工验证，输出与重构前逐字符一致
- 只读参考目录 fixtures/todo-app 确认 git 状态干净、未被修改

**遗留**（P2，未修，理由见上）：

- renderStats 的 √/× 与列表 [x]/[ ] 标记不统一（行为变更，待确认）
- readTodos 吞 JSON 解析错误、不校验数组类型（潜在 bug，待确认）
- main 未捕获业务异常（行为变更，待确认）
- 'high'/'normal' 魔法字符串（收益低）

---

## 无人值守决策说明

1. **模式判定**：用户原话含"重复/臃肿/性能"，判为 full 模式；无"补丁/几轮修改"字样，不走 cleanup。
2. **计划确认**：技能流程要求确认修哪些项，评测环境无交互，按默认执行 P0+P1 全部 5 项；P2 一律不动并记录。
3. **行为保持底线**：凡会改变 CLI 输出/错误表现/异常语义的项（√/× 统一、吞错、main 捕获）一律不碰，仅报告。
4. **不可变化**：项目无约定，按用户全局编码规范对业务层（api）采用不可变更新；store 层读写文件属 I/O 边界，保持原模式。
5. **commit 粒度**：一个逻辑重构一个 commit，refactor(scope): 前缀，消息写明动机，逐步验证。
