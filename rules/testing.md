# Testing

## Coverage: 80% Minimum

100% for auth, payments, financial calculations.

## Required Test Types

| Type | Scope | When |
|------|-------|------|
| Unit | Functions, utilities | Every new function |
| Integration | API endpoints, DB ops | Every endpoint |
| E2E | Critical user flows | Before releases |

## TDD Workflow

1. Write test (RED) — must fail
2. Implement (GREEN) — minimum to pass
3. Refactor (IMPROVE) — tests stay green
4. Coverage check — fill gaps

## Test Quality

- One behavior per test
- Independent — no shared mutable state
- Descriptive names: `"returns 404 when user not found"`
- Test behavior, not implementation details

## On Failure

- Fix implementation, not tests (unless test is wrong)
- Run `/tdd` for TDD guidance
- Run `/fix` for build errors

## Reference

See `skills/tdd-patterns/SKILL.md` for examples and mocking patterns.
