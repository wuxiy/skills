# todo-app 代码 Review 与重构报告

- 评审对象：`fixtures/todo-app`（只读参考），所有修改在完整复制的 `outputs/work/` 中进行并逐条 git 提交
- 验证方式：改动前后均在 `outputs/work/` 运行 `npm test`（零依赖，等价 `node test/test.js`）
- 结果：**测试 12 → 25 个，全部通过**；stats 统计性能提升约 **100~300 倍**

## 一、Review 发现的问题

### 1. 重复逻辑（高）

| 问题 | 位置 | 风险 |
|---|---|---|
| `normalizeTitle` 在 cli.js 与 api.js 各有一份（代码注释自己也承认） | `cli.js:7`、`api.js:7` | 规则漂移：两处校验标准可能不一致 |
| `handleAdd` 手写一套空标题/长度校验，api 层 `validateTitle` 又有一套 | `cli.js:74-84` | 同一规则两处维护 |
| `renderList` 把「filter × 完成状态 × 优先级」展开成 4 段几乎相同的 if/else 格式化代码 | `cli.js:20-59` | 改一个格式要同步改 4 处 |

### 2. 死代码与半成品功能（中）

- `formatDateLegacy` 无任何引用（死代码）。
- `api.removeTodo` 已实现且有测试，但 **没有 CLI 命令入口**。
- 优先级功能半接线：api 支持 `priority='high'`、渲染层支持 `(!)` 标记，但 `add` 命令永远不传 priority，用户无法设置。

### 3. 设计问题（高）

- **损坏文件被静默吞掉**：`readTodos` 对任何读取/解析异常都返回 `[]`。数据文件损坏后，下一次 `add` 会用新数据直接覆盖旧文件——**静默数据丢失**（已实测复现）。
- **写入非原子**：直接 `writeFileSync` 覆盖数据文件，进程中途崩溃会留下半截 JSON，而半截 JSON 又会被上一条静默吞掉。
- **api 层原地修改数据**：`todos.push` / `splice` / `todo.done = !todo.done`，存在隐式副作用，返回值与入参共享引用。
- **cli 混用两层**：读操作走 store、写操作走 api，分层不一致。
- **无错误处理**：`done abc` → `Number('abc')=NaN` → 抛出未捕获异常，用户看到整段堆栈；所有错误退出码都是 0。
- **无输入校验**：`done`/`remove` 不校验 id；`list foo` 等未知过滤条件被静默当作 `all`。
- `done` 命令实际是 toggle，但提示语永远是「已完成」——把已完成项再 `done` 一次，提示与事实相反。

### 4. UI 一致性（中）

- `list` 用 `[x]`/`[ ]`，`stats` 却用 `√`/`×`（代码里已有 NOTE 待办）。
- 错误输出没有统一格式，也没有 stdout/stderr、退出码约定。
- 用法说明硬编码在 main 里，与新增能力脱节。

### 5. 性能瓶颈（高）

`getStats` 的重复标题检测是双重循环两两比较，**O(n²)**。实测基准（getStats 本身耗时，约 1/5 标题重复）：

| 数据量 | 重构前 | 重构后 | 提升 |
|---|---|---|---|
| 20,000 条 | 898 ms | 9 ms | ~100x |
| 60,000 条 | 7,351 ms | 24 ms | ~300x |

其余路径（add/toggle/search）都是单遍 O(n)，无瓶颈；每条命令只读一次文件，无冗余 IO。

## 二、重构内容（按提交）

1. **`refactor: 消除重复逻辑与死代码`** — 删除 cli 侧重复的 `normalizeTitle` 与死代码 `formatDateLegacy`；`handleAdd` 完全复用 `api.validateTitle`，校验只剩一套标准；`renderList` 的 4 段重复分支拆为单职责的 `matchesFilter` + `formatTodo`。
2. **`refactor: 数据层健壮性`** — `readTodos` 区分「文件不存在（返回空）」与「文件损坏（抛带路径的明确错误）」，并校验数据结构；`writeTodos` 校验入参并改为 tmp 文件 + rename 原子落盘。
3. **`perf: getStats O(n²) → O(n)`** — 单遍遍历 + Map 计数；Map 按首次出现顺序迭代，重复标题输出顺序与旧实现完全一致（有测试锁定）。
4. **`refactor: api 层不可变更新 + 查询门面`** — add/toggle/remove 改用 map/filter/展开生成新数据，返回对象 `Object.freeze`；新增 `listTodos` 并委托 `searchTodos`/`getStats`，cli 从此只依赖 api 一层。
5. **`refactor: cli 命令分发重构`** — 抽出纯函数 `dispatch(argv)`（返回文本、错误用异常），与 console/退出码解耦、可测试；所有错误统一走 stderr + 退出码 1；id 校验为正整数、过滤条件白名单校验；`done` 提示语反映真实状态（已完成/已取消完成）；补齐 `remove` 命令与 `add --high`（未知 flag 报错）；stats 改用与列表一致的 `[x]`/`[ ]` 标记并新增完成率。
6. **`test: 用例 12 → 25`** — 覆盖高优先级渲染、stats 统一标记、`--high`/未知参数、id/过滤条件校验、done 状态提示、remove 命令、未知命令、损坏文件快速失败、重复标题顺序一致性。
7. **`docs: README 更新`** — 同步命令列表、数据文件位置与错误处理约定。

## 三、取舍说明（无人值守，按工程判断决策）

- **`handleAdd` 保持返回字符串的既有契约**（现有测试直接断言其返回值），退出码由 `main` 依据统一的 `错误：` 前缀判定，避免破坏公开接口。
- **补齐 `remove` 命令与 `--high` 视为「接线已有半成品」而非新功能**：api/渲染层早已实现，仅缺命令入口，补齐后消除不可达代码；未引入任何超出原设计范围的能力。
- **id 沿用「最大 id + 1」**：删除最大 id 后新条目会复用该号，对单机 CLI 可接受；引入持久化计数器收益不成比例，仅在报告中记录。
- **未加文件锁**：多进程并发读写竞态超出 CLI 单用户场景，原子 rename 已覆盖最主要的损坏场景。
- **stats 增加「完成率」行**：属于低风险展示增强；原测试只断言前缀，兼容。
- **`search` 空关键词返回全部**：保留原行为，未收紧。

## 四、测试结果

- 改动前（原始代码）：`npm test` → **12 passed**
- 改动后（outputs/work）：`npm test` → **25 passed**（0 失败）
- `node test/test.js` 直跑结果一致。

## 五、Git 提交列表（outputs/work）

```
c40c8c6 docs: README 更新命令列表（remove/--high）、数据文件与错误处理说明
520f1ad test: 为错误路径与新行为补充 13 个用例（12 -> 25）
c92d48e refactor: cli 命令分发重构——错误处理、参数校验与 UI 一致性
ab22948 refactor: api 层改为不可变更新，并补齐查询门面
48107e7 perf: 统计重复标题由 O(n²) 双循环优化为 O(n) 单遍 Map 计数
6c29cd3 refactor: 数据层健壮性——损坏文件快速失败与原子写入
51e6325 refactor: 消除重复逻辑与死代码
99c51d7 feat: 实现命令行 todo 工具
```
