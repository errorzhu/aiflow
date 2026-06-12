# tddloop — TDD 循环流程编排工具

自动化 TDD 工作流：定义验证条件 → 生成测试骨架 → 编写测试 → 实现代码 → 全量验证。

## 快速开始

```bash
# 1. 安装到 PATH（任选一种）
./install.sh                              # 安装到 ~/.local/bin
./install.sh /usr/local/bin               # 安装到系统目录 (需要 sudo)

# 2. 在任意项目目录初始化
cd ~/my-project
tddloop init

# 3. 让 Codex 识别 skill（可选）
cp -r .codex/SKILL.md .codex/agents/ .agents/

# 4. 开始 TDD 开发
tddloop status
tddloop run "你的需求描述"
```

## 工作流

```
tddloop init          → 初始化项目配置 + skill
tddloop write '...'   → 定义验证条件（cases + assumptions）
tddloop run "..."     → 生成测试骨架，提示 agent 填充
              ↳ agent 写测试，运行 pytest
tddloop mark-covered  → 标记 cases 已覆盖
tddloop run "..."     → 自动全量验证 + lint → mark done
tddloop export        → 导出 conditions.md
```

## 配置说明

`tddloop.json`:

| 字段 | 说明 | 默认值 |
|---|---|---|
| `app_entry` | CLI 入口 | `src/main.py` |
| `python_prefix` | Python 前缀 (poetry run, uv run) | `""` |
| `test_runner` | 单文件测试命令 | `pytest {test_file} -v` |
| `test_runner_all` | 全量测试命令 | `pytest tests/ -v` |
| `lint` | Lint 命令 | `flake8 src/` |
| `auto_mark_done` | 自动标记完成 | `true` |
| `max_retries` | 最大重试次数 | `3` |

## 目录结构

```
tddloop-release/
├── README.md
├── install.sh          # 安装脚本
├── SKILL.md            # Codex skill 定义
├── agents/             # Skill agent 配置
├── assets/             # 原始模板
├── tddloop.json        # 项目配置模板
└── tddloop.py          # 工具本体 (Python 3, 零依赖)
```

## 环境要求

- Python 3.10+
- pytest (可选，用于运行测试)
