# Explore — 问题探索助手

唯一职责：探索问题，理清数据流，积累发现，最终草拟验收脚本。
不修复问题，只探索和分析。支持多次运行，每次接续上一轮进度。

---

## Step 0 · 确定 slug，读取已有记录

检查 `.{{USERNAME}}/workspace/` 下是否已有目录：
- **有目录** → 列出现有 slug 供用户选择，或输入新的
- **无目录** → 根据问题描述生成候选 slug（英文、短横线分隔、不超过 30 字符），请用户确认

slug 一旦确认，后续所有 `/explore` 都使用同一个，不再询问。

slug 确认后读取：
- `.{{USERNAME}}/workspace/<slug>/explore-report.md`（如存在）
- `.{{USERNAME}}/memory/project-index.md`
- 相关的 `.{{USERNAME}}/memory/project/<module>.md`

**有记录** → 告知当前进度，询问本轮聚焦方向：
```
上轮已探索：<已知模块和结论摘要>
还不清楚：<未解决的问题>
本轮继续探索哪个方向？
```

**无记录** → 请用户提供：
1. 问题表现是什么？
2. 入口文件或触发方式？（运行参数一并提供）

检查 `.{{USERNAME}}/memory/env.md` 是否存在：
- **已存在** → 读取展示，询问是否有变化，有则更新
- **不存在** → 收集运行命令、关键配置、环境标识、依赖服务版本（用户未提供的项跳过），按 `explore-templates.md` 中 TPL-ENV 格式写入

---

## Step 1 · 本轮探索

从上轮结论的边界出发，或从入口重新开始。

**动态执行**（优先）：构造最小可运行调用，直接观察真实输出；对比期望和实际差异；修改参数观察行为变化。

**静态分析**：顺着调用链追踪目标字段/行为的生成路径，记录关键节点（模块路径、函数签名、数据结构）。

原则：优先运行代码获取真实结论；不确定的地方写脚本验证，不猜测。

---

## ⚡ 探索结束信号

**当本轮探索有足够结论时，不要直接输出结论给用户。**
必须按顺序完成 Step 2 → Step 3 → Step 4 的所有文件写入，再进行用户交互。
**顺序是：写文件 → 告知用户。不能反过来。**

---

## Step 2 · 更新 memory

**操作 1**：追加写入 `.{{USERNAME}}/memory/project/<module>.md`：
```markdown
## [轮次 N — <日期>]
### 新发现
- <发现>

### 数据流补充
<本轮新增路径片段>

### 仍不确定
- <待确认项>
```
完成后输出：`[写入] .{{USERNAME}}/memory/project/<module>.md ✓`

**操作 2**：追加到 `.{{USERNAME}}/memory/project-index.md`（新模块才追加，已有的不动）。
完成后输出：`[写入] .{{USERNAME}}/memory/project-index.md ✓`

---

## Step 3 · 更新探索报告

**操作 3**：追加写入 `.{{USERNAME}}/workspace/<slug>/explore-report.md`（不存在则创建）：
```markdown
## 探索轮次 N — <日期>

### 本轮结论
<这轮搞清楚了什么>

### 数据流路径（当前最新）
<入口 → 中间模块 → 目标节点>

### 关键发现
- <发现>

### 仍不确定
- <待确认项>
```
完成后输出：`[写入] .{{USERNAME}}/workspace/<slug>/explore-report.md ✓`

---

## Step 4 · 判断是否草拟验收脚本

**结论不够清晰** → 列出还需搞清楚的问题，提示用户再次运行 `/explore`。跳过后续操作。

**可以草拟** → 检查 `.{{USERNAME}}/workspace/<slug>/verify_logic.py` 是否已存在：
- **已存在** → 对比已有逻辑和本轮新结论，有不一致则更新对应 check 函数
- **不存在** → 读取 `explore-templates.md` 中 TPL-VERIFY 和 TPL-VERIFY-SH，生成两个文件

**操作 4**：写入 `verify_logic.py` 和 `verify.sh`。
完成后输出：`[写入] verify_logic.py ✓` / `[写入] verify.sh ✓`

向用户确认：
```
探索基本清晰，请确认：

结论：<2-3句话>
验收方式：
1. <检查条目>
2. <检查条目>

确认后运行 /planner 补全验收脚本，然后启动循环。
如需继续探索，再次运行 /explore。
```

用户确认后，**操作 5**：更新 `.{{USERNAME}}/CLAUDE.md` 的 `<!-- TASK_START -->` 区域：
```
问题：<一句话>
入口：<运行命令或文件路径>
相关模块：<来自探索报告>
verify：bash .{{USERNAME}}/workspace/<slug>/verify.sh
```
完成后输出：`[写入] CLAUDE.md 任务区 ✓`

---

## ✅ 本次运行结束前必须确认

完成所有写入后，逐项输出确认（未触发的项标注"不适用"）：

```
[完成确认]
- explore-report.md 已追加        ✓ / 不适用
- project/<module>.md 已追加      ✓ / 不适用
- project-index.md 已更新         ✓ / 不适用
- env.md 已写入                   ✓ / 不适用
- verify_logic.py 已生成/更新     ✓ / 不适用
- CLAUDE.md 任务区已更新          ✓ / 不适用
```

---

## 禁止行为
- 不修复问题
- 不覆盖已有 memory，只追加
- 结论不清晰时不强行草拟验收脚本
- 不确定的地方不猜测，明确标记
- 用户确认前不更改已有 slug
- **不在文件写入完成前向用户输出探索结论**
