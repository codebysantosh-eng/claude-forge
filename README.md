# Claude Forge

Where raw ideas become production-ready code.

8 agents, 12 commands, 9 hooks, 3 skills, 5 rules — a complete development system for Claude Code. Every agent has a clear role, every command maps to an action, and everything is wired together with handoffs.

## Agents

| Agent | Role | Model |
|-------|------|-------|
| **architect** | Research solutions, design systems, plan implementations, document decisions | opus |
| **tdd-developer** | Build test-first — Red/Green/Refactor with 80%+ coverage | sonnet |
| **error-resolver** | Fix build/type/compile errors — one at a time, minimal diffs | sonnet |
| **code-inspector** | Review for correctness, quality, React/backend patterns, AI code | sonnet |
| **security-scanner** | Scan for vulnerabilities — OWASP Top 10, secrets, injection | sonnet |
| **e2e-runner** | Create, run, and maintain Playwright E2E tests for critical flows | sonnet |
| **performance-profiler** | Profile bottlenecks — algorithms, bundle, queries, rendering | sonnet |
| **code-explorer** | Map unfamiliar codebases, generate onboarding guides + CLAUDE.md | sonnet |

## Commands

| Command | Action | Agent |
|---------|--------|-------|
| `/design` | Research + design + implementation plan | architect |
| `/tdd` | Test-driven development | tdd-developer |
| `/fix` | Fix build errors incrementally | error-resolver |
| `/inspect` | Review code (local or PR with full 7-phase pipeline) | code-inspector |
| `/scan` | Security vulnerability audit | security-scanner |
| `/e2e` | E2E tests with Playwright (Page Object Model, artifacts) | e2e-runner |
| `/profile` | Performance profiling and optimization | performance-profiler |
| `/explore` | Map and understand a codebase | code-explorer |
| `/learn` | Extract reusable patterns from current session | *(direct)* |
| `/healthcheck` | Build + types + lint + tests + secrets scan | *(direct)* |
| `/pre-deploy` | Deployment readiness checklist | *(direct)* |

## How It Flows

```
 ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
 │  THINK   │ →  │  BUILD   │ →  │  CHECK   │ →  │  SHIP    │
 │          │    │          │    │          │    │          │
 │ /design  │    │ /tdd     │    │ /inspect │    │/healthchk│
 │          │    │ /fix     │    │ /scan    │    │/pre-deploy│
 │ architect│    │ /e2e     │    │ /profile │    │          │
 │          │    │tdd-dev   │    │inspector │    │          │
 │          │    │err-resolv│    │sec-scan  │    │          │
 │          │    │e2e-runner│    │perf-prof │    │          │
 └──────────┘    └──────────┘    └──────────┘    └──────────┘

 /explore → Jump in anywhere. Map the codebase first.
 /learn   → Extract patterns after solving non-trivial problems.
```

Not every task needs all phases. A bug fix skips THINK. A library evaluation skips BUILD. **You decide which tools to reach for.**

## Hooks (Automated Safety)

| Hook | Phase | What |
|------|-------|------|
| block-hook-bypass | Pre | Blocks `--no-verify` in git commands |
| pre-commit-scan | Pre | Blocks commits with secrets, console.log, debugger |
| block-force-push | Pre | Blocks `--force` push |
| config-guard | Pre | Warns on linter/formatter/CI config changes |
| console-log-warn | Post | Warns on console.log in edits (skips test files) |
| build-fail-hint | Post | Suggests `/fix` on build failure |
| large-file-warn | Post | Warns when file exceeds 800 lines |
| console-log-audit | Stop | Audits modified source files for console.log |
| test-reminder | Stop | Reminds to add tests if only source files changed |

## Skills (Deep Reference)

| Skill | Lines | Used By |
|-------|-------|---------|
| `tdd-patterns` | ~350 | tdd-developer, e2e-runner — test examples, mocking, hooks, CI |
| `security-checklist` | ~350 | security-scanner — 12 categories with verification commands and security tests |
| `coding-standards` | ~330 | code-inspector — naming, immutability, async, React, API, smells |

## Rules (Always On)

| Rule | Enforces |
|------|----------|
| `code-quality` | Immutability, function/file size, naming, no console.log |
| `security` | Pre-commit checks, secret management, auto-escalation |
| `testing` | 80% coverage, TDD workflow, test quality |
| `git` | Conventional commits, branch hygiene, PR standards |
| `performance` | Model routing (Haiku/Sonnet/Opus), context window management, extended thinking |

## Quick Start

```bash
# Clone
git clone https://github.com/codebysantosh-eng/claude-forge.git
cd claude-forge

# Install globally (available in all projects)
./install.sh

# Or install to a specific project
./install.sh --project /path/to/your-project
```

> **Hooks** require manual setup — merge `hooks/hooks.json` into your `.claude/settings.json`.

## Philosophy

1. **Agents have roles, not numbers** — Reach for the right tool, not the next step in a pipeline
2. **Commands match agents** — `/inspect` → code-inspector. `/scan` → security-scanner. No guessing.
3. **Skills are reference, not workflow** — Agents carry workflow; skills are lookup tables
4. **Rules are guardrails** — Always on, always enforced, never in the way
5. **Hooks are a safety net** — Catch mistakes before they become commits
6. **Research is part of design** — The architect researches, designs, and plans in one flow

## License

MIT
