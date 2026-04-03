---
description: Review code for bugs, security, performance, and maintainability. Works on local changes or GitHub PRs with full review pipeline.
argument-hint: [pr-number | pr-url | blank for local]
---

# /inspect

Invoke the **code-inspector** agent to review code.

**Input**: $ARGUMENTS

## Mode Selection

If `$ARGUMENTS` contains a PR number, PR URL, or `--pr` → **PR Inspection**
Otherwise → **Local Inspection**

---

## Local Inspection

1. `git diff --name-only HEAD` — find changed files
2. If no changes: "Nothing to inspect."
3. Read each changed file **in full** (not just the diff — you need surrounding context)
4. Apply checklist: Security (CRITICAL) → Quality (HIGH) → React/Backend (HIGH) → Performance (MEDIUM) → Style (LOW)
5. Report with severity-ranked findings and verdict

---

## PR Inspection (Full Pipeline)

### Phase 1: Fetch

```bash
gh pr view <NUMBER> --json number,title,body,author,baseRefName,headRefName,changedFiles,additions,deletions
gh pr diff <NUMBER>
```

If PR not found → stop with error.

### Phase 2: Build Context

1. Read `CLAUDE.md` and project rules for conventions
2. Parse PR description for goals, linked issues, test plan
3. List all changed files — categorize: source, test, config, docs
4. Check for related plans or design docs

### Phase 3: Deep Review

Read each changed file **in full at PR head** (not just diff hunks):

```bash
gh pr diff <NUMBER> --name-only | while read -r file; do
  gh api "repos/{owner}/{repo}/contents/$file?ref=<head-branch>" --jq '.content' | base64 -d
done
```

Review across 7 categories:

| Category | What to Check |
|----------|--------------|
| **Correctness** | Logic errors, off-by-ones, null handling, race conditions |
| **Type Safety** | Mismatches, unsafe casts, `any` usage |
| **Patterns** | Matches project conventions (naming, structure, imports) |
| **Security** | Injection, auth gaps, secrets, SSRF, XSS |
| **Performance** | N+1 queries, missing indexes, unbounded loops, memory leaks |
| **Completeness** | Missing tests, error handling, migrations, docs |
| **Maintainability** | Dead code, magic numbers, deep nesting, unclear naming |

### Phase 4: Validate

Detect project type and run checks:

| Project | Commands |
|---------|----------|
| Node.js/TS | `npx tsc --noEmit` → `npm run lint` → `npm test` → `npm run build` |
| Rust | `cargo clippy -- -D warnings` → `cargo test` → `cargo build` |
| Go | `go vet ./...` → `go test ./...` → `go build ./...` |
| Python | `mypy src/` → `pytest` |

### Phase 5: Decide

| Condition | Decision |
|-----------|----------|
| Zero CRITICAL/HIGH, validation passes | **APPROVE** |
| Only MEDIUM/LOW, validation passes | **APPROVE with comments** |
| Any HIGH or validation failure | **REQUEST CHANGES** |
| Any CRITICAL | **BLOCK** |

Draft PR → Always **COMMENT** (never approve/block drafts).

### Phase 6: Publish to GitHub

```bash
# Approve
gh pr review <NUMBER> --approve --body "<summary>"

# Request changes
gh pr review <NUMBER> --request-changes --body "<required fixes>"

# Comment only (draft PRs)
gh pr review <NUMBER> --comment --body "<observations>"
```

For inline comments on specific lines:
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" \
  -f body="<comment>" -f path="<file>" -F line=<N> -f side="RIGHT" \
  -f commit_id="$(gh pr view <NUMBER> --json headRefOid --jq .headRefOid)"
```

### Phase 7: Report to User

```
PR #42: Add subscription billing
Decision: APPROVE WITH COMMENTS

Issues: 0 critical, 0 high, 2 medium, 1 low
Validation: 4/4 checks passed

Files reviewed: 5 (3 source, 1 test, 1 migration)
```

---

## Edge Cases

- **No `gh` CLI**: Fall back to local inspection. Warn user.
- **Diverged branch**: Suggest rebase before inspection.
- **Large PR (>50 files)**: Warn about scope. Focus: source → tests → config → docs.

## After Inspection

- `/scan` — Deep security audit for sensitive code
- `/fix` — Fix issues found
- `/healthcheck` — Final verification before merge

## Agent

`agents/code-inspector.md`
