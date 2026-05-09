# 🐘🐟 大象-金鱼 Claude Code 框架
**Elephant-Goldfish Workflow for Claude Code**

> **核心理念**：在 AI 时代，设计即代码。在写任何代码之前，先把设计决策变成清晰、可验证的文档。

---

## 快速开始

### 1. 将此目录复制到你的项目根目录

```bash
cp -r elephant-goldfish/. your-project/
```

### 2. 目录结构

```
your-project/
├── CLAUDE.md                    # Agent 操作手册（Claude Code 自动读取）
├── claude-progress.md           # 会话进度日志
├── feature_list.json            # 功能状态追踪
├── docs/                        # 设计文档（唯一真理来源）
│   └── elephant-goldfish-model.md  # 模型原理文档
├── scripts/
│   └── readme-generator.sh     # 现有代码库 README 生成辅助脚本
└── .claude/
    └── commands/               # 斜杠命令（Claude Code 自动识别）
        ├── design-start.md     # /design-start — 开始设计讨论
        ├── design-draft.md     # /design-draft — 生成设计文档
        ├── goldfish-test.md    # /goldfish-test — 理解力测试
        ├── goldfish-critic.md  # /goldfish-critic — 批评者审查
        ├── goldfish-ready.md   # /goldfish-ready — 就绪检查
        ├── implement.md        # /implement — 实施编码
        ├── code-review.md      # /code-review — 毒舌代码评审
        └── done.md             # /done — 会话结束清单
```

### 3. 开始使用

在 Claude Code 中，直接输入斜杠命令即可触发对应流程。

---

## 斜杠命令速查

| 命令 | 阶段 | 用途 |
|------|------|------|
| `/design-start` | 🐘 大象 | 开始新功能的设计讨论，建立"不写代码"规则 |
| `/design-draft` | 📄 文档 | 逐段生成设计文档草稿 |
| `/goldfish-test` | 🐟 金鱼 | 理解力测试：文档是否自洽完整？ |
| `/goldfish-critic` | 🐟 金鱼 | 批评者审查：找出所有设计漏洞 |
| `/goldfish-ready` | 🐟 金鱼 | 就绪检查：能否一次成功实施？ |
| `/implement` | ⚙️ 实施 | 根据设计文档生成代码（严格遵循文档） |
| `/code-review` | ⚙️ 实施 | 毒舌代码评审：找出所有代码问题 |
| `/done` | 📝 收尾 | 会话结束清单，更新进度日志 |

---

## 工作流程

```
你想开发一个新功能
        ↓
/design-start        ← 🐘 大象：讨论设计，禁止写代码
        ↓
/design-draft        ← 📄 文档：逐段生成设计文档
        ↓
/goldfish-test       ← 🐟 金鱼1：理解力测试
        ↓ (通过)
/goldfish-critic     ← 🐟 金鱼2：批评者审查
        ↓ (通过)
/goldfish-ready      ← 🐟 金鱼3：就绪检查
        ↓ (通过)
[人工审批]           ← 👤 人工：团队评审设计文档
        ↓
/implement           ← ⚙️ 实施：严格按文档生成代码
        ↓
/code-review         ← 🔥 评审：毒舌找问题
        ↓
/done                ← 📝 收尾：更新进度日志
```

---

## 对于现有代码库

如果你的项目已经有大量代码，先运行 README 生成脚本：

```bash
chmod +x scripts/readme-generator.sh
./scripts/readme-generator.sh /path/to/your/project
```

脚本会生成逐步操作指南，帮你自下而上地为现有代码库建立 README 层级体系。

---

## 核心原则

- 🚫 **不要在设计阶段写代码**——过早写代码会产生无法维护的技术债
- ✅ **文档是唯一真理来源**——代码必须遵循文档，不是相反
- 🔍 **金鱼不撒谎**——只有通过金鱼测试的文档，才是真正完整的文档
- 💬 **质疑是美德**——好的 AI 助手应该挑战你的假设，而不是一味称好
- 📝 **每次会话都要更新进度**——好文档让新会话在 30 秒内恢复工作

---

## 背景

此框架基于 Snippets Machine 团队的内部实践，核心理念来自"大象-金鱼模型"。  
原始文档见：`docs/elephant-goldfish-model.md`
