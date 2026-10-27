---
name: w-retro
description: 复盘历史聊天记录，找出阻碍 AI 工作的卡点，输出可 review 的优化清单（默认只读、不写入）。也用于「安全读取超长会话/日志」——提供分页、落盘、grep 定位的标准姿势，避免被 tool-output 压缩搞丢原文。当用户说「复盘」「retro」「看看过去的聊天记录」「哪里可以优化」「AI 哪里卡住了」时使用。
---

# 复盘 / 长内容安全读取

## 何时使用

- 用户要做复盘：翻历史线程，找阻碍 AI 工作的点
- 用户问「有没有可以优化的地方」「AI 哪里卡住了」
- 需要读取超长会话、大日志、大批量工具输出时的标准姿势（这一半是通用技能）

## 铁律（违反任何一条都会得出错误结论）

1. **默认只读。** 复盘阶段不写报告文件、不改配置、不发消息。结论放聊天里，等用户 review 后再决定写入。
2. **预览不等于原文。** `alma thread messages` 预览每条裁到 80 字符，只能用来定位，不能用来下结论。定性结论必须回 `--full` 原文。
3. **被压缩就分页读，不要重新请求。** 输出被 `alma compacted … saved to <path>` 折叠时，用 Read 打开那个已有文件，按 offset 翻页读完。重新跑一遍同样的命令只会再被压缩一次。
4. **大结果先落盘再筛选。** 循环类任务在脚本里做过滤/聚合，只 print 最终结论，不要把原始数据倒回上下文。
5. **grep 只能证明「有」，不能证明「只有」。** 用关键词命中定位后，必须在原文里确认上下文，否则容易把正常汇报误判成故障。

## 已知工具坑（都踩过）

| 坑 | 现象 | 对策 |
|---|---|---|
| 预览截断 | 每条只有 80 字符 | 定位用预览，引用用 `--full` |
| 分页上限 | `limit must be 1–100` | 最大 100，用 `--offset` 步进 |
| help 打错 | `alma thread messages --help` → `HTTP 404 Thread not found` | 别用 `--help`，`--help` 会被当成 threadId |
| 输出压缩 | `alma compacted … INCOMPLETE MODEL-VISIBLE OUTPUT` | 读已保存的 overflow 文件，别重跑 |
| 默认输出量大 | 全量 JSON 一次就爆 | 只取需要的字段，脚本内聚合 |

## 标准流程

### 1. 盘点范围

```bash
alma threads --all          # 线程清单（元数据，不是内容）
```

### 2. 量化扫描（脚本里做，只 print 统计）

对每个线程分页拉全文，统计「摩擦信号」：裸「继续」次数、`Generation failed` 次数、后台唤醒次数、超时/ssh/docker 关键词命中。

```js
// run_script 里跑
const ids = [/* 线程 id */];
const rows = [];
for (const id of ids) {
  let offset = 0, all = "";
  for (let p = 0; p < 6; p++) {
    const r = await alma(`thread messages ${id} 100 --full --offset ${offset}`);
    all += r; offset += 100;
    if (!/MORE MESSAGES/.test(r)) break;
  }
  const blocks = all.split(/\n(?=\[m[a-z0-9]+--)/).filter(b => /sent-at/.test(b.split("\n")[0]));
  const users = blocks.filter(b => / user — /.test(b.split("\n")[0]));
  const cont = users.filter(b => /^\s*继续\s*$/.test(b.split("\n").slice(1).join("").trim())).length;
  rows.push({ id, msgs: blocks.length, users: users.length, cont,
              genfail: (all.match(/Generation failed/g) || []).length });
}
console.log(rows.map(r => JSON.stringify(r)).join("\n"));
```

**解析坑**：消息头的格式是 `[<id>--user-<n>] user — sent-at: …`。切块用 `\n(?=\[m[a-z0-9]+--)`，判断角色用 `/ user — /`（注意 `--user-` 前面没有空格，不能用 `/ --/` 判角色）。

### 3. 定向回原文

优先读**用户消息全文**——用户的纠正、重发、催问就是最准的卡点信号：

- 同一句话**几分钟内发两次** → 上一轮回合静默丢失
- **同一请求在新线程重开** → 上一轮彻底失败
- 大量裸「继续」 → 回合被打断
- 「不用 X」「先不执行」「暂停」 → 上一轮违反了显式约束

助手侧只对**最重的 1–2 个线程**逐条回读，其余用关键词定位。

### 4. 出报告

按严重度分级，每条必须带：**证据（线程 id + 原文引用）→ 根因 → 建议 → 建议落点**。

- 明确写出**覆盖边界**：哪些线程逐条读了、哪些只是关键词命中
- 结尾给「待你 review 的写入方案」表格，**勾选后才动手**

## 判断卡点的分类框架

| 类别 | 典型信号 | 一般落点 |
|---|---|---|
| 回合丢失 | 重发同一句、新线程重开、裸「继续」 | MEMORY 铁律 + 配置修正 |
| Provider 故障 | key 失效、provider disabled、`[1210]` 类参数错 | 任务开头预检 |
| 单轮超时 | 600s 强杀、任务跑 10 分钟无输出 | 拆片 + 落盘 + 后台轮询 |
| 规范未沉淀 | 同一要求说 2–3 遍、默认输出不符口味 | skill 默认值 / USER.md 偏好 |
| 跨 agent 不可移植 | 「codex 怎么用这个 skill」 | 同步产出 AGENTS.md 兼容版 |
| 环境脆弱 | SSH 255 瞬断、镜像拉取静默失败 | 写小抄 skill（base64+nohup+轮询） |

## 反模式

- ❌ 只看预览就断言「AI 出错了」
- ❌ 先写报告文件再问用户
- ❌ 把统计结论当成根因（「超时 23 次」不等于「超时是主要瓶颈」，要分流：provider 断流 / 参数错 / 真墙钟）
- ❌ 复盘完顺手改配置——必须等 review
