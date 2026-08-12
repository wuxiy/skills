# 重构 Review 报告

**范围**：todo-app 全量（唯一提交 `99c51d7 feat: 实现命令行 todo 工具`；src/api.js 55 行、src/cli.js 109 行、src/store.js 56 行、test/test.js 128 行）
**模式**：full（重复逻辑 / 设计 / UI 一致性 / 性能 四维度并行 review 后汇总去重）

**项目约定（Step 0）**：项目内无 CLAUDE.md / AGENTS.md / `.claude/rules/`，也未找到 EXTEND.md 偏好文件。依据顺序：用户全局编码约定（不可变优先、不静默吞错、输入边界校验、小文件）→ 代码库既有模式 → 通用最佳实践（项目未约定处已标注）。

**基线**：`npm test` 12/12 通过；并已抓取重构前 CLI 行为快照（add/done/list 各 filter/stats/search/用法输出）用于逐条对比。

## 发现（按优先级）

| # | 维度 | 位置 | 问题 | 影响 | 建议 | 优先级 |
|---|------|------|------|------|------|--------|
| 1 | 重复 | api.js:7-11 / cli.js:7-11 | `normalizeTitle` 逐字复制两份，两处注释均已自认（"回头合并"/"与 api.js 重复"） | 同一归一化规则必然一起演化，改一处漏一处即行为分裂；api 已导出该函数，副本零存在理由 | 删 cli 副本，统一用 api 的实现 | **P0** |
| 2 | 重复 | api.js:14-19 / cli.js:74-84 | 标题校验两套并行实现：空检查、100 上限、错误文案各写一遍，且成功路径双重执行（handleAdd 校验后 addTodo 内再校验） | 规则漂移只是时间问题——test.js:49 专门用测试"焊"两处一致性，恰是证据 | handleAdd 委托 `api.validateTitle`，只做 `错误：` 前缀转换 | **P0** |
| 3 | 重复+设计 | cli.js:20-59 | renderList 把"勾选框+高优先级标记+标题"格式化块复制 4 份，嵌套 4 层（for>filter>done>priority），~40 行仅 ~3 行信息量 | 任何展示调整要同步改 4 处，漏改即 UI 不一致；全项目最大重复块 | 拆 `formatTodoLine` + `matchesFilter`，filter→谓词 | **P0** |
| 4 | 性能 | store.js:36-45 | getStats 重复标题检测：Θ(n²) 配对循环内再叠 `indexOf` 线性扫，最坏字符级工作量 ≈ n²·L/2（L=100） | 有据：n=1,000 约 50 万次配对比较；n=10,000 约 5×10⁹ 字符比较（秒级）；数据文件只增不删时 stats 明显卡顿 | Map 计数单遍 O(n)；Map 插入序=首次出现顺序，`duplicateTitles` 顺序语义完全等价 | **P0** |
| 5 | 设计 | cli.js:13-17 | 死代码 `formatDateLegacy`，注释自认"已经没有地方使用"，确无调用方、未导出 | 误导后续读者 | 直接删除（版本控制会记得） | P1 |
| 6 | 设计 | store.js:34-54 / cli.js:91,96,98 | 职责错位：`getStats`（纯计算）、`searchTodos`（查询业务）放在数据层；CLI main 绕过 api 直调 store，分层被打穿 | api 层形同虚设，将来换存储/加逻辑无统一入口 | getStats/searchTodos 上移 api.js，main 一律走 api；store 只留读写+nextId | P1 |
| 7 | 设计 | store.js:23-27 | `writeTodos` 直接 `writeFileSync` 覆盖，写入中断会留半截 JSON（与 #10 构成数据丢失链） | 数据文件完整性无保障 | 写同目录临时文件后 `renameSync` 原子替换（成功路径行为完全等价，纯加固） | P1 |
| 8 | 设计 | api.js:21-53 | 三个写操作对读出的数组原地 mutate（push/splice/todo.done=），违反用户全局约定的不可变模式 | 隐式副作用风险；与用户全局编码约定不符 | 改为返回新数组/新对象（`[...todos, todo]`、`map`、`filter`），行为不变 | P1 |
| 9 | UI | cli.js:62-67 vs 26-50 | 状态符号两套体系：stats 用 `√`/`×`，list/search 用 `[x]`/`[ ]`；cli.js:62 注释自认"回头统一" | 同一语义两种符号，用户需心智换算；最显眼的输出不一致 | 对齐主导模式 `[x]`/`[ ]`：stats 计数行已按"已完成/未完成"分类，删除行尾冗余 `√`/`×`（用户明确要求 UI 一致性，属授权变更；测试断言只锁前缀不锁符号） | P1 |
| 10 | 设计 | store.js:15-20 | ⚠️行为变更：`catch { return [] }` 静默吞掉 JSON 解析失败；数据文件损坏时显示空列表，下一次 add/done 会基于空数组覆盖原数据——静默数据丢失 | 高影响但修复改变可观察行为（损坏时从"空列表"变"报错"） | 区分 ENOENT 与解析失败，损坏时抛错由 CLI 提示。**需用户确认** | P0*（暂缓） |
| 11 | 设计+UI | cli.js:86-103 | ⚠️行为变更：main 无异常兜底，`done 999`/`done abc`/`done`（NaN）直接抛堆栈给用户；id 无正整数校验，与 add 的友好错误模式割裂 | 错误体验割裂、输入边界未设防 | 入口 try/catch 输出 `错误：<msg>` + 退出码 1；校验正整数 id。**需确认** | P1*（暂缓） |
| 12 | 设计+UI | api.js:46-53 / cli.js | ⚠️行为变更：`removeTodo` 已实现且有测试，但 CLI 未暴露 remove 命令，用户用不到 | 增删改查缺"删" | 补 `remove <id>` 命令+用法文本。**需确认** | P1*（暂缓） |
| 13 | UI | cli.js:92-94 + api.js:37-44 | ⚠️行为变更：api 是 toggle 翻转，CLI 恒打印"已完成"，二次执行实际取消完成但输出仍称已完成 | 输出误导 | 按翻转后状态输出文案。**需确认** | P1*（暂缓） |
| 14 | UI | cli.js:26-50 | ⚠️行为变更：列表行不带 `#id`，而 `done <id>` 必须用 id，核心流程 list→done 断链 | 用户被迫数行号 | 列表行加 `#id`。**需确认** | P1*（暂缓） |
| 15 | 设计 | cli.js:89 / api.js:28 | ⚠️行为变更：priority 半死功能——CLI 永不传参，`(!)` 展示不可达；无效 priority 静默降级 normal | 能力与展示脱节 | 补 `--high` 参数或砍掉 priority。**需确认方向** | P1*（暂缓） |
| 16 | 设计 | cli.js:74-103 | ⚠️行为变更：错误走 stdout、退出码恒 0，脚本调用方无法感知失败 | 集成不友好 | 错误走 stderr + exitCode=1。**需确认** | P2*（暂缓） |
| 17 | 设计+UI | cli.js:91,97-99 | ⚠️行为变更：非法 filter 静默按 all；search 空关键词静默返回全部（usage 声称必填） | 拼错无提示 | fail-fast 报错。**需确认** | P2*（暂缓） |
| 18 | 设计 | store.js:29-31 | ⚠️行为变更：nextId=max+1，删最大 id 后会复用旧 id | 用户困惑（低危） | 持久化计数器成本高，先记录为已知行为 | P2*（暂缓） |
| 19 | 重复 | api.js:37-53 | toggle/remove 共享"按 id 查找+同一报错文案"骨架（2 处） | 文案会一起演化，但主体逻辑不同 | 按"两次重复观察第三次"原则暂不提取 | P2（不动） |
| 20 | 重复 | api.js:24-51 | read-改-write 三明治 ×3 | 将来加原子写/锁要改三遍 | 可提 `updateTodos(fn)`，当前每处仅 2 行样板，观察一轮 | P2（不动） |
| 21 | 性能 | store.js:14 | existsSync 与 try/catch 冗余（多一次 stat syscall，µs 级） | 无感 | 不动 | P2（不动） |
| 22 | 性能 | store.js:25 | 每次写前 mkdirSync(recursive)（每进程 1 次，µs 级） | 无感 | 不动 | P2（不动） |
| 23 | UI | cli.js:77,80 vs 65-67 | 冒号全角/半角混用（`错误：` vs `总计: `），且两种写法都被测试断言锁死 | 纯排版 | 统一需同步改测试断言，收益低，不动 | P2（不动） |
| 24 | UI | cli.js:69 | 重复标题行用半角 `, ` 拼中文标题 | 纯观感 | 不动 | P2（不动） |

\* 标注"暂缓"的条目：修复会改变外部可观察行为或属于新功能。按技能底线 1（行为保持），此类项需单独列出让用户拍板，不混进重构提交——无人值守环境下无法确认，故全部移入"不动的部分"。

## 重构计划（每项对应一个 commit，默认修 P0+P1、`refactor:` 前缀、默认粒度）

1. `test: 补充行为锚点回归用例`——动代码前先锁定两处易被重构波及的现行语义：重复标题按**首次出现顺序**输出（`[A,B,B,A]→['任务A','任务B']`，防朴素重写改序）、renderList 四种行格式的精确输出。
2. `refactor: 合并 normalizeTitle 与标题校验，消除 cli/api 双份实现`（#1 #2）——cli 删副本，handleAdd 委托 `api.validateTitle`；收窄导出，魔法数 100 与错误文案只剩一份。
3. `refactor: renderList 去重，收敛为过滤谓词+统一行格式化`（#3）——40 行→约 12 行，嵌套 4 层→1 层；保留"未知 filter 按 all"的现行宽容行为。
4. `refactor: 删除死代码 formatDateLegacy`（#5）。
5. `refactor: getStats/searchTodos 上移至 api 层，CLI 统一走 api 入口`（#6）——store 收敛为纯读写；同步调整测试的调用指向（断言不变）。
6. `refactor: api 层写操作改为不可变更新`（#8）——add/toggle/remove 一律产出新数组/新对象。
7. `refactor: 统计重复标题检测优化为 O(n) 单遍`（#4）——Map 计数（插入序=首次出现顺序），`done` 计数并入同一遍；输出含顺序逐字等价。
8. `refactor: 统一状态展示，stats 移除与列表不一致的 √/× 符号`（#9，用户明确要求的 UI 一致性项）。
9. `refactor: 数据写入改为临时文件+原子替换`（#7）——成功路径零行为差异的纯加固。

每个 commit 后跑 `npm test`；全部完成后重放 CLI 行为快照逐条对比。

## 不动的部分（及原因）

- **发现 #10（损坏 JSON 静默吞错，P0 风险）**：最有价值的遗留项，但修复会把"损坏时显示空列表"变为"报错"，属行为变更，需用户拍板。已单独列出，不与重构混提。
- **发现 #11-#17（CLI 错误兜底/id 校验、remove 命令、toggle 文案、列表加 #id、priority 打通、退出码、filter/search 校验）**：均为行为变更或新功能，无人值守无法确认，全部暂缓并记录在案。
- **发现 #18（nextId 复用）**：修复需持久化计数器，成本/收益不划算，记录为已知行为。
- **发现 #19 #20（两处重复骨架）**：按"两次重复观察第三次"原则刻意不合并，避免造出别扭抽象。
- **发现 #21 #22（µs 级微优化）**：CLI 短生命周期场景收益不可感知，不动。
- **发现 #23 #24（冒号/分隔符排版）**：被测试锁死或纯观感，不动。
- **readTodos 的 existsSync、JSON 缩进序列化**：前者冗余但无害；后者是数据可读性的有意取舍，保留。
- **test.js:13 首次 env 赋值冗余**：测试内部细节，无行为影响，不动。

> 无人值守环境，按默认选项执行（修 P0+P1 项、`refactor:` 提交前缀、默认 commit 粒度）；所有"行为变更"类项因无法向用户确认而暂缓，未混入重构提交。

---

# 重构完成（Step 7 总结）

## 提交（9 个，均通过 npm test 后落库）

| commit | 说明 |
|--------|------|
| `ea275f5` test: 补充行为锚点回归用例 | 动代码前锁定重复标题顺序语义与 renderList 精确行格式 |
| `8902d5e` refactor: 合并 normalizeTitle 与标题校验 | 消除 cli/api 双份归一化/校验实现，错误文案与 100 上限只剩一份 |
| `9df646d` refactor: renderList 去重 | 4 份复制的格式化块收敛为 formatTodoLine + matchesFilter，嵌套 4 层→1 层 |
| `324c8fc` refactor: 删除死代码 formatDateLegacy | 无调用方、注释自认废弃，直接删除 |
| `bedcc53` refactor: getStats/searchTodos 上移至 api 层 | store 收敛为纯读写，cli 不再越过 api 直调 store |
| `d302d20` refactor: api 层写操作改为不可变更新 | add/toggle/remove 不再原地 mutate，产出新数组/新对象 |
| `b19e1a1` refactor: 统计重复标题检测优化为 O(n) 单遍 | Map 计数替换 n²/2 配对循环+indexOf，顺序语义逐字等价 |
| `c356dc3` refactor: 统一状态展示 | stats 移除与列表不一致的 √/×，状态词汇全项目只剩一套 |
| `e86dcc1` refactor: 数据写入改为临时文件+原子替换 | 消除写入中断留半截 JSON 的损坏隐患，成功路径零差异 |

## Before → After

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| src 总行数 | 220（api 55 / cli 109 / store 56） | 190（api 80 / cli 73 / store 37） |
| 测试 | 12 用例 | 14 用例（新增 2 个行为锚点） |
| 跨文件重复块 | 3 处（normalizeTitle×2、校验规则×2、渲染格式×4） | 0 |
| 最深嵌套 | 4 层（renderList） | 1 层 |
| 死代码 | 1 处（formatDateLegacy） | 0 |
| 重复标题检测复杂度 | Θ(n²) 配对 + indexOf，最坏 ≈ n²·L/2 字符比较 | O(n) 单遍 Map 计数 |
| 实测（n=5000，真实分布模拟） | 39.7 ms | 0.9 ms（约 44×，n 越大差距越大） |
| 数据写入 | 直接覆盖，中断即损坏 | 临时文件 + rename 原子替换 |

## 验证

- 每个 commit 后 `npm test`：全部通过；最终 **14/14 passed**（零依赖，`node test/test.js` 等价）。
- CLI 行为快照对比重放（add/done/list 各 filter/stats/search/空结果/用法 共 13 条命令）：除 stats 行尾 `√`/`×` 符号按 UI 一致性要求移除外，**其余输出逐字节一致**（含"未知 filter 按 all 处理"等宽容行为）。
- 源 fixtures 项目未被修改（git status 干净）。

## 遗留（未修项及原因）

- **P0 风险但需拍板**：readTodos 对损坏 JSON 静默返回 []，配合下次写入会静默覆盖数据——修复属行为变更，待确认后单独提交。
- **P1 暂缓（行为变更/新功能，无人值守无法确认）**：CLI 入口错误兜底与 id 正整数校验、暴露 remove 命令、toggle 按实际状态输出文案、列表行加 #id、priority 参数打通。
- **P2 不动**：toggle/remove 两处查找骨架与 read-改-write 三明治（"两次重复观察第三次"）、µs 级微优化、冒号全半角（被测试锁死）等，详见上文发现表 #19-#24。

> 无人值守环境，按默认选项执行。
