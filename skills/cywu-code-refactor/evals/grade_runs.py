#!/usr/bin/env python3
"""Grade all 6 eval runs of iteration-1 against their assertions."""

import json
import os
import re
import shutil
import subprocess

ITER1 = os.path.join(os.path.dirname(os.path.abspath(__file__)), "iteration-1")

EVAL2_ORIGINAL_TESTS = [
    "无折扣无会员：原价",
    "SAVE20 折扣",
    "VIP 会员 9 折",
    "折扣码与会员折扣叠加：先折扣码后会员",
    "四舍五入到分",
    "未知折扣码按无折扣处理",
    "VIP50 与会员折扣不叠加，取更优惠者",
    "VIP50 非会员",
    "负价格输入兜底为 0",
    "价格为 0",
]


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def grep_dir(directory, pattern):
    """Return list of 'file:line' matches for regex pattern in directory."""
    matches = []
    rx = re.compile(pattern)
    for root, _dirs, files in os.walk(directory):
        if ".git" in root.split(os.sep):
            continue
        for name in files:
            if not name.endswith((".js", ".json", ".md")):
                continue
            path = os.path.join(root, name)
            for i, line in enumerate(read(path).splitlines(), 1):
                if rx.search(line):
                    matches.append(f"{os.path.relpath(path, directory)}:{i}")
    return matches


def git_subjects(work):
    r = subprocess.run(
        ["git", "-C", work, "log", "--format=%s"],
        capture_output=True, text=True,
    )
    return [s for s in r.stdout.splitlines() if s.strip()]


def git_full_log(work):
    r = subprocess.run(
        ["git", "-C", work, "log", "--format=%H %s"],
        capture_output=True, text=True,
    )
    return r.stdout


def run_npm_test(work):
    r = subprocess.run(
        ["node", "test/test.js"], cwd=work, capture_output=True, text=True, timeout=120
    )
    return r.returncode, r.stdout + r.stderr


def exp(text, passed, evidence):
    return {"text": text, "passed": bool(passed), "evidence": evidence}


def write_grading(run_dir, expectations):
    run1 = os.path.join(run_dir, "run-1")
    os.makedirs(run1, exist_ok=True)
    passed = sum(1 for e in expectations if e["passed"])
    grading = {
        "expectations": expectations,
        "summary": {
            "passed": passed,
            "failed": len(expectations) - passed,
            "total": len(expectations),
            "pass_rate": round(passed / len(expectations), 4),
        },
    }
    with open(os.path.join(run1, "grading.json"), "w", encoding="utf-8") as f:
        json.dump(grading, f, indent=2, ensure_ascii=False)
    # timing.json lives one level up in our layout; copy it into run-1 for the aggregator
    src_timing = os.path.join(run_dir, "timing.json")
    if os.path.exists(src_timing):
        shutil.copy(src_timing, os.path.join(run1, "timing.json"))
    return grading["summary"]


def grade_todo_app(eval_dir, full_mode):
    """Assertions for todo-app evals (eval 1 full / eval 3 casual)."""
    for config in ("with_skill", "without_skill"):
        run_dir = os.path.join(eval_dir, config)
        work = os.path.join(run_dir, "outputs", "work")
        src = os.path.join(work, "src")
        report = read(os.path.join(run_dir, "outputs", "report.md"))
        exps = []

        if full_mode:
            dims = [d for d in ("重复逻辑", "设计", "UI", "性能") if d in report]
            has_prio = "P0" in report and "P1" in report
            exps.append(exp(
                "产出了 report.md，且覆盖重复逻辑、设计、UI 一致性、性能四个维度，每个维度有具体条目和优先级",
                report and len(dims) == 4 and has_prio,
                f"report.md {'存在' if report else '缺失'}；命中维度关键词: {dims or '无'}；优先级标记(P0/P1): {'有' if has_prio else '无'}",
            ))
        else:
            has_findings = ("发现" in report) or ("问题" in report)
            has_plan = ("重构计划" in report) or ("计划" in report) or ("建议" in report)
            exps.append(exp(
                "产出了 report.md，包含发现清单与重构计划",
                bool(report) and has_findings and has_plan,
                f"report.md {'存在' if report else '缺失'}；发现清单: {'有' if has_findings else '无'}；重构计划/建议: {'有' if has_plan else '无'}",
            ))

        subjects = git_subjects(work) if os.path.isdir(work) else []
        refactor_commits = [s for s in subjects if s.startswith("refactor")]
        exps.append(exp(
            "work/ 副本的 git 提交使用 refactor 前缀",
            len(refactor_commits) >= 1,
            f"共 {len(subjects)} 个提交，其中 refactor 前缀 {len(refactor_commits)} 个: {refactor_commits[:4]}",
        ))

        dup_defs = grep_dir(src, r"function\s+normalizeTitle")
        exps.append(exp(
            "标题归一化逻辑只存在一处实现（api.js 与 cli.js 中重复的 normalizeTitle 被合并，两个模块行为一致）"
            if full_mode else "至少合并了一处重复实现（normalizeTitle 或重复的标题校验）",
            len(dup_defs) <= 1,
            f"src/ 中 normalizeTitle 函数定义出现 {len(dup_defs)} 处: {dup_defs or '无（可能已重命名）'}",
        ))

        if full_mode:
            nested = grep_dir(src, r"for\s*\(\s*(let|var|const)\s+j\b")
            exps.append(exp(
                "统计重复标题的 O(n²) 双重循环被消除",
                len(nested) == 0,
                f"内层 j 循环匹配: {nested or '无，双重循环已消除'}",
            ))
            dead = grep_dir(src, r"formatDateLegacy")
            exps.append(exp(
                "死代码 formatDateLegacy 被删除",
                len(dead) == 0,
                f"src/ 中 formatDateLegacy 残留: {dead or '无，已删除'}",
            ))

        code, out = run_npm_test(work) if os.path.isdir(work) else (1, "work/ 不存在")
        tail = "; ".join(out.strip().splitlines()[-2:])
        exps.append(exp(
            "重构后在 work/ 副本中运行 npm test 全部通过",
            code == 0,
            f"exit={code}；{tail}",
        ))

        summary = write_grading(run_dir, exps)
        print(f"{os.path.basename(eval_dir)}/{config}: {summary['passed']}/{summary['total']}")


def grade_discount_calc(eval_dir):
    for config in ("with_skill", "without_skill"):
        run_dir = os.path.join(eval_dir, config)
        work = os.path.join(run_dir, "outputs", "work")
        src = os.path.join(work, "src")
        report = read(os.path.join(run_dir, "outputs", "report.md"))
        exps = []

        patch_keywords = [k for k in ("未知折扣码", "VIP50", "负价格") if k in report]
        has_cause = ("根因" in report) or ("症状" in report)
        exps.append(exp(
            "report.md 逐个分析了 git 历史中的 fix 提交：每个补丁修的症状是什么、根因是什么",
            len(patch_keywords) == 3 and has_cause,
            f"三个补丁主题关键词命中 {patch_keywords or '无'}；症状/根因分析: {'有' if has_cause else '无'}",
        ))

        verdict = "补丁叠补丁" in report
        exps.append(exp(
            "明确给出了是否为补丁叠补丁的判断结论",
            verdict,
            "报告中出现'补丁叠补丁'判断表述" if verdict else "报告未出现明确判断",
        ))

        fix_marks = grep_dir(src, r"FIX")
        price_js = read(os.path.join(src, "price.js"))
        early_returns = price_js.count("return Math.round")
        exps.append(exp(
            "重构后的代码中不再保留 FIX 兜底注释及对应的特判结构（safeRate 三元、VIP50 early-return 分支被整合进统一实现）",
            len(fix_marks) == 0 and early_returns <= 1,
            f"src/ 中 FIX 标记 {len(fix_marks)} 处 {fix_marks or ''}；price.js 中 'return Math.round' 出口 {early_returns} 处（1 = 单一出口）",
        ))

        code, out = run_npm_test(work) if os.path.isdir(work) else (1, "work/ 不存在")
        ok_lines = [l for l in out.splitlines() if l.strip().startswith("ok -")]
        missing = [t for t in EVAL2_ORIGINAL_TESTS if not any(t in l for l in ok_lines)]
        exps.append(exp(
            "重构后在 work/ 副本中运行 npm test 全部通过（10 个用例锁定的行为全部保持）",
            code == 0 and not missing,
            f"exit={code}；原 10 个契约用例全部 ok" if not missing else f"exit={code}；缺失/失败的原始用例: {missing}",
        ))

        subjects = git_subjects(work) if os.path.isdir(work) else []
        refactor_commits = [s for s in subjects if s.startswith("refactor")]
        full_log = git_full_log(work) if os.path.isdir(work) else ""
        replacement = ("替换" in report) or ("替换" in full_log) or any(
            h in (report + full_log) for h in ("31a1dfa", "4e35f0a", "f5e0d83")
        )
        exps.append(exp(
            "work/ 副本的 git 提交使用 refactor 前缀，且提交信息或报告说明了与原补丁提交的替换关系",
            len(refactor_commits) >= 1 and replacement,
            f"refactor 提交 {len(refactor_commits)} 个；替换关系说明(报告或提交信息提及原补丁/哈希): {'有' if replacement else '无'}",
        ))

        summary = write_grading(run_dir, exps)
        print(f"{os.path.basename(eval_dir)}/{config}: {summary['passed']}/{summary['total']}")


def main():
    grade_todo_app(os.path.join(ITER1, "eval-1-full-review-todo-app"), full_mode=True)
    grade_discount_calc(os.path.join(ITER1, "eval-2-cleanup-discount-calc"))
    grade_todo_app(os.path.join(ITER1, "eval-3-casual-refactor-todo"), full_mode=False)


if __name__ == "__main__":
    main()
