#!/usr/bin/env bash
# Regenerate the two eval fixture projects (todo-app, discount-calc).
# These are gitignored (they contain nested .git); run after a fresh clone to make
# the evals in ../cywu-code-refactor/evals/evals.json reproducible.
#   Usage: bash setup-fixtures.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$HERE/fixtures"
echo ">> 清理旧 fixtures: $FIX"
rm -rf "$FIX"
mkdir -p "$FIX"

gitinit() { git init -q -b main; git config user.name "Dev"; git config user.email "dev@example.com"; }

# ───────────────────────── fixture: todo-app ─────────────────────────
{
  D="$FIX/todo-app"; mkdir -p "$D/src" "$D/test"
  printf '{\n  "name": "todo-app",\n  "version": "1.0.0",\n  "private": true,\n  "description": "命令行 Todo 工具",\n  "scripts": { "test": "node test/test.js", "start": "node src/cli.js" }\n}\n' > "$D/package.json"
  printf 'node_modules/\ndata/\n' > "$D/.gitignore"
  cat > "$D/README.md" <<'MD'
# todo-app

命令行 Todo 工具。

## 命令
- `node src/cli.js add <标题>` 添加待办
- `node src/cli.js list [all|done|todo]` 查看列表
- `node src/cli.js done <id>` 完成待办
- `node src/cli.js stats` 统计
- `node src/cli.js search <关键词>` 搜索

## 测试
`npm test`（零依赖，等价于 `node test/test.js`）
MD
  cat > "$D/src/store.js" <<'JS'
'use strict';
const fs = require('fs');
const path = require('path');
const DEFAULT_DATA_FILE = path.join(__dirname, '..', 'data', 'todos.json');
function dataFile() { return process.env.TODO_DATA_FILE || DEFAULT_DATA_FILE; }
function readTodos() {
  const file = dataFile();
  if (!fs.existsSync(file)) return [];
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { return []; }
}
function writeTodos(todos) {
  const file = dataFile();
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(todos, null, 2));
}
function nextId(todos) { return todos.reduce((max, t) => Math.max(max, t.id), 0) + 1; }
function getStats() {
  const todos = readTodos();
  const duplicateTitles = [];
  for (let i = 0; i < todos.length; i++) {
    for (let j = i + 1; j < todos.length; j++) {
      if (todos[i].title === todos[j].title) {
        if (duplicateTitles.indexOf(todos[i].title) === -1) duplicateTitles.push(todos[i].title);
      }
    }
  }
  const done = todos.filter((t) => t.done).length;
  return { total: todos.length, done, duplicateTitles };
}
function searchTodos(keyword) {
  const todos = readTodos();
  const kw = String(keyword).toLowerCase();
  return todos.filter((t) => t.title.toLowerCase().includes(kw));
}
module.exports = { readTodos, writeTodos, nextId, getStats, searchTodos };
JS
  cat > "$D/src/api.js" <<'JS'
'use strict';
const store = require('./store');
// 标题归一化：去首尾空格、压缩连续空白
// TODO: cli.js 里好像也有一份，回头合并
function normalizeTitle(title) {
  let t = String(title == null ? '' : title).trim();
  t = t.replace(/\s+/g, ' ');
  return t;
}
function validateTitle(title) {
  const t = normalizeTitle(title);
  if (!t) return { ok: false, error: '标题不能为空' };
  if (t.length > 100) return { ok: false, error: '标题不能超过 100 个字符' };
  return { ok: true, title: t };
}
function addTodo(title, priority) {
  const v = validateTitle(title);
  if (!v.ok) throw new Error(v.error);
  const todos = store.readTodos();
  const todo = { id: store.nextId(todos), title: v.title, priority: priority === 'high' ? 'high' : 'normal', done: false, createdAt: new Date().toISOString() };
  todos.push(todo);
  store.writeTodos(todos);
  return todo;
}
function toggleTodo(id) {
  const todos = store.readTodos();
  const todo = todos.find((t) => t.id === id);
  if (!todo) throw new Error(`未找到 id 为 ${id} 的待办`);
  todo.done = !todo.done;
  store.writeTodos(todos);
  return todo;
}
function removeTodo(id) {
  const todos = store.readTodos();
  const idx = todos.findIndex((t) => t.id === id);
  if (idx === -1) throw new Error(`未找到 id 为 ${id} 的待办`);
  const removed = todos.splice(idx, 1)[0];
  store.writeTodos(todos);
  return removed;
}
module.exports = { normalizeTitle, validateTitle, addTodo, toggleTodo, removeTodo };
JS
  cat > "$D/src/cli.js" <<'JS'
'use strict';
const api = require('./api');
const store = require('./store');
// 标题归一化（与 api.js 中的实现重复）
function normalizeTitle(title) {
  let t = String(title == null ? '' : title).trim();
  t = t.replace(/\s+/g, ' ');
  return t;
}
// 旧版日期格式化，已经没有地方使用
function formatDateLegacy(iso) { const d = new Date(iso); return `${d.getMonth() + 1}/${d.getDate()}`; }
function renderList(todos, filter) {
  const lines = [];
  for (const t of todos) {
    if (filter === 'done') {
      if (t.done) { if (t.priority === 'high') { lines.push(`[x] (!) ${t.title}`); } else { lines.push(`[x] ${t.title}`); } }
    } else if (filter === 'todo') {
      if (!t.done) { if (t.priority === 'high') { lines.push(`[ ] (!) ${t.title}`); } else { lines.push(`[ ] ${t.title}`); } }
    } else {
      if (t.done) { if (t.priority === 'high') { lines.push(`[x] (!) ${t.title}`); } else { lines.push(`[x] ${t.title}`); } }
      else { if (t.priority === 'high') { lines.push(`[ ] (!) ${t.title}`); } else { lines.push(`[ ] ${t.title}`); } }
    }
  }
  if (lines.length === 0) lines.push('（空）');
  return lines.join('\n');
}
// NOTE: 这里用的是 √/×，和列表的 [x]/[ ] 不一致，回头统一
function renderStats(stats) {
  const lines = [];
  lines.push(`总计: ${stats.total}`);
  lines.push(`已完成: ${stats.done} √`);
  lines.push(`未完成: ${stats.total - stats.done} ×`);
  if (stats.duplicateTitles.length > 0) lines.push(`重复标题: ${stats.duplicateTitles.join(', ')}`);
  return lines.join('\n');
}
function handleAdd(rawTitle, priority) {
  const title = normalizeTitle(rawTitle);
  if (!title) return '错误：标题不能为空';
  if (title.length > 100) return '错误：标题不能超过 100 个字符';
  const todo = api.addTodo(title, priority);
  return `已添加 #${todo.id}: ${todo.title}`;
}
function main(argv) {
  const [cmd, ...rest] = argv;
  if (cmd === 'add') console.log(handleAdd(rest.join(' ')));
  else if (cmd === 'list') console.log(renderList(store.readTodos(), rest[0] || 'all'));
  else if (cmd === 'done') { const todo = api.toggleTodo(Number(rest[0])); console.log(`已完成 #${todo.id}: ${todo.title}`); }
  else if (cmd === 'stats') console.log(renderStats(store.getStats()));
  else if (cmd === 'search') { const found = store.searchTodos(rest.join(' ')); console.log(renderList(found, 'all')); }
  else console.log('用法: todo add <标题> | list [all|done|todo] | done <id> | stats | search <关键词>');
}
if (require.main === module) main(process.argv.slice(2));
module.exports = { normalizeTitle, renderList, renderStats, handleAdd };
JS
  cat > "$D/test/test.js" <<'JS'
'use strict';
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
function freshDataFile() { const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'todo-test-')); return path.join(dir, 'todos.json'); }
process.env.TODO_DATA_FILE = freshDataFile();
const api = require('../src/api');
const store = require('../src/store');
const cli = require('../src/cli');
let passed = 0;
function test(name, fn) {
  process.env.TODO_DATA_FILE = freshDataFile();
  try { fn(); passed += 1; console.log(`  ok - ${name}`); }
  catch (e) { console.error(`  FAIL - ${name}`); console.error(`    ${e.message}`); process.exitCode = 1; }
}
console.log('todo-app tests');
test('添加待办：标题归一化（去首尾空格、压缩空白）', () => { const todo = api.addTodo('  买   牛奶 '); assert.strictEqual(todo.title, '买 牛奶'); });
test('添加待办：空标题报错', () => { assert.throws(() => api.addTodo('   '), /标题不能为空/); });
test('添加待办：超长标题报错', () => { assert.throws(() => api.addTodo('a'.repeat(101)), /标题不能超过 100 个字符/); });
test('cli handleAdd 与 api 校验规则一致', () => {
  assert.strictEqual(cli.handleAdd('   '), '错误：标题不能为空');
  assert.strictEqual(cli.handleAdd('a'.repeat(101)), '错误：标题不能超过 100 个字符');
  assert.strictEqual(cli.handleAdd('  写   周报 '), '已添加 #1: 写 周报');
});
test('完成待办：toggle 翻转状态', () => {
  const todo = api.addTodo('任务A'); const toggled = api.toggleTodo(todo.id); assert.strictEqual(toggled.done, true);
  api.toggleTodo(todo.id); const todos = store.readTodos(); assert.strictEqual(todos[0].done, false);
});
test('删除待办', () => { const todo = api.addTodo('任务B'); api.removeTodo(todo.id); assert.strictEqual(store.readTodos().length, 0); });
test('搜索待办：不区分大小写', () => {
  api.addTodo('Buy Milk'); api.addTodo('写周报');
  const found = store.searchTodos('milk'); assert.strictEqual(found.length, 1); assert.strictEqual(found[0].title, 'Buy Milk');
});
test('统计：总数/完成数/重复标题', () => {
  api.addTodo('任务A'); api.addTodo('任务A'); api.addTodo('任务B'); api.toggleTodo(1);
  const stats = store.getStats(); assert.strictEqual(stats.total, 3); assert.strictEqual(stats.done, 1); assert.deepStrictEqual(stats.duplicateTitles, ['任务A']);
});
test('渲染列表：包含所有条目标题', () => {
  api.addTodo('任务A', 'high'); api.addTodo('任务B'); api.toggleTodo(1);
  const output = cli.renderList(store.readTodos(), 'all'); assert.ok(output.includes('任务A')); assert.ok(output.includes('任务B'));
});
test('渲染列表：done/todo 过滤', () => {
  api.addTodo('任务A'); api.addTodo('任务B'); api.toggleTodo(1);
  const doneOut = cli.renderList(store.readTodos(), 'done'); const todoOut = cli.renderList(store.readTodos(), 'todo');
  assert.ok(doneOut.includes('任务A')); assert.ok(!doneOut.includes('任务B'));
  assert.ok(todoOut.includes('任务B')); assert.ok(!todoOut.includes('任务A'));
});
test('渲染列表：空列表显示（空）', () => { assert.strictEqual(cli.renderList([], 'all'), '（空）'); });
test('渲染统计：包含总数与完成数', () => {
  api.addTodo('任务A'); api.addTodo('任务B'); api.toggleTodo(1);
  const output = cli.renderStats(store.getStats()); assert.ok(output.includes('总计: 2')); assert.ok(output.includes('已完成: 1')); assert.ok(output.includes('未完成: 1'));
});
if (process.exitCode) console.log(`\n${passed} passed, 有失败用例`); else console.log(`\n${passed} passed`);
JS
  ( cd "$D" && gitinit && git add -A && git commit -q -m "feat: 实现命令行 todo 工具" )
  echo "   todo-app: $( ( cd "$D" && node test/test.js | tail -1 ) )"
}

# ─────────────────────── fixture: discount-calc ───────────────────────
# 4-commit patch chain: 1 feat + 3 fix（补丁叠补丁）
{
  D="$FIX/discount-calc"; mkdir -p "$D/src" "$D/test"
  printf '{\n  "name": "discount-calc",\n  "version": "1.0.0",\n  "private": true,\n  "description": "订单折扣计算",\n  "scripts": { "test": "node test/test.js" }\n}\n' > "$D/package.json"
  printf 'node_modules/\n' > "$D/.gitignore"
  cd "$D" && gitinit

  # commit 1: feat
  cat > src/price.js <<'JS'
'use strict';
const COUPON_RATES = { SAVE10: 0.1, SAVE20: 0.2, VIP50: 0.5 };
const VIP_RATE = 0.9;
function calcFinalPrice(price, coupon, isVip) {
  let result = price;
  if (coupon) { result = result * (1 - COUPON_RATES[coupon]); }
  if (isVip) { result = result * VIP_RATE; }
  return Math.round(result * 100) / 100;
}
module.exports = { calcFinalPrice, COUPON_RATES };
JS
  cat > README.md <<'MD'
# discount-calc

订单折扣计算模块。

## 计价规则
1. 折扣码按比例减价（SAVE10=9折，SAVE20=8折，VIP50=5折）
2. VIP 会员额外 9 折
3. 折扣码与会员折扣可叠加：先应用折扣码，再应用会员折扣
4. 结果四舍五入到分

## 运行测试
    npm test
MD
  cat > test/test.js <<'JS'
'use strict';
const assert = require('assert');
const { calcFinalPrice } = require('../src/price');
let passed = 0, failed = 0;
function test(name, fn) { try { fn(); passed += 1; console.log(`  ok - ${name}`); } catch (e) { failed += 1; console.error(`  FAIL - ${name}\n    ${e.message}`); } }
console.log('discount-calc tests');
test('无折扣无会员：原价', () => assert.strictEqual(calcFinalPrice(100, null, false), 100));
test('SAVE20 折扣', () => assert.strictEqual(calcFinalPrice(100, 'SAVE20', false), 80));
test('VIP 会员 9 折', () => assert.strictEqual(calcFinalPrice(100, null, true), 90));
test('折扣码与会员折扣叠加：先折扣码后会员', () => assert.strictEqual(calcFinalPrice(100, 'SAVE10', true), 81));
test('四舍五入到分', () => assert.strictEqual(calcFinalPrice(33.33, 'SAVE10', false), 30));
if (failed > 0) { console.log(`\n${passed} passed, ${failed} failed`); process.exitCode = 1; } else console.log(`\n${passed} passed`);
JS
  git add -A && git commit -q -m "feat: 订单折扣计算"

  # commit 2: fix 未知折扣码 NaN
  cat > src/price.js <<'JS'
'use strict';
const COUPON_RATES = { SAVE10: 0.1, SAVE20: 0.2, VIP50: 0.5 };
const VIP_RATE = 0.9;
function calcFinalPrice(price, coupon, isVip) {
  let result = price;
  if (coupon) {
    const rate = COUPON_RATES[coupon];
    // FIX: 线上有人输错折扣码导致价格为 NaN，找不到的码先按 0 折扣处理
    const safeRate = rate === undefined ? 0 : rate;
    result = result * (1 - safeRate);
  }
  if (isVip) { result = result * VIP_RATE; }
  return Math.round(result * 100) / 100;
}
module.exports = { calcFinalPrice, COUPON_RATES };
JS
  cat > test/test.js <<'JS'
'use strict';
const assert = require('assert');
const { calcFinalPrice } = require('../src/price');
let passed = 0, failed = 0;
function test(name, fn) { try { fn(); passed += 1; console.log(`  ok - ${name}`); } catch (e) { failed += 1; console.error(`  FAIL - ${name}\n    ${e.message}`); } }
console.log('discount-calc tests');
test('无折扣无会员：原价', () => assert.strictEqual(calcFinalPrice(100, null, false), 100));
test('SAVE20 折扣', () => assert.strictEqual(calcFinalPrice(100, 'SAVE20', false), 80));
test('VIP 会员 9 折', () => assert.strictEqual(calcFinalPrice(100, null, true), 90));
test('折扣码与会员折扣叠加：先折扣码后会员', () => assert.strictEqual(calcFinalPrice(100, 'SAVE10', true), 81));
test('四舍五入到分', () => assert.strictEqual(calcFinalPrice(33.33, 'SAVE10', false), 30));
test('未知折扣码按无折扣处理', () => assert.strictEqual(calcFinalPrice(100, 'FAKE99', false), 100));
if (failed > 0) { console.log(`\n${passed} passed, ${failed} failed`); process.exitCode = 1; } else console.log(`\n${passed} passed`);
JS
  git add -A && git commit -q -m "fix: 未知折扣码导致价格为 NaN"

  # commit 3: fix VIP50 折上折
  cat > src/price.js <<'JS'
'use strict';
const COUPON_RATES = { SAVE10: 0.1, SAVE20: 0.2, VIP50: 0.5 };
const VIP_RATE = 0.9;
function calcFinalPrice(price, coupon, isVip) {
  let result = price;
  if (coupon) {
    const rate = COUPON_RATES[coupon];
    // FIX: 线上有人输错折扣码导致价格为 NaN，找不到的码先按 0 折扣处理
    const safeRate = rate === undefined ? 0 : rate;
    result = result * (1 - safeRate);
  }
  if (isVip) {
    if (coupon === 'VIP50') {
      // FIX: 运营投诉 VIP50 叠加会员折扣后力度过大（5折再9折），VIP50 不与会员折扣叠加，取两者中更优惠的结果
      const vipOnly = price * VIP_RATE;
      result = Math.min(result, vipOnly);
      return Math.round(result * 100) / 100;
    }
    result = result * VIP_RATE;
  }
  return Math.round(result * 100) / 100;
}
module.exports = { calcFinalPrice, COUPON_RATES };
JS
  cat > README.md <<'MD'
# discount-calc

订单折扣计算模块。

## 计价规则
1. 折扣码按比例减价（SAVE10=9折，SAVE20=8折，VIP50=5折）
2. VIP 会员额外 9 折
3. 折扣码与会员折扣可叠加：先应用折扣码，再应用会员折扣；
   例外：VIP50 活动码不与会员折扣叠加，取两者中更优惠的结果
4. 结果四舍五入到分

## 运行测试
    npm test
MD
  cat > test/test.js <<'JS'
'use strict';
const assert = require('assert');
const { calcFinalPrice } = require('../src/price');
let passed = 0, failed = 0;
function test(name, fn) { try { fn(); passed += 1; console.log(`  ok - ${name}`); } catch (e) { failed += 1; console.error(`  FAIL - ${name}\n    ${e.message}`); } }
console.log('discount-calc tests');
test('无折扣无会员：原价', () => assert.strictEqual(calcFinalPrice(100, null, false), 100));
test('SAVE20 折扣', () => assert.strictEqual(calcFinalPrice(100, 'SAVE20', false), 80));
test('VIP 会员 9 折', () => assert.strictEqual(calcFinalPrice(100, null, true), 90));
test('折扣码与会员折扣叠加：先折扣码后会员', () => assert.strictEqual(calcFinalPrice(100, 'SAVE10', true), 81));
test('四舍五入到分', () => assert.strictEqual(calcFinalPrice(33.33, 'SAVE10', false), 30));
test('未知折扣码按无折扣处理', () => assert.strictEqual(calcFinalPrice(100, 'FAKE99', false), 100));
test('VIP50 与会员折扣不叠加，取更优惠者', () => assert.strictEqual(calcFinalPrice(100, 'VIP50', true), 50));
test('VIP50 非会员', () => assert.strictEqual(calcFinalPrice(100, 'VIP50', false), 50));
if (failed > 0) { console.log(`\n${passed} passed, ${failed} failed`); process.exitCode = 1; } else console.log(`\n${passed} passed`);
JS
  git add -A && git commit -q -m "fix: VIP50 折上折力度过大被投诉"

  # commit 4: fix 负价格
  cat > src/price.js <<'JS'
'use strict';
const COUPON_RATES = { SAVE10: 0.1, SAVE20: 0.2, VIP50: 0.5 };
const VIP_RATE = 0.9;
function calcFinalPrice(price, coupon, isVip) {
  let result = price;
  if (coupon) {
    const rate = COUPON_RATES[coupon];
    // FIX: 线上有人输错折扣码导致价格为 NaN，找不到的码先按 0 折扣处理
    const safeRate = rate === undefined ? 0 : rate;
    result = result * (1 - safeRate);
  }
  if (isVip) {
    if (coupon === 'VIP50') {
      // FIX: 运营投诉 VIP50 叠加会员折扣后力度过大（5折再9折），VIP50 不与会员折扣叠加，取两者中更优惠的结果
      const vipOnly = price * VIP_RATE;
      result = Math.min(result, vipOnly);
      return Math.round(result * 100) / 100;
    }
    result = result * VIP_RATE;
  }
  // FIX: 历史订单数据里有负价格，先兜底钳制到 0，别让页面显示负数
  if (result < 0) result = 0;
  return Math.round(result * 100) / 100;
}
module.exports = { calcFinalPrice, COUPON_RATES };
JS
  cat > test/test.js <<'JS'
'use strict';
const assert = require('assert');
const { calcFinalPrice } = require('../src/price');
let passed = 0, failed = 0;
function test(name, fn) { try { fn(); passed += 1; console.log(`  ok - ${name}`); } catch (e) { failed += 1; console.error(`  FAIL - ${name}\n    ${e.message}`); } }
console.log('discount-calc tests');
test('无折扣无会员：原价', () => assert.strictEqual(calcFinalPrice(100, null, false), 100));
test('SAVE20 折扣', () => assert.strictEqual(calcFinalPrice(100, 'SAVE20', false), 80));
test('VIP 会员 9 折', () => assert.strictEqual(calcFinalPrice(100, null, true), 90));
test('折扣码与会员折扣叠加：先折扣码后会员', () => assert.strictEqual(calcFinalPrice(100, 'SAVE10', true), 81));
test('四舍五入到分', () => assert.strictEqual(calcFinalPrice(33.33, 'SAVE10', false), 30));
test('未知折扣码按无折扣处理', () => assert.strictEqual(calcFinalPrice(100, 'FAKE99', false), 100));
test('VIP50 与会员折扣不叠加，取更优惠者', () => assert.strictEqual(calcFinalPrice(100, 'VIP50', true), 50));
test('VIP50 非会员', () => assert.strictEqual(calcFinalPrice(100, 'VIP50', false), 50));
test('负价格输入兜底为 0', () => assert.strictEqual(calcFinalPrice(-100, null, false), 0));
test('价格为 0', () => assert.strictEqual(calcFinalPrice(0, 'SAVE20', true), 0));
if (failed > 0) { console.log(`\n${passed} passed, ${failed} failed`); process.exitCode = 1; } else console.log(`\n${passed} passed`);
JS
  git add -A && git commit -q -m "fix: 负价格输入导致负金额"
  echo "   discount-calc: $(git log --oneline | wc -l | tr -d ' ') commits, $(node test/test.js | tail -1)"
}

echo ">> fixtures 就绪: $FIX"
