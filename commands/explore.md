---
description: Explore and map an unfamiliar codebase. Generate onboarding guide and CLAUDE.md.
---

# /explore

Invoke the **code-explorer** agent to understand a codebase.

## What It Does

1. **Recon** — Scans package manifests, frameworks, entry points, structure, tooling, tests
2. **Map** — Identifies tech stack, architecture, key directories, data flow
3. **Detect** — Finds conventions (naming, commits, error handling, test patterns)
4. **Generate** — Produces onboarding guide + starter CLAUDE.md

## When to Use

- First time in a new project
- After cloning or forking a repo
- "What is this codebase?"
- Need a CLAUDE.md for a project that doesn't have one

## Output

- **Onboarding Guide** — Tech stack, architecture, entry points, commands, conventions
- **CLAUDE.md** — Project instructions for Claude Code (if none exists)

## After Exploring

- `/research` — If you need to evaluate this project against alternatives
- `/design` — If you're ready to plan a feature
- `/tdd` — If you're ready to build

## Agent

`agents/code-explorer.md`
