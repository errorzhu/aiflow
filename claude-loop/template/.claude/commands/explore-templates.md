# Explore 模板文件（供 /explore 按需读取，不直接加载）

---

## TPL-ENV · env.md 格式

```markdown
# env.md · 环境与配置
> 最后更新：<日期>

## 运行入口
\```bash
<完整运行命令>
\```

## 关键配置
| 配置项 | 值 |
|--------|-----|
| <key>  | <value> |

## 环境标识
- <集群、环境等>

## 依赖服务
- <服务名>：<版本或地址>
```

---

## TPL-VERIFY · verify_logic.py 模板

```python
#!/usr/bin/env python3
"""
验收脚本：<问题描述>
基于：.{{USERNAME}}/workspace/<slug>/explore-report.md
"""
import sys

def check_<item>():
    """<检查项描述>"""
    # 基于探索发现的真实接口和数据结构
    # 失败时打印足够上下文，方便 Claude 定位问题
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

## TPL-VERIFY-SH · verify.sh 模板

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/verify_logic.py"
```
