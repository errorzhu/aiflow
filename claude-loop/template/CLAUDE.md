# 任务

<!-- TASK_START -->
（尚未定义任务，请先运行 /explore）
<!-- TASK_END -->

验证：见当前 workspace 下的 verify.sh

---

# L1 · 当前摘要

> 每轮 session 结束前覆盖更新 .{{USERNAME}}/memory/l1-summary.md，严格不超过 20 行。

<!-- L1_START -->
状态：未开始
最近失败：无
关键结论：无
下一步：运行 /explore 开始探索
<!-- L1_END -->

---

# 项目模块索引

> 已扫描模块，需要细节时 Read 对应文件。

<!-- PROJECT_INDEX_START -->
（暂无，/explore 扫描后追加）
<!-- PROJECT_INDEX_END -->

---

# 记忆使用规则

## 读取规则
- 本文件每次 session 自动加载，无需再读
- 模块细节：查看上方索引，Read `.{{USERNAME}}/memory/project/<module>.md`
- 踩坑记录：Read `.{{USERNAME}}/memory/errors.md`
- 方案记录：Read `.{{USERNAME}}/memory/approach.md`
- `.{{USERNAME}}/memory/log/` 不要加载，仅供人工查阅

## 写入规则
- **session 结束前**：覆盖写入 `.{{USERNAME}}/memory/l1-summary.md`，不超过 20 行
- **模块细节**：写入 `.{{USERNAME}}/memory/project/<module>.md`
- **踩坑**：追加写入 `.{{USERNAME}}/memory/errors.md`，格式：`[Round N] 现象 → 根因 → 解决`
- **方案**：追加写入 `.{{USERNAME}}/memory/approach.md`，格式：`[Round N] 方案 → 结果 → 原因`
- **不在 L1 里写细节**，超过 20 行就是写错了层

## L2 加载时机
- session 开始时 → 读 `.{{USERNAME}}/memory/env.md` 了解运行环境和配置
- 遇到报错 → 先读 `.{{USERNAME}}/memory/errors.md`
- 涉及已知模块 → 读 `.{{USERNAME}}/memory/project/<module>.md`
- 不确定方案 → 读 `.{{USERNAME}}/memory/approach.md`
