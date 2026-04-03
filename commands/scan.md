---
description: Run a security scan — OWASP Top 10, secrets detection, injection patterns, dependency CVEs.
---

# /scan

Invoke the **security-scanner** agent for a vulnerability audit.

## What It Does

1. Runs automated scans (`npm audit`, secret grep, dangerous patterns)
2. Walks through OWASP Top 10 systematically
3. Pattern-matches against known vulnerability signatures
4. Filters false positives (test creds, public keys, checksums)
5. Classifies findings: CRITICAL → HIGH → MEDIUM → LOW
6. Reports with exploit proof and concrete fix for each finding

## Severity Actions

| Severity | Action |
|----------|--------|
| **CRITICAL** | Block merge. Fix now. Rotate exposed secrets. |
| **HIGH** | Block merge. Fix before shipping. |
| **MEDIUM** | Merge OK with follow-up ticket. |
| **LOW** | Optional improvement. |

## When to Use

- Auth or authorization code
- User input handling, file uploads
- API endpoints, database queries
- Payment or financial logic
- Dependency updates
- Before any production release

## After Scan

- `/tdd` — Add security regression tests
- `/inspect` — Re-review after fixes
- `/pre-deploy` — Include in deployment readiness check

## Agent

`agents/security-scanner.md`
