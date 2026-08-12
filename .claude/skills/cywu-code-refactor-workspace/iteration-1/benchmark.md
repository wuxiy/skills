# Skill Benchmark: cywu-code-refactor

**Model**: claude (session model, 6 parallel subagents)
**Date**: 2026-08-12T10:23:55Z
**Evals**: 1, 2, 3 (1 run each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 94% ± 10% | +0.06 |
| Time | 772.1s ± 453.4s | 711.5s ± 308.2s | +60.6s |
| Tokens | 27798 ± 7859 | 23633 ± 1734 | +4164 |

## Notes

- 量化差异集中在报告规范：唯一失败断言是基线 eval-1 报告缺少 P0/P1 优先级分层（技能模板强制要求），其余断言两组全过——强模型基线下，技能的价值更多体现在 qualitative 行为差异而非断言分数
- 关键 qualitative 差异（eval-1）：无技能基线越界引入行为变更与新功能（补 remove 命令、--high 入口、错误提示改写、stats 符号统一、测试 12→25）；有技能组把同类改动明确列入"不动的部分（行为变更需确认）"，守住了行为保持底线——这正是技能三条底线的直接效果
- 例外提示：有技能组 eval-1 仍执行了 stats √/× 符号统一（P1），与其自述"行为变更需确认"存在轻微矛盾，建议人工审阅时关注该边界是否需要技能进一步收紧
- 两组都独立消除了 O(n²) 统计循环、合并了重复 normalizeTitle、使用 refactor 提交前缀——这些断言不具区分度，属强基线下的共性能力
- eval-2（cleanup 模式）两组都正确判定补丁叠补丁并给出干净重写；基线甚至额外挖出 4 个补丁遗留 bug（负价格钳制被绕过等）。技能组的优势在于报告结构化（逐提交根因表 + 覆盖核对），以及把"替换关系"写进提交说明
- 耗时/token：有技能组平均 772s/27.8k tokens，无技能基线平均 711s/23.6k tokens——技能带来约 +61s/+4.2k 的开销，换取流程纪律与报告规范
