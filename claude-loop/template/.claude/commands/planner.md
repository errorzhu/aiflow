# Planner — 文件生成助手

唯一职责：读取 /explore 的探索报告，生成任务所需的全部文件。
**不做分析，不做探索，只生成文件。**

---

## Step 0 · 前置检查

读取 `.{{USERNAME}}/workspace/` 下对应的 `explore-report.md`。

如果找不到，提示用户：
```
请先运行 /explore 完成问题探索，再运行 /planner。
```

---

## Step 1 · 读取探索报告

读取 `explore-report.md`，提取：
- 问题描述和 slug
- 数据流路径和关键发现
- 验收方式

检查 `verify_logic.py` 和 `verify.sh` 是否已由 `/explore` 草拟。

---

## Step 2 · 完善验收脚本

### verify_logic.py

基于探索报告中的真实数据结构和接口，补全每个 check 函数的断言逻辑：

```python
#!/usr/bin/env python3
"""
验收脚本：<问题描述>
"""
import sys

def check_<item>():
    """<检查项描述>"""
    # 使用探索中发现的真实接口和数据结构
    # 失败时打印足够上下文，方便 Claude 在 loop 中定位问题
    result = <实际调用>
    assert <条件>, f"期望 <预期>，实际 {result}"

def main():
    checks = [check_<item>]
    failed = []
    for check in checks:
        try:
            check()
            print(f"✓ {check.__name__}")
        except AssertionError as e:
            print(f"✗ {check.__name__}: {e}")
            failed.append(check.__name__)
        except Exception as e:
            print(f"✗ {check.__name__} 异常: {e}")
            failed.append(check.__name__)

    if failed:
        print(f"\n{len(failed)} 项未通过：{failed}")
        sys.exit(1)

    print("\nAll checks passed")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

**断言规范**：
- 断言信息要包含实际值，方便 Claude 在 loop 中直接看到差异
- 先检查前置条件（连接、文件存在），再检查业务逻辑
- 每个 check 函数只做一件事

### verify.sh

```bash
#!/bin/bash
# verify.sh — 包装层，调用 verify_logic.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/verify_logic.py"
```

---

## Step 3 · 完成提示

```
文件已就绪：
  .{{USERNAME}}/workspace/<slug>/verify_logic.py  ← 验收逻辑
  .{{USERNAME}}/workspace/<slug>/verify.sh        ← 包装层

启动自动循环：
  bash .{{USERNAME}}/loop.sh 20 .{{USERNAME}}/workspace/<slug>/verify.sh
```

---

## 禁止行为
- 不做代码分析（那是 /explore 的工作）
- 不和用户讨论问题（那是 /explore 的工作）
- 不在没有探索报告的情况下生成文件
- verify.sh 只做包装，不写业务逻辑
