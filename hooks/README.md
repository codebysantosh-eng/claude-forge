# Forge Hooks

Automated safety net that runs during Claude Code sessions.

## Hook Map

```
PreToolUse (before action)          PostToolUse (after action)       Stop (end of response)
┌─────────────────────┐            ┌──────────────────────┐        ┌─────────────────────┐
│ block-hook-bypass    │            │ console-log-warn     │        │ console-log-audit   │
│ pre-commit-scan      │            │ build-fail-hint      │        └─────────────────────┘
│ block-force-push     │            └──────────────────────┘
│ config-guard         │
└─────────────────────┘
```

## What Each Hook Does

| Hook | Phase | Action |
|------|-------|--------|
| `block-hook-bypass` | Pre | Blocks `--no-verify` in git commands |
| `pre-commit-scan` | Pre | Blocks commits with secrets, `console.log`, `debugger` |
| `block-force-push` | Pre | Blocks `--force` push (use `--force-with-lease`) |
| `config-guard` | Pre | Warns before modifying eslint/prettier/tsconfig/CI configs |
| `console-log-warn` | Post | Warns when `console.log` is added (skips test files) |
| `build-fail-hint` | Post | Suggests `/fix` when build commands fail |
| `console-log-audit` | Stop | Checks all modified source files for `console.log` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Continue |
| 2 | Block (PreToolUse only) |

## Installation

Merge `hooks.json` into your project's `.claude/settings.json` under the `hooks` key.
