## 重构 Review 报告

**范围**：todo-app 全项目（单提交仓库，`feat: 实现命令行 todo 工具`；src/api.js、src/cli.js、src/store.js、test/test.js，约 230 行）　**模式**：full

**项目约定**：项目内无 CLAUDE.md / AGENTS.md / .claude/rules/（项目未约定），以通用最佳实践 + 用户全局编码规范（不可变性、函数 <50 行、错误处理）为补充依据。

**基线**：`npm test` 12/12 通过（重构前已验证）。

### 发现（按优先级）

| # | 维度 | 位置 | 问题 | 影响 | 建议 | 优先级 |
|---|------|------|------|------|------|--------|
| 1 | 重复逻辑 | api.js `normalizeTitle` + cli.js `normalizeTitle` | 两份逐字相同的归一化实现，注释互相承认（"TODO: cli.js 里好像也有一份" / "与 api.js 中的实现重复"） | 规则改动需双改，必然漂移 | 保留 api.js 一份，cli.js 复用 | P0 |
| 2 | 重复逻辑 | cli.js `handleAdd` vs api.js `validateTitle` | 标题校验规则（非空、≤100 字符）两套并行实现，错误文案各自维护；测试 `cli handleAdd 与 api 校验规则一致` 本身就是在防漂移 | 改一处漏一处 | handleAdd 委托 api.validateTitle，只负责把 error 包装成 `错误：…` 展示文案 | P0 |
| 3 | 重复逻辑+设计 | cli.js `renderList` | 行格式 `[x]/[ ]` × `(!)` 的拼装在 done/todo/all 分支里写了 4 份近乎相同的块；4 层嵌套、40 行只做一件事 | 改行格式要动 4 处；可读性差 | 提取 `formatTodoLine` + `matchesFilter`，嵌套降为 1 层 | P0 |
| 4 | 性能 | store.js `getStats` | 重复标题检测为双重循环 O(n²) × 内层 `indexOf` O(n) = **O(n³)**；1000 条待办约 5×10⁸ 次比较 | 数据增长后 stats 命令显著变慢 | Map/Set 单趟扫描 O(n)，保持原有输出顺序 | P0 |
| 5 | 重复逻辑 | api.js `toggleTodo` + `removeTodo` | "按 id 查找 + 未找到抛错"逻辑与错误文案各写一份 | 双份维护 | 提取 `findTodoOrThrow` | P1 |
| 6 | 设计 | cli.js `formatDateLegacy` | 死代码，注释自认"已经没有地方使用"，未导出无引用 | 误导读者 | 直接删除 | P1 |
| 7 | 设计 | api.js `addTodo`/`toggleTodo`/`removeTodo` | 原地 mutate store 返回的数组/对象（push、splice、`todo.done =`）；用户全局规范要求不可变模式（项目未约定，按全局规范） | 隐式副作用，违反约定 | 构造新数组/新对象后写回，返回值同步为新对象 | P1 |
| 8 | 设计 | cli.js `handleAdd` | 业务校验漏进展示层（与 #2 同根） | 职责错位 | 随 #2 一并修复 | P1 |
| 9 | UI 一致性 | cli.js `renderStats` | 纯 CLI 项目，无图形 UI，本维度整体跳过；唯一疑点：stats 用 `√/×`、列表用 `[x]/[ ]`（NOTE 注释"回头统一"） | 展示风格不一致 | 改文案会改变可观察输出，属行为变更，未经确认不动 | P2 |

### 重构计划（每项对应一个 commit）

1. `refactor(cli): 删除死代码 formatDateLegacy` —— 无引用、注释自证废弃（#6）
2. `refactor(title): 合并重复的标题归一化与校验` —— cli.js 删除重复的 normalizeTitle，handleAdd 委托 api.validateTitle，消除两处校验漂移风险（#1 #2 #8）
3. `refactor(cli): 提取 formatTodoLine/matchesFilter 简化 renderList` —— 4 份重复分支收敛为"过滤 + 格式化"两步，嵌套 4→1 层（#3）
4. `refactor(store): getStats 重复标题检测 O(n³) → O(n)` —— Map 计数单趟扫描，严格保持 duplicateTitles 原有顺序语义（#4）
5. `refactor(api): 提取 findTodoOrThrow 并改用不可变更新` —— toggle/remove 共享查找与错误文案；add/toggle/remove 构造新对象写回（#5 #7）

每个 commit 后跑 `npm test` 验证，失败即停。

### 不动的部分（及原因）

- **`√/×` 与 `[x]/[ ]` 的统一**（#9）：会改变用户可见输出，属行为变更；重构默认行为保持，留待用户确认后单独处理。
- **`main()` 的 if/else 命令分发**：5 个命令的规模不值得引入命令表/路由抽象，当前形式直观。
- **`handleAdd` 未使用的 priority 形参、main 未透传 priority**：属未完成的特性入口（CLI 无 priority 参数），不是重复/缺陷；行为保持，不扩功能。
- **store.js 读写层（readTodos/writeTodos/nextId）**：职责单一、无重复、O(n) 合理。
- **test/test.js**：结构清晰（每用例独立数据文件），不在本次范围。

## 重构完成

**提交**（基线 99c51d7 之上，每个提交后 npm test 均 12/12 通过）：
- `5b72ea9` refactor(cli): 删除无引用的 formatDateLegacy 死代码 —— 清除注释自证废弃的孤立函数
- `592165a` refactor(title): 合并 cli/api 两份重复的标题归一化与校验 —— 删除逐字重复的 normalizeTitle，handleAdd 委托 api.validateTitle
- `8e57dc2` refactor(cli): 提取 formatTodoLine/matchesFilter 简化 renderList —— 4 份重复分支收敛为过滤+格式化，嵌套 4→1 层
- `ef5640b` refactor(store): getStats 重复标题检测 O(n³) 降为 O(n) —— Map 计数单趟扫描，边界用例验证输出顺序不变
- `1c2e173` refactor(api): 提取 findTodoOrThrow 并改用不可变更新 —— toggle/remove 共享查找与错误文案，写操作全部构造新对象

**Before → After**：
- src 行数：223 → 190（+43/−73）；最大文件 cli.js 110 → 68 行
- 重复块：normalizeTitle ×2 → ×1；标题校验 ×2 → ×1；renderList 行格式 ×4 → ×1；id 查找+抛错 ×2 → ×1
- renderList 嵌套深度 4 → 1；getStats 复杂度 O(n³) → O(n)（n=1000 时约 5×10⁸ → 数千次操作量级）
- 清理：死代码 1 处、过时 TODO/NOTE 注释 2 处

**验证**：`npm test` 重构前 12/12 通过（基线），重构后 12/12 通过（最终），每个 commit 后均验证；额外用 [B,A,A,B] 边界用例核对 duplicateTitles 顺序语义不变。工作树干净，fixtures 原项目零改动。

**遗留**（未修项及原因）：
- P2：stats 的 `√/×` 与列表的 `[x]/[ ]` 状态展示统一 —— 改变用户可见输出，属行为变更，需用户确认后单独做
- P2：`handleAdd` 的 priority 形参未被 main 透传 —— 未完成特性入口，非本次范围，保持行为不扩功能
- P2：main 的 if/else 命令分发 —— 5 命令规模不值得引入命令表

**说明**：无人值守环境，按默认选项执行（修 P0+P1 项、`refactor:` 提交前缀、默认 commit 粒度；模式按用户关键词"重复/臃肿/性能"自动识别为 full）。
