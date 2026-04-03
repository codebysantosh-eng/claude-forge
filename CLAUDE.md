# CLAUDE.md

## Project Overview

Claude Forge is a development system for Claude Code — 8 agents, 12 commands, 9 hooks, 3 skills, and 5 rules covering the full lifecycle from research to deployment.

## Structure

- `agents/` — 8 specialized agents (markdown with YAML frontmatter)
- `commands/` — 12 slash commands (markdown with description frontmatter)
- `hooks/` — Safety hooks (JSON) + documentation
- `skills/` — Deep reference patterns for agents to pull from
- `rules/` — Always-on guardrails

## Agent → Command Map

| Agent | Command | Role |
|-------|---------|------|
| architect | `/design` | Research + design + plan |
| tdd-developer | `/tdd` | Build test-first |
| error-resolver | `/fix` | Fix build errors |
| code-inspector | `/inspect` | Review code (local + PR) |
| security-scanner | `/scan` | Security audit |
| e2e-runner | `/e2e` | E2E tests (Playwright) |
| performance-profiler | `/profile` | Performance profiling |
| code-explorer | `/explore` | Map codebases |
| *(none)* | `/learn` | Extract patterns |
| *(none)* | `/healthcheck` | Verification suite |
| *(none)* | `/pre-deploy` | Deploy readiness |

## Conventions

- File naming: lowercase with hyphens
- Agents: YAML frontmatter with name, description, tools, model
- Commands: description frontmatter, $ARGUMENTS for input
- Skills: SKILL.md in named subdirectory
- Rules: short guardrails that reference skills for detail
