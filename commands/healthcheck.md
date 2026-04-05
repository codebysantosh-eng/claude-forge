---
description: Run all verification checks — build, types, lint, format, tests, secrets, console.log. Stops on first failure.
---

# /healthcheck

Run comprehensive verification. No agent — this is a direct check pipeline.

## Pipeline

Execute in order, stop on critical failure:

| Step | Check | Pass |
|------|-------|------|
| 1 | **Build** | Exit code 0 |
| 2 | **Type check** | No type errors |
| 3 | **Lint** | No errors (warnings OK) |
| 4 | **Format** | `npm run format:check` passes (Prettier) |
| 5 | **Tests** | All passing, coverage reported |
| 6 | **Secrets scan** | No hardcoded secrets in source |
| 7 | **Console.log** | None in source files (test files OK) |
| 8 | **Git status** | Show uncommitted changes |

If build or types fail → report errors and STOP.

## Modes

| Mode | Flag | Checks |
|------|------|--------|
| Quick | `/healthcheck quick` | Build + types only |
| Full | `/healthcheck` | All 8 (default) |
| Pre-commit | `/healthcheck pre-commit` | Build + types + lint + format + secrets + console.log |
| Pre-PR | `/healthcheck pre-pr` | All + security scan via **security-scanner** |

## Output

```
Healthcheck Report
───────────────────────────────
Build       ✓ PASS
Types       ✓ PASS
Lint        ✓ PASS  (2 warnings)
Format      ✓ PASS
Tests       ✓ PASS  87/87  coverage: 84%
Secrets     ✓ PASS
Logs        ✓ PASS
───────────────────────────────
Status: HEALTHY — ready to commit
```

## On Failure

| Failure | Suggested Fix |
|---------|--------------|
| Build errors | `/fix` |
| Format issues | `npm run format` to auto-fix |
| Low coverage | `/tdd` to add tests |
| Secrets found | Move to env vars immediately |
| Console.log | Remove from source files |

## Arguments

$ARGUMENTS: `quick` | `full` | `pre-commit` | `pre-pr`
