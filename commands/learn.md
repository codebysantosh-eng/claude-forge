---
description: Extract reusable patterns from the current session and save them as skills for future use.
---

# /learn

Review the current session for patterns worth saving. No agent — this is a direct extraction workflow.

## What to Extract

| Pattern Type | Example |
|-------------|---------|
| **Error resolution** | "Error X means root cause Y — fix with Z" |
| **Debugging technique** | "To debug flaky WebSocket, enable trace and check..." |
| **Workaround** | "Library X has a bug with Y in v3 — use Z instead" |
| **Project convention** | "This codebase uses pattern X for all API routes" |
| **Integration pattern** | "Connecting A to B requires these specific config steps" |

## What NOT to Extract

- Typo fixes or simple syntax errors
- One-time environment issues
- Patterns already documented in project
- Trivial knowledge (basic imports, simple syntax)

## Process

1. Review session for non-trivial problem-solving
2. Identify the most reusable insight
3. Draft the skill file
4. **Ask user to confirm** before saving
5. Save to `~/.claude/skills/learned/[pattern-name].md`

## Output Format

```markdown
---
name: [descriptive-name]
description: [one-line summary]
---

# [Pattern Name]

## Problem
[What situation triggers this — be specific]

## Solution
[Step-by-step fix or technique]

## Example
[Code showing the pattern in action]

## When to Use
- [Trigger condition 1]
- [Trigger condition 2]
```

## Rules

- One pattern per skill — keep focused
- Include enough context to be useful without the original conversation
- Never write to filesystem without user confirmation
- Only extract what will save time in future sessions
