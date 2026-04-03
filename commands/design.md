---
description: Design the system architecture and create a phased implementation plan. Waits for approval before any code is written.
---

# /design

Invoke the **architect** agent to design and plan.

## What It Does

1. Analyzes current codebase state
2. Proposes 2-3 architectural options with trade-offs
3. Creates a phased implementation plan with exact file paths
4. Identifies risks and mitigations
5. **Waits for explicit approval** before proceeding

## User Commands

| Input | Effect |
|-------|--------|
| "yes" / "proceed" / "go" | Begin implementation via `/tdd` |
| "modify: ..." | Adjust the plan |
| "different approach" | Rethink from scratch |
| "more detail on phase N" | Expand a section |

**CRITICAL**: No code is written until you approve.

## When to Use

- After `/research` delivers findings
- New feature spanning multiple files
- System design decisions
- Major refactoring or migration

## After Design

- `/tdd` — Implement the approved plan test-first
- `/fix` — If build errors arise during implementation

## Agent

`agents/architect.md`
