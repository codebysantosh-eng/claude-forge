---
description: Fix build, type, and compile errors incrementally. One error at a time, minimal changes.
---

# /fix

Invoke the **error-resolver** agent to make the build green.

## What It Does

1. Detects build system (TypeScript, Rust, Go, Python, Java)
2. Runs build, captures errors
3. Groups by file, sorts by dependency order
4. Fixes one error at a time: read → diagnose → fix → verify → next
5. Stops and asks if a fix makes things worse

## Guardrails

Stops and asks if:
- Fix introduces more errors than it resolves
- Same error persists after 3 attempts
- Fix requires architectural changes
- Missing dependencies need installation

## What It Does NOT Do

- Refactor code
- Add features
- Improve quality
- Install packages without asking

## When to Use

- Build or type check fails
- After dependency upgrades
- After merges that broke things
- When CI is red

## After Fix

- `/healthcheck` — Verify everything passes
- `/inspect` — Review the changes
- Back to `/tdd` — Continue implementing

## Agent

`agents/error-resolver.md`
