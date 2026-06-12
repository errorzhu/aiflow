---
name: tddloop
description: TDD loop workflow automation. Use when the user asks to implement a feature, write tests, run the TDD cycle, or check verification conditions. Triggers on requests like "implement X", "add feature Y", "run tddloop", "tdd loop", "write tests for", or any feature implementation task in a repo that has tddloop.json.
---

# TDD Loop

## Overview

Automate the TDD cycle: read verification conditions, generate test skeletons, validate implementation, and mark conditions complete — all through `tddloop.py`.

## Quick Start

Always start by reading the project config:

```
cat tddloop.json
```

This tells you the test runner, lint command, and path conventions for this project.

## Core Commands

### Check status

```bash
python3 tddloop.py status
```

Shows all conditions and their state (pending/partial/done). Run this first whenever the user asks about implementation progress.

### Run TDD loop for a requirement

```bash
python3 tddloop.py run "<requirement>"
```

This is the main workflow. It will:

1. Look up or create a condition matching the requirement
2. If condition exists and has uncovered cases: generate test file skeleton with function stubs
3. If all cases covered: auto-run full test suite + lint, then mark done
4. If requirement is new: instruct to use `write` subcommand first

### Write a new condition

```bash
python3 tddloop.py write '{"requirement":"...", "cases":[...], "assumptions":[...]}'
```

Use when creating a brand new verification condition from requirements.

### Mark cases as covered

```bash
python3 tddloop.py mark-covered <condition-id> --cases C00X-1 C00X-2
```

Call after implementing tests and getting them green.

### Export markdown

```bash
python3 tddloop.py export
```

Regenerates `conditions/conditions.md` from the JSON data.

## Workflow

When a user asks to implement something, follow this sequence:

1. **Read config**: `cat tddloop.json`
2. **Check existing conditions**: `python3 tddloop.py status`
3. **Start or resume loop**: `python3 tddloop.py run "<requirement>"`
4. **If new condition needed**: write the condition JSON with cases covering happy path, edge cases, and error paths, then re-run step 3
5. **If test skeleton generated**: read the generated test file, fill in real test logic for each stub, then run `python3 -m pytest <test_file> -v`
6. **If tests red**: implement minimal code to make them green, re-run tests
7. **If tests green**: run `python3 tddloop.py mark-covered <id> --cases ...`, then re-run `python3 tddloop.py run "<requirement>"` to trigger auto-mark-done with full validation
8. **Done**: report completion to user

## Key Rules

- Never skip the test-red phase — confirm tests fail before implementing
- Only write minimal implementation to pass tests
- Always run full test suite (`test_runner_all`) before marking done
- Respect `max_retries` from config (default 3) — if same error persists, stop and ask user
- `python_prefix` in config adapts to the project's Python environment (poetry run, uv run, etc.)
