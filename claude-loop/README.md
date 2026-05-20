# claude-loop

将 AI 自动循环工作流注入到任何已有项目，完全不干扰原有目录结构。

## 快速开始

```bash
# 注入到你的项目
bash inject.sh alice /path/to/your-project

# 进入项目，打开 Claude Code
cd /path/to/your-project && claude

# 探索问题（可多次运行，每次接续上一轮）
/explore

# 补全验收脚本
/planner

# 启动自动循环
bash .alice/loop.sh 20 .alice/workspace/<slug>/verify.sh
```

## 注入后的目录结构

```
your-project/
├── .alice/                        # 所有流程文件，完全隔离，不提交 git
│   ├── CLAUDE.md                  # L1，loop.sh 每轮动态组装
│   ├── loop.sh                    # 循环驱动
│   ├── memory/
│   │   ├── project-index.md       # 已扫描模块索引（注入 L1）
│   │   ├── env.md                 # 运行环境与配置（/explore 收集）
│   │   ├── project/               # 模块详情，按需 L2 加载
│   │   ├── errors.md              # 踩坑记录
│   │   ├── approach.md            # 方案记录
│   │   └── log/                   # 每轮原始日志，不进上下文
│   └── workspace/
│       └── <slug>/
│           ├── explore-report.md  # 探索报告（/explore 生成）
│           ├── verify_logic.py    # 验收逻辑主体
│           └── verify.sh          # 包装层，调用 verify_logic.py
└── .claude/                       # Claude Code 约定位置
    └── commands/
        ├── explore.md             # /explore
        └── planner.md             # /planner
```

## 工作流程

```
/explore  →  探索问题 + 收集环境配置 + 草拟验收脚本 + 更新 CLAUDE.md
                ↓
          用户确认方向（可多次 /explore 直到清晰）
                ↓
/planner  →  补全 verify_logic.py 的断言逻辑
                ↓
loop.sh   →  自动循环，直到 verify.sh 通过
```

## 三层记忆

| 层 | 文件 | 加载方式 | 内容 |
|----|------|----------|------|
| L1 | `memory/l1-summary.md` + `project-index.md` | 自动（loop.sh 注入） | 当前状态 + 模块索引 |
| L2 | `memory/env.md` `memory/project/*.md` 等 | 按需 Read | 环境配置、模块详情、踩坑、方案 |
| L3 | `memory/log/` | 不加载 | 每轮完整输出，人工查阅用 |

## 多人使用

```bash
bash inject.sh alice /path/to/project   # .alice/
bash inject.sh bob   /path/to/project   # .bob/
```

各自隔离，互不干扰，.gitignore 自动配置。
