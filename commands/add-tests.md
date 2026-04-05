---
description: Retroactively add missing unit and integration tests to maximize coverage.
---

# /add-tests

Analyze source files, identify untested or under-tested code, and generate tests retroactively.

Accepts an optional argument: a file path, glob pattern, or "all" (default: "all").

```
/add-tests                        # scan everything
/add-tests src/routes/items.ts    # single file
/add-tests src/middleware/*.ts    # glob pattern
```

## What It Does

1. Discovers the test framework and conventions
2. Maps source files to test files and finds gaps
3. Reports a coverage gap table — waits for user confirmation
4. Generates tests matching existing project conventions
5. Runs and fixes until green
6. Reports summary

## Worked Example

```
User: /add-tests src/routes/admin.ts

Agent:

# Phase 1 — Discovery

  Test framework: vitest (vitest.config.ts)
  Test location: src/__tests__/*.test.ts
  Naming convention: {source-name}.test.ts → __tests__/{route-name}-route.test.ts

  | File                  | Status   | Routes | Tested | Missing |
  |-----------------------|----------|--------|--------|---------|
  | src/routes/admin.ts   | No tests | 6      | 0      | 6       |

  Proceed with generating tests? [waiting for confirmation]

# Phase 2 — Analysis

  Reading src/routes/admin.ts...
  Found 6 route handlers:
    - GET  /api/admin/items         (list with filters + pagination)
    - PATCH /api/admin/items/:id    (approve/reject/archive)
    - GET  /api/admin/flags         (list with filters)
    - PATCH /api/admin/flags/:id    (resolve/dismiss)
    - GET  /api/admin/users         (list with status filter)
    - PATCH /api/admin/users/:id    (suspend/reactivate)

  Studying test conventions from auth-middleware.test.ts...
    - vi.mock for Supabase client
    - app.request() for route testing
    - beforeEach for env setup

# Phase 3 — Generation

  Writing src/__tests__/admin-route.test.ts...
  41 test cases covering:
    - Happy paths (list, approve, reject, resolve, dismiss, suspend, reactivate)
    - Validation (invalid params, invalid JSON, invalid UUID)
    - Auth (missing auth → 401, non-admin → 403)
    - Errors (DB error → 500, not found → 404)

# Phase 4 — Validation

  $ npx vitest run src/__tests__/admin-route.test.ts

  PASS  src/__tests__/admin-route.test.ts
    41 tests passed ✓

  $ npx vitest run

  114 tests passed, 0 failed ✓  (no regressions)

# Phase 5 — Report

  ## Test Coverage Added

  | File               | Tests Added | Status      |
  |--------------------|-------------|-------------|
  | src/routes/admin.ts | 41 new     | All passing |

  Total: 41 new tests across 1 file
  Skipped: none
```

## The Phases

### Phase 1 — Discovery

1. **Identify test framework** — Read `package.json` for test deps (vitest, jest, mocha, etc.) and locate the config file. Note the test file pattern and location.

2. **Map source → test files** — List all source files matching the target (excluding tests, types, config). Check if a corresponding test file exists.

3. **Classify gaps** as:
   - **No tests** — no test file exists
   - **Partial** — test file exists but missing coverage
   - **Well tested** — skip

4. **Report gap analysis** — Print summary table. Ask user to confirm before generating.

### Phase 2 — Analysis

For each file needing tests (no-tests first, then partial):

5. **Read the source** — identify exports, routes, middleware, validators, classes.

6. **Read existing tests** (if partial) — avoid duplicating coverage.

7. **Study conventions** — read 1-2 existing test files for import style, mock patterns, setup/teardown, assertion style.

### Phase 3 — Generation

8. **Write tests** following these rules:
   - Match existing conventions exactly
   - One behavior per test with descriptive names
   - Happy path first, then errors, edges, boundaries
   - **Routes**: valid → response, invalid input → 400, unauthorized → 401, not found → 404, server error → 500
   - **Functions**: normal inputs, edge cases, error throwing
   - **Middleware**: pass-through on valid, block on invalid
   - Mock external deps using same patterns as existing tests
   - Test behavior, not implementation details
   - Skip type-only files

9. **Place test files** in the project's conventional location and naming.

### Phase 4 — Validation

10. **Run new tests** — use the project's test command, scoped to new files if possible.

11. **Fix failures** — adjust the test (not source code). Re-run until green. Note any tests that require source changes.

12. **Run full suite** — ensure no regressions.

### Phase 5 — Report

13. **Print summary**:
    ```
    ## Test Coverage Added

    | File | Tests Added | Status |
    |------|-------------|--------|
    | ... | N new tests | All passing |

    Total: X new tests across Y files
    Skipped: [list any that couldn't be generated and why]
    ```

## Rules

- **Do NOT modify source code** — only create/modify test files
- **Do NOT delete or modify existing passing tests**
- **Ask before proceeding** after the gap analysis
- Prioritize: auth, payments, validation → 100%; others → 80%+
- Keep tests independent — no shared mutable state
- Use specific assertions (`toBe(value)` not `toBeTruthy()`)

## Coverage Targets

| Code Type | Target |
|-----------|--------|
| Auth / payments / critical | 100% |
| Utilities / helpers | 90%+ |
| General | 80%+ |

## When to Use

- After building features without tests
- When inheriting untested code
- Before major refactors (ensure coverage first)
- During pre-production audits
- When `/healthcheck` reveals test gaps

## After add-tests

- `/inspect` — Review the generated tests for quality
- `/healthcheck` — Verify full suite passes
- `/tdd` — Switch to test-first for new features
- `/scan` — If untested code touches auth/payments
