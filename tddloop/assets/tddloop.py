#!/usr/bin/env python3
"""
tddloop.py — TDD 循环流程编排工具（项目通用）

用法：
  python tddloop.py run <requirement>        完整的 TDD 循环（推荐）
  python tddloop.py status                   查看所有验证条件状态
  python tddloop.py export                   导出 conditions.md 可读版
  python tddloop.py mark-done <condition_id> 手动标记已完成
  python tddloop.py write '<json>'           写入新验证条件
  python tddloop.py update <id> '<json>'     更新已有验证条件

项目配置：tddloop.json（定义测试命令、路径模式等）
数据存储：conditions/conditions.json（自动初始化为空）
"""

import json
import os
import subprocess
import sys
import argparse
from datetime import datetime
from pathlib import Path


# ── 配置加载 ────────────────────────────────────────────

DEFAULT_CONFIG = {
    "test_runner": "pytest {test_file} -v",
    "test_runner_all": "pytest tests/ -v",
    "lint": "flake8 src/",
    "test_file_pattern": "tests/test_{condition_id}.py",
    "test_func_pattern": "test_{case_id}_{desc}",
    "conditions_file": "conditions/conditions.json",
    "markdown_export": "conditions/conditions.md",
    "implementation_dir": "src",
    "auto_mark_done": True,
    "max_retries": 3,
}

PROJECT_ROOT = Path.cwd()
CONFIG_PATH = PROJECT_ROOT / "tddloop.json"


def load_config():
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            cfg = json.load(f)
        # merge with defaults
        merged = {**DEFAULT_CONFIG, **cfg}
        return merged
    return dict(DEFAULT_CONFIG)


def resolve_path(relative_path):
    return str(PROJECT_ROOT / relative_path)


# ── 数据层（原位 conditions/conditions.json） ──────────

def load_conditions(cfg):
    path = resolve_path(cfg["conditions_file"])
    if not os.path.exists(path):
        # 如果目录不存在也创建
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return {"project": str(PROJECT_ROOT.name), "updated": "", "counter": 0, "conditions": []}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_conditions(data, cfg):
    data["updated"] = datetime.now().strftime("%Y-%m-%d")
    path = resolve_path(cfg["conditions_file"])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def next_condition_id(data):
    data["counter"] += 1
    return f"C{data['counter']:03d}"


# ── 命令实现 ────────────────────────────────────────────

def cmd_status(args, cfg):
    """查看所有验证条件状态"""
    data = load_conditions(cfg)
    conditions = data["conditions"]

    if not conditions:
        print("暂无验证条件。运行 tddloop run <需求描述> 开始。")
        return

    STATUS_LABEL = {
        "pending": "⏳ 待实现",
        "partial": "🔶 部分实现",
        "done": "✅ 已实现",
        "deprecated": "🚫 已废弃",
    }

    counts = {"pending": 0, "partial": 0, "done": 0, "deprecated": 0}
    print("验证条件列表")
    print("─" * 60)
    for c in conditions:
        s = c["status"]
        counts[s] = counts.get(s, 0) + 1
        label = STATUS_LABEL.get(s, s)
        covered = sum(1 for case in c["cases"] if case.get("covered"))
        total = len(c["cases"])
        cov_str = f"{covered}/{total}" if s in ("partial", "done") else str(total)
        print(f"  {c['id']}  [{label}]  {c['requirement']:<30}  {cov_str} cases")
    print("─" * 60)
    print(f"共 {len(conditions)} 条  |  "
          f"pending: {counts['pending']}  "
          f"partial: {counts['partial']}  "
          f"done: {counts['done']}  "
          f"deprecated: {counts['deprecated']}")

    # 提示 partial 条目
    partials = [c for c in conditions if c["status"] == "partial"]
    if partials:
        print()
        for c in partials:
            uncovered = [case for case in c["cases"] if not case.get("covered")]
            print(f"⚠️  {c['id']} 未覆盖的 cases: {', '.join(case['id'] for case in uncovered)}")


def cmd_export(args, cfg):
    """导出可读 Markdown"""
    data = load_conditions(cfg)
    conditions = data["conditions"]

    STATUS_LABEL = {
        "pending": "⏳ 待实现",
        "partial": "🔶 部分实现",
        "done": "✅ 已实现",
        "deprecated": "🚫 已废弃",
    }

    lines = [
        "# 验证条件",
        "",
        f"> 最后更新：{data['updated']}  |  共 {len(conditions)} 条",
        "",
        "---",
        "",
        "## 汇总",
        "",
        "| ID | 状态 | 需求 | Cases |",
        "|-----|------|------|-------|",
    ]
    for c in conditions:
        covered = sum(1 for case in c["cases"] if case.get("covered"))
        total = len(c["cases"])
        cov = f"{covered}/{total}" if c["status"] == "partial" else str(total)
        label = STATUS_LABEL.get(c["status"], c["status"])
        lines.append(f"| {c['id']} | {label} | {c['requirement']} | {cov} |")
    lines += ["", "---", "", "## 详细内容", ""]

    for c in conditions:
        label = STATUS_LABEL.get(c["status"], c["status"])
        lines += [f"### {c['id']}  {label}", "", f"**需求**：{c['requirement']}", "", "**Cases**：", ""]
        for case in c["cases"]:
            mark = "✓" if case.get("covered") else "○"
            lines += [
                f"- {mark} `{case['id']}`  {case['description']}",
                f"  - 前置条件：{case.get('preconditions', '无')}",
                f"  - 输入：{case.get('input', '—')}",
                f"  - 期望输出：{case.get('expected_output', '—')}",
                "",
            ]
        if c.get("assumptions"):
            lines += ["**假设**：", ""]
            for a in c["assumptions"]:
                lines.append(f"- [{a['type']}] {a['content']}")
            lines.append("")
        lines += ["---", ""]

    md_path = resolve_path(cfg["markdown_export"])
    Path(md_path).write_text("\n".join(lines), encoding="utf-8")
    print(f"✓ 已导出到 {md_path}")


def cmd_write(args, cfg):
    """写入新验证条件"""
    data = load_conditions(cfg)
    payload = json.loads(args.json_data)
    cid = next_condition_id(data)
    now = datetime.now().isoformat(timespec="seconds")

    for i, case in enumerate(payload.get("cases", []), 1):
        if "id" not in case or not case.get("id"):
            case["id"] = f"{cid}-{i}"
        case.setdefault("covered", False)

    condition = {
        "id": cid,
        "requirement": payload["requirement"],
        "cases": payload.get("cases", []),
        "assumptions": payload.get("assumptions", []),
        "status": "pending",
        "created_at": now,
        "history": [
            {"at": now, "requirement": payload["requirement"], "reason": "初始创建"}
        ],
    }
    data["conditions"].append(condition)
    save_conditions(data, cfg)
    print(json.dumps({"ok": True, "id": cid, "cases_count": len(condition["cases"])}, ensure_ascii=False))


def cmd_update(args, cfg):
    """更新已有验证条件"""
    data = load_conditions(cfg)
    payload = json.loads(args.json_data)
    condition = next((c for c in data["conditions"] if c["id"] == args.id), None)
    if not condition:
        print(json.dumps({"ok": False, "error": f"未找到 {args.id}"}))
        sys.exit(1)

    now = datetime.now().isoformat(timespec="seconds")
    condition["history"].append({
        "at": now,
        "requirement": payload.get("requirement", condition["requirement"]),
        "reason": payload.get("reason", "用户修正"),
    })
    if "requirement" in payload:
        condition["requirement"] = payload["requirement"]
    if "cases" in payload:
        condition["cases"] = payload["cases"]
        for case in condition["cases"]:
            case.setdefault("covered", False)
    if "assumptions" in payload:
        condition["assumptions"] = payload["assumptions"]
    if condition["status"] == "done":
        condition["status"] = "pending"

    save_conditions(data, cfg)
    print(json.dumps({"ok": True, "id": args.id}, ensure_ascii=False))


def cmd_mark_done(args, cfg):
    """标记为已实现"""
    data = load_conditions(cfg)
    condition = next((c for c in data["conditions"] if c["id"] == args.id), None)
    if not condition:
        print(json.dumps({"ok": False, "error": f"未找到 {args.id}"}))
        sys.exit(1)

    now = datetime.now().isoformat(timespec="seconds")
    condition["status"] = "done"
    for case in condition["cases"]:
        case["covered"] = True
    condition["history"].append({
        "at": now,
        "requirement": condition["requirement"],
        "reason": "标记为已实现",
    })
    save_conditions(data, cfg)
    cmd_export(args, cfg)
    print(json.dumps({"ok": True, "id": args.id, "status": "done"}, ensure_ascii=False))


def cmd_mark_covered(args, cfg):
    """标记指定 cases 为已覆盖"""
    data = load_conditions(cfg)
    condition = next((c for c in data["conditions"] if c["id"] == args.id), None)
    if not condition:
        print(json.dumps({"ok": False, "error": f"未找到 {args.id}"}))
        sys.exit(1)

    covered_ids = set(args.cases) if args.cases else set()
    for case in condition["cases"]:
        if case["id"] in covered_ids:
            case["covered"] = True

    total = len(condition["cases"])
    covered_count = sum(1 for c in condition["cases"] if c["covered"])
    if covered_count == total:
        condition["status"] = "partial"

    now = datetime.now().isoformat(timespec="seconds")
    condition["history"].append({
        "at": now,
        "requirement": condition["requirement"],
        "reason": f"TDD Loop 标记覆盖：{', '.join(covered_ids)}",
    })
    save_conditions(data, cfg)
    print(json.dumps({
        "ok": True,
        "id": args.id,
        "covered": f"{covered_count}/{total}",
    }, ensure_ascii=False))


# ── run 子命令：完整 TDD 循环 ──────────────────────────

def run_shell(cmd, cfg, cwd=None):
    """运行 shell 命令，自动拼接 python_prefix"""
    prefix = cfg.get("python_prefix", "")
    if prefix:
        cmd = prefix + " " + cmd
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True,
        cwd=cwd or str(PROJECT_ROOT),
    )
    return result.returncode, result.stdout, result.stderr


def _generate_test_file(condition, cfg):
    """根据 condition 生成测试文件骨架 — 只写模板，由 agent 填充逻辑。

    返回生成的测试文件路径和 case 到测试函数的映射。
    """
    test_file = resolve_path(
        cfg["test_file_pattern"].format(condition_id=condition["id"].lower())
    )
    os.makedirs(os.path.dirname(test_file), exist_ok=True)

    lines = [
        f"# condition: {condition['id']} — {condition['requirement']}",
        "",
        "import subprocess",
        "import sys",
        "import os",
        "import json",
        "",
        "",
        'def _run(args, tmpfile):',
        '    env = os.environ.copy()',
        '    env["TODO_DB_PATH"] = tmpfile',
        "    result = subprocess.run(",
        "        [sys.executable, '-m', 'todo'] + args,",
        "        capture_output=True, text=True,",
        '        cwd=os.path.join(os.path.dirname(__file__), ".."),',
        "        env=env,",
        "    )",
        "    return result",
        "",
        "",
        "@pytest.fixture",
        "def tmp_db(tmp_path):",
        "    return str(tmp_path / 'tasks.json')",
        "",
    ]

    mapping = {}
    for case in condition["cases"]:
        case_id = case["id"].lower().replace("-", "_")
        desc_short = case["description"].split("—")[0].strip().replace(" ", "_").lower()
        desc_short = "".join(c for c in desc_short if c.isalnum() or c == "_")[:30]
        func_name = cfg["test_func_pattern"].format(
            case_id=case_id, desc=desc_short
        )

        lines += [
            "",
            f"def {func_name}(tmp_db):",
            f'    """{case["id"]}: {case["description"]}"""',
            f"    # TODO: implement test for: {case['input'] or '—'}",
            f"    # Expected: {case['expected_output'] or '—'}",
            f"    pass",
            "",
        ]
        mapping[case["id"]] = func_name

    lines += [
        "",
        'if __name__ == "__main__":',
        "    import pytest",
        "    import sys",
        "    sys.exit(pytest.main(['-v', __file__]))",
        "",
    ]

    with open(test_file, "w") as f:
        f.write("\n".join(lines))

    return test_file, mapping


def cmd_run(args, cfg):
    """完整 TDD 循环：读/写 condition → 生成测试骨架 → 提示 agent 实现

    注意：tddloop 只负责流程编排和数据管理。
    实际的写测试逻辑和写实现代码由 agent 完成，
    tddloop 提供骨架和验证命令。
    """
    requirement = args.requirement

    # ── Step 1: 检查是否已有相同需求 ──
    data = load_conditions(cfg)
    existing = [c for c in data["conditions"] if c["requirement"] == requirement]
    cid = existing[0]["id"] if existing else None

    if cid:
        condition = existing[0]
        print(f"📋 已存在验证条件 {cid}（状态: {condition['status']}）")
        if condition["status"] == "done":
            print("   该条件已实现，如需重新处理请先 update 状态。")
            return
        print("   将对该条件进行 TDD 循环。")
    else:
        # ── Step 2: 生成验证条件草稿 ──
        print(f"📋 需求: {requirement}")
        print("   正在生成验证条件草稿...")
        print()
        print("   ⚠️  请先通过 write 子命令写入验证条件（含 cases 定义），")
        print("   然后重新运行 run <requirement>。")
        print()
        print(f"   示例：tddloop write '{{\"requirement\": \"{requirement}\", \"cases\": [...]}}'")
        return

    # ── Step 3: 展示条件详情 ──
    print()
    print("─" * 60)
    print(f"验证条件: {condition['id']} — {condition['requirement']}")
    total = len(condition["cases"])
    covered = sum(1 for c in condition["cases"] if c.get("covered"))
    uncovered_cases = [c for c in condition["cases"] if not c.get("covered")]

    if covered == total:
        print(f"  Cases: {total}/{total} 已覆盖 ✅")
        if condition["status"] != "done":
            print("  所有 cases 已覆盖，自动标记为 done...")
            _auto_mark_done(condition["id"], cfg)
        else:
            print("  该条件已完成。")
        return

    print(f"  Cases: {covered}/{total} 已覆盖, {len(uncovered_cases)} 待处理")
    print()
    for case in uncovered_cases:
        print(f"    ○ {case['id']}  {case['description']}")
        print(f"      输入: {case.get('input', '—')}")
        print(f"      期望: {case.get('expected_output', '—')}")
        print()

    if condition.get("assumptions"):
        print("  假设:")
        for a in condition["assumptions"]:
            print(f"    [{a['type']}] {a['content']}")
        print()

    print("─" * 60)

    # ── Step 4: 生成/更新测试文件 ──
    test_file, mapping = _generate_test_file(condition, cfg)
    print()
    print(f"📝 测试文件: {test_file}")
    print("   测试函数映射:")
    for cid_key, func_name in mapping.items():
        print(f"     {cid_key} → {func_name}()")
    print()
    print(f"⚠️  请 agent 根据上述 case 定义填充测试逻辑，")
    print(f"   然后运行 `{cfg['test_runner'].format(test_file=test_file)}` 验证。")
    print()
    print(f"   完成后执行 `tddloop mark-covered {condition['id']} --cases "
          f"{' '.join(c['id'] for c in uncovered_cases)}`")
    print()
    print(f"   最终执行 `tddloop run \"{requirement}\"` 继续下一轮。")

    # 生成测试文件后自动跑一下确认是红色的（测试骨架都是 pass）
    rc, stdout, stderr = run_shell(cfg["test_runner"].format(test_file=test_file), cfg)
    if rc == 0:
        print()
        print(f"⚠️  测试骨架当前全部通过（pass），这是预期的。")
        print(f"   agent 填充断言后，如果第一次跑就全绿，说明实现已存在或测试不对。")
    else:
        print(f"⚠️  测试骨架未能通过（可能是导入错误等），请检查。")


def _auto_mark_done(condition_id, cfg):
    """自动标记为 done，运行全量验证 + lint"""
    print()
    print("🔍 运行全量验证...")
    rc, stdout, stderr = run_shell(cfg["test_runner_all"], cfg)
    if rc != 0:
        print(f"❌ 全量测试失败:\n{stderr or stdout}")
        return False

    if cfg.get("lint"):
        print("🔍 运行 lint...")
        rc, stdout, stderr = run_shell(cfg["lint"], cfg)
        if rc != 0:
            print(f"❌ Lint 失败:\n{stderr or stdout}")
            return False

    print("✅ 全量验证通过，标记为 done...")
    data = load_conditions(cfg)
    condition = next((c for c in data["conditions"] if c["id"] == condition_id), None)
    if not condition:
        return False

    now = datetime.now().isoformat(timespec="seconds")
    condition["status"] = "done"
    for case in condition["cases"]:
        case["covered"] = True
    condition["history"].append({
        "at": now,
        "requirement": condition["requirement"],
        "reason": "TDD Loop 自动标记完成",
    })
    save_conditions(data, cfg)
    cmd_export(None, cfg)

    print(f"✅ {condition_id} — {condition['requirement']} 已完成。")
    return True


# ── CLI 入口 ────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="tddloop — TDD 循环流程编排工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  tddloop status                        查看所有验证条件
  tddloop run "添加任务，标题不能为空"     运行 TDD 循环
  tddloop write '{"requirement":"...","cases":[...]}'  写入验证条件
  tddloop mark-done C001                手动标记完成
  tddloop export                        导出 conditions.md
""",
    )
    sub = parser.add_subparsers(dest="command")

    # run
    p_run = sub.add_parser("run", help="运行 TDD 循环")
    p_run.add_argument("requirement", help="需求描述")

    # status
    sub.add_parser("status", help="查看所有验证条件状态")

    # export
    sub.add_parser("export", help="导出 conditions.md")

    # write
    p_write = sub.add_parser("write", help="写入新验证条件")
    p_write.add_argument("json_data", help="JSON 数据字符串")

    # update
    p_update = sub.add_parser("update", help="更新已有验证条件")
    p_update.add_argument("id")
    p_update.add_argument("json_data")

    # mark-done
    p_done = sub.add_parser("mark-done", help="标记为已实现")
    p_done.add_argument("id")

    # mark-covered
    p_covered = sub.add_parser("mark-covered", help="标记 cases 为已覆盖")
    p_covered.add_argument("id")
    p_covered.add_argument("--cases", nargs="*", default=[])

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    cfg = load_config()

    commands = {
        "status": cmd_status,
        "export": cmd_export,
        "write": cmd_write,
        "update": cmd_update,
        "mark-done": cmd_mark_done,
        "mark-covered": cmd_mark_covered,
        "run": cmd_run,
    }

    commands[args.command](args, cfg)


if __name__ == "__main__":
    main()
