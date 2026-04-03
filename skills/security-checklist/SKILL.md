---
name: security-checklist
description: Deep reference for security scanning — secrets, input validation, injection, auth, XSS, CSRF, rate limiting, data protection, dependencies, headers, cloud security, and security testing patterns.
---

# Security Checklist Reference

Deep reference for the **security-scanner** agent. Checklists, code patterns, and verification commands.

## 1. Secrets Management

```typescript
// ✗ NEVER
const stripe = new Stripe("sk_live_abc123");
const dbUrl = "postgres://admin:password@prod:5432/app";

// ✓ ALWAYS
const key = process.env.STRIPE_SECRET_KEY;
if (!key) throw new Error("STRIPE_SECRET_KEY required");
const stripe = new Stripe(key);
```

**Verification**:
```bash
# Search for hardcoded secrets
grep -rn "password\s*=\|api_key\s*=\|secret\s*=\|token\s*=" --include="*.{ts,js,py,go}" src/ lib/ app/

# Check .gitignore
grep -q ".env" .gitignore && echo "OK" || echo "MISSING: .env not in .gitignore"

# Check .env.example exists
test -f .env.example && echo "OK" || echo "MISSING: .env.example"
```

- [ ] No hardcoded secrets in source
- [ ] `.env` in `.gitignore`
- [ ] `.env.example` with placeholder values
- [ ] Required env vars validated at startup (fail fast)
- [ ] Secrets never in logs or error messages

## 2. Input Validation

```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).trim(),
  role: z.enum(["user", "admin"]),
});

// Validate ALL external input
app.post("/users", (req, res) => {
  const data = CreateUserSchema.parse(req.body);
  return createUser(data); // data is typed and safe
});

// File upload validation
const MAX_SIZE = 5 * 1024 * 1024; // 5MB
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

function validateUpload(file: File) {
  if (file.size > MAX_SIZE) throw new Error("File too large (max 5MB)");
  if (!ALLOWED.includes(file.type)) throw new Error("Invalid file type");
  // Also validate magic bytes, not just extension/MIME
}
```

**Verification**:
```bash
# Find endpoints without validation
grep -rn "req.body\|req.params\|req.query" --include="*.{ts,js}" src/ | grep -v "parse\|validate\|schema"
```

- [ ] Every API endpoint validates input with schema
- [ ] File uploads check size, type, and magic bytes
- [ ] Whitelist approach (allow known-good, reject everything else)
- [ ] No user input passed directly to SQL, shell, file paths, or HTML

## 3. Injection Prevention

| Type | Vector | Prevention |
|------|--------|-----------|
| **SQL** | String concatenation | Parameterized queries, ORM |
| **Command** | `exec(userInput)` | `execFile` with args array |
| **XSS** | `innerHTML = userInput` | Framework escaping, DOMPurify, CSP |
| **Path traversal** | `readFile(userPath)` | `path.resolve()` + validate in allowed dir |
| **SSRF** | `fetch(userUrl)` server-side | Whitelist domains, block internal IPs |
| **Template** | User input as template | Never pass user input to template engines |

```typescript
// ✗ SQL injection
db.query(`SELECT * FROM users WHERE id = '${userId}'`);
// ✓ Parameterized
db.query("SELECT * FROM users WHERE id = $1", [userId]);

// ✗ Command injection
exec(`convert ${userFilename} output.png`);
// ✓ Safe argument passing
execFile("convert", [userFilename, "output.png"]);

// ✗ Path traversal
fs.readFile(`uploads/${userPath}`);
// ✓ Validated path
const resolved = path.resolve("uploads", userPath);
if (!resolved.startsWith(path.resolve("uploads"))) throw new Error("Invalid path");
fs.readFile(resolved);
```

**Verification**:
```bash
grep -rn "SELECT.*\\\${\|INSERT.*\\\${" --include="*.{ts,js}" src/
grep -rn "\bexec(" --include="*.{ts,js}" src/
grep -rn "innerHTML\|dangerouslySetInnerHTML" --include="*.{ts,tsx,js,jsx}" src/
```

## 4. Authentication

```typescript
import bcrypt from "bcrypt";

// Password hashing — NEVER MD5/SHA for passwords
const hash = await bcrypt.hash(password, 12);
const valid = await bcrypt.compare(input, hash);

// JWT with proper claims
const token = jwt.sign(
  { sub: user.id, role: user.role },
  process.env.JWT_SECRET!,
  { expiresIn: "1h", audience: "myapp", issuer: "myapp" }
);

// Verify with all claims
const payload = jwt.verify(token, process.env.JWT_SECRET!, {
  audience: "myapp",
  issuer: "myapp",
});

// Session cookies — httpOnly prevents XSS token theft
res.cookie("session", token, {
  httpOnly: true,    // Not accessible via document.cookie
  secure: true,      // HTTPS only
  sameSite: "strict", // CSRF protection
  maxAge: 3600000,   // 1 hour
  path: "/",
});
```

- [ ] Passwords hashed with bcrypt (cost 12+) or argon2
- [ ] JWT has expiry, audience, and issuer claims
- [ ] Sessions in httpOnly + Secure + SameSite cookies
- [ ] Token refresh mechanism for long sessions
- [ ] Logout invalidates session server-side

## 5. Authorization

```typescript
// ✗ Only checks authentication, not authorization
app.get("/api/users/:id", requireAuth, async (req, res) => {
  const user = await db.users.findById(req.params.id);
  return res.json(user); // Any logged-in user can see ANY user
});

// ✓ Checks authorization — user can only access OWN data
app.get("/api/users/:id", requireAuth, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== "admin") {
    return res.status(403).json({ error: "Forbidden" });
  }
  const user = await db.users.findById(req.params.id);
  return res.json(user);
});
```

- [ ] Every endpoint checks authentication (who are you?)
- [ ] Every endpoint checks authorization (can YOU access THIS resource?)
- [ ] Row Level Security for database (Supabase/Postgres)
- [ ] Admin endpoints protected by role check
- [ ] Never rely on client-side authorization

## 6. XSS Prevention

```typescript
// React auto-escapes by default — SAFE:
<div>{userComment}</div>

// ✗ DANGEROUS — bypasses React's escaping:
<div dangerouslySetInnerHTML={{ __html: userComment }} />

// ✓ If you MUST render HTML, sanitize:
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userComment) }} />
```

**Content Security Policy**:
```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;
```

- [ ] No `dangerouslySetInnerHTML` without DOMPurify
- [ ] CSP headers configured
- [ ] No `eval()`, `Function()`, or `document.write()` with user input

## 7. CSRF Protection

```typescript
// SameSite cookies (primary defense)
res.cookie("session", token, { sameSite: "strict" });

// CSRF token for forms (defense in depth)
const csrfToken = crypto.randomUUID();
req.session.csrfToken = csrfToken;
// Validate on state-changing requests
if (req.body._csrf !== req.session.csrfToken) return res.status(403).send("CSRF");
```

- [ ] Cookies use `SameSite=Strict` or `Lax`
- [ ] CSRF tokens on state-changing forms
- [ ] CORS configured for known origins only

## 8. Rate Limiting

```typescript
import rateLimit from "express-rate-limit";

// General API
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  message: { error: "Too many requests. Try again later." },
});

// Aggressive on auth
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: "Too many login attempts. Try again in 15 minutes." },
});

// Tight on expensive operations
const searchLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
});

app.use("/api/", apiLimiter);
app.use("/api/auth/", authLimiter);
app.use("/api/search/", searchLimiter);
```

- [ ] All public endpoints have rate limits
- [ ] Auth endpoints: 5 attempts per 15 minutes
- [ ] Expensive operations: tight limits (search, upload, AI calls)
- [ ] Rate limit responses include `Retry-After` header

## 9. Data Protection

```typescript
// ✓ Sanitize logs
logger.info("User login", { userId: user.id }); // ID only
logger.error("Payment failed", { orderId, error: err.message }); // Not full stack

// ✗ NEVER log these
logger.info("Login", { email: user.email, password }); // PII + secret
logger.error("DB error", { connectionString: dbUrl }); // Secret

// ✓ Generic errors to users
app.use((err, req, res, next) => {
  logger.error("Internal error", { error: err.message, stack: err.stack });
  res.status(500).json({ error: "Something went wrong" }); // Never expose internals
});
```

- [ ] API responses exclude sensitive fields (hashes, tokens, internal IDs)
- [ ] Error messages generic to users, detailed in server logs only
- [ ] PII never logged (names, emails, addresses, phone numbers)
- [ ] HTTPS enforced for all connections
- [ ] Sensitive data encrypted at rest where required

## 10. Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
X-XSS-Protection: 0
```

**Verification**:
```bash
curl -I https://your-app.com | grep -i "strict-transport\|x-content-type\|x-frame\|content-security"
```

## 11. Dependencies

```bash
# Audit commands
npm audit --production
pip-audit
cargo audit
go vuln check ./...
```

- [ ] No known CRITICAL vulnerabilities
- [ ] Lock files committed (`package-lock.json`, `Cargo.lock`, etc.)
- [ ] Automated scanning in CI (Dependabot, Snyk, npm audit)
- [ ] Review new dependencies before installing

## 12. Security Testing

```typescript
describe("Authentication", () => {
  it("rejects requests without token", async () => {
    await request(app).get("/api/protected").expect(401);
  });

  it("rejects expired tokens", async () => {
    const expired = createToken({ exp: Math.floor(Date.now() / 1000) - 3600 });
    await request(app)
      .get("/api/protected")
      .set("Authorization", `Bearer ${expired}`)
      .expect(401);
  });

  it("rejects tampered tokens", async () => {
    await request(app)
      .get("/api/protected")
      .set("Authorization", "Bearer invalid.token.here")
      .expect(401);
  });
});

describe("Authorization", () => {
  it("prevents horizontal privilege escalation", async () => {
    const userA = createToken({ sub: "user-a" });
    await request(app)
      .get("/api/users/user-b/profile")
      .set("Authorization", `Bearer ${userA}`)
      .expect(403);
  });

  it("prevents vertical privilege escalation", async () => {
    const regular = createToken({ sub: "user-a", role: "user" });
    await request(app)
      .delete("/api/admin/users/user-b")
      .set("Authorization", `Bearer ${regular}`)
      .expect(403);
  });
});

describe("Input Validation", () => {
  it("rejects SQL injection attempts", async () => {
    await request(app)
      .get("/api/users/'; DROP TABLE users; --")
      .set("Authorization", `Bearer ${adminToken}`)
      .expect(400);
  });

  it("rejects XSS payloads", async () => {
    const res = await request(app)
      .post("/api/comments")
      .set("Authorization", `Bearer ${userToken}`)
      .send({ body: '<script>alert("xss")</script>' })
      .expect(201);

    expect(res.body.data.body).not.toContain("<script>");
  });
});

describe("Rate Limiting", () => {
  it("blocks after exceeding limit", async () => {
    for (let i = 0; i < 6; i++) {
      await request(app).post("/api/auth/login").send({ email: "a@b.com", password: "x" });
    }
    const res = await request(app).post("/api/auth/login").send({ email: "a@b.com", password: "x" });
    expect(res.status).toBe(429);
    expect(res.headers["retry-after"]).toBeDefined();
  });
});
```

## 13. Cloud & Infrastructure Security

### IAM & Access Control

```bash
# AWS — check for overly permissive policies
aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName, `Admin`)]'

# Verify MFA on root account
aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled'
```

- [ ] Principle of least privilege — no `*:*` policies
- [ ] MFA enabled on root and admin accounts
- [ ] Service accounts use IAM roles, not long-lived credentials
- [ ] Access reviewed quarterly

### Cloud Secrets Management

```bash
# Use cloud secret managers, not env files on servers
aws secretsmanager get-secret-value --secret-id my-app/prod/db-password
# Or Vercel encrypted env vars, Railway secrets, etc.
```

- [ ] Production secrets in AWS Secrets Manager / Vercel Secrets / equivalent
- [ ] Automatic rotation configured (30 days for DB creds)
- [ ] API keys rotated quarterly
- [ ] Audit logging on secret access

### Network Security

```hcl
# Terraform — database NOT publicly accessible
resource "aws_db_instance" "main" {
  publicly_accessible = false  # CRITICAL
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_security_group" "db" {
  ingress {
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]  # App servers only
  }
}
```

- [ ] Database not publicly accessible
- [ ] SSH/RDP restricted to VPN or bastion host
- [ ] Security groups follow least-privilege
- [ ] VPC flow logs enabled

### CI/CD Pipeline Security

```yaml
# GitHub Actions — use OIDC, not long-lived secrets
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/deploy
      aws-region: us-east-1
```

- [ ] OIDC authentication instead of long-lived credentials
- [ ] Secrets scanning in CI pipeline (GitHub secret scanning, gitleaks)
- [ ] Dependency vulnerability scanning on every PR
- [ ] Branch protection on main (require reviews, status checks)
- [ ] Container image scanning if using Docker

### CDN & Edge Security

- [ ] WAF configured with OWASP rule set
- [ ] Rate limiting at edge (Cloudflare, CloudFront)
- [ ] Bot protection enabled
- [ ] DDoS protection active
- [ ] SSL/TLS in strict mode (no mixed content)
- [ ] Security headers set at edge

### Backup & Disaster Recovery

- [ ] Automated daily backups
- [ ] Point-in-time recovery enabled (RDS, etc.)
- [ ] Backup restoration tested quarterly
- [ ] RPO (Recovery Point Objective) documented
- [ ] RTO (Recovery Time Objective) documented
- [ ] Deletion protection enabled on production databases

### Common Cloud Misconfigurations

| Misconfiguration | Risk | Fix |
|-----------------|------|-----|
| S3 bucket public | Data exposure | `aws s3api put-public-access-block --bucket X --public-access-block-configuration BlockPublicAcls=true,...` |
| RDS publicly accessible | Database breach | `publicly_accessible = false` + security group |
| IAM `Action: "*"` | Full account takeover | Scope to specific actions and resources |
| No VPC flow logs | Can't detect intrusion | Enable flow logs on all VPCs |
| Long-lived CI secrets | Compromised pipeline | Switch to OIDC federation |

## Pre-Deployment Checklist

### Application Security
1. [ ] No hardcoded secrets
2. [ ] All inputs schema-validated
3. [ ] No injection vectors (SQL, command, XSS)
4. [ ] Auth on every endpoint
5. [ ] Authorization at resource level
6. [ ] Rate limiting on public + expensive endpoints
7. [ ] HTTPS enforced
8. [ ] Security headers configured
9. [ ] Errors don't leak internals
10. [ ] Logs don't contain PII/secrets
11. [ ] Dependencies audited
12. [ ] CORS restricted to known origins
13. [ ] File uploads validated (type, size, extension)
14. [ ] Cookies: httpOnly, Secure, SameSite
15. [ ] Security tests pass

### Infrastructure Security
16. [ ] IAM follows least privilege
17. [ ] Database not publicly accessible
18. [ ] Secrets in cloud secret manager (not env files)
19. [ ] CI/CD uses OIDC (not long-lived keys)
20. [ ] Backups configured and tested
21. [ ] WAF/DDoS protection enabled
22. [ ] VPC flow logs and audit logging enabled

---

**Remember**: Security is not optional. One vulnerability can compromise every user on the platform.
