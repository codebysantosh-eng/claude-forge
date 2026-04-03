# Git

## Commits

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`

```bash
# ✓ Good
feat(auth): add OAuth2 login
fix(api): handle null user in response

# ✗ Bad
"fixed stuff"
"WIP"
```

## Branches

- `main` = always deployable, protected
- `feature/...`, `fix/...` from main
- Keep branches < 3 days
- Delete after merge

## PRs

- Title: `type(scope): description`
- Body: What, Why, How, Test Plan
- < 500 lines preferred

## Never

- Commit to main directly
- Commit secrets
- Force push shared branches (use `--force-with-lease`)
- Skip hooks (`--no-verify`)
