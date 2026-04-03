# Performance

## Model Selection Strategy

Choose the right Claude model for the task:

| Model | Cost | Best For |
|-------|------|----------|
| **Haiku 4.5** | Lowest | Lightweight agents, pair programming, worker agents in multi-agent systems. 90% of Sonnet capability at 3x cost savings. |
| **Sonnet 4.6** | Mid | Main development work, code generation, multi-agent orchestration, complex coding tasks. Best coding model. |
| **Opus 4.6** | Highest | Architectural decisions, deep reasoning, research, analysis. Use when quality of thought matters more than speed. |

**Default**: Use Sonnet unless the task requires deep reasoning (→ Opus) or is lightweight/repetitive (→ Haiku).

## Context Window Management

Avoid the last 20% of context window for:
- Large-scale refactoring (many files)
- Feature implementation spanning multiple files
- Debugging complex cross-file interactions

Lower context sensitivity (safe even near limits):
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

**When context is getting long**: Use `/explore` to generate a CLAUDE.md, then start a new session with that context.

## Extended Thinking

Extended thinking is enabled by default (up to 31,999 tokens for reasoning).

| Control | How |
|---------|-----|
| Toggle | Option+T (macOS) / Alt+T (Windows/Linux) |
| Config | `alwaysThinkingEnabled` in `~/.claude/settings.json` |
| Budget cap | `export MAX_THINKING_TOKENS=10000` |

**Use extended thinking for**: Architectural decisions, complex debugging, multi-step planning.
**Disable for**: Simple edits, formatting, documentation — saves tokens.

## Agent Cost Awareness

- Flag workflows that escalate to Opus without clear reasoning need
- Default to Sonnet for code generation and review
- Use Haiku for repetitive worker tasks (formatting, simple checks)
- Batch similar operations instead of invoking agents per-file

## Reference

See `agents/performance-profiler.md` for code-level performance optimization.
