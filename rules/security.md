# Security

Mandatory checks before every commit.

## Pre-Commit Requirements

- [ ] No hardcoded secrets
- [ ] All user inputs validated with schema
- [ ] No SQL/command/XSS injection vectors
- [ ] Auth on every endpoint
- [ ] Authorization at resource level
- [ ] Error messages don't leak internals

## Secrets

- NEVER hardcode — environment variables or secret manager
- Validate required secrets at startup
- Rotate immediately if exposed in code, logs, or errors

## Auto-Escalation

Use **security-scanner** agent automatically when touching:
- Authentication / authorization code
- User input handling / file uploads
- Database queries with user data
- Payment or financial logic
- API endpoints

## Emergency Protocol

1. STOP current work
2. Run `/scan`
3. Fix CRITICAL issues before anything else
4. Rotate exposed secrets
5. Search codebase for similar patterns

## Reference

See `skills/security-checklist/SKILL.md` for full checklist.
