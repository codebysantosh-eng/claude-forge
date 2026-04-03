---
name: tdd-patterns
description: Deep reference for test-driven development — unit, integration, E2E patterns, mocking strategies, file organization, coverage config, CI integration, and common mistakes.
---

# TDD Patterns Reference

Deep reference for the **tdd-developer** and **e2e-runner** agents. Patterns, not workflow.

## Unit Test Patterns

### Function Testing (Jest/Vitest)

```typescript
describe("calculateDiscount", () => {
  it("applies percentage discount to subtotal", () => {
    expect(calculateDiscount(10000, { type: "percent", value: 15 })).toBe(8500);
  });

  it("applies fixed discount without going negative", () => {
    expect(calculateDiscount(500, { type: "fixed", value: 1000 })).toBe(0);
  });

  it("throws on negative amount", () => {
    expect(() => calculateDiscount(-1, { type: "percent", value: 10 }))
      .toThrow("Amount must be non-negative");
  });

  it("handles zero amount", () => {
    expect(calculateDiscount(0, { type: "percent", value: 50 })).toBe(0);
  });

  it("handles 100% discount", () => {
    expect(calculateDiscount(5000, { type: "percent", value: 100 })).toBe(0);
  });
});
```

### React Component Testing

```tsx
import { render, screen, fireEvent, waitFor } from "@testing-library/react";

describe("UserCard", () => {
  const mockUser = { id: "1", name: "Alice", email: "alice@test.com" };

  it("renders user name and email", () => {
    render(<UserCard user={mockUser} />);
    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("alice@test.com")).toBeInTheDocument();
  });

  it("calls onSelect with user ID when clicked", () => {
    const onSelect = jest.fn();
    render(<UserCard user={mockUser} onSelect={onSelect} />);
    fireEvent.click(screen.getByRole("button"));
    expect(onSelect).toHaveBeenCalledWith("1");
  });

  it("shows loading skeleton while fetching", () => {
    render(<UserCard userId="1" />);
    expect(screen.getByTestId("skeleton")).toBeInTheDocument();
  });

  it("shows error state when fetch fails", async () => {
    server.use(rest.get("/api/users/1", (req, res, ctx) => res(ctx.status(500))));
    render(<UserCard userId="1" />);
    await waitFor(() => {
      expect(screen.getByText("Failed to load user")).toBeInTheDocument();
    });
  });
});
```

### Custom Hook Testing

```typescript
import { renderHook, act } from "@testing-library/react";

describe("useDebounce", () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it("returns initial value immediately", () => {
    const { result } = renderHook(() => useDebounce("hello", 500));
    expect(result.current).toBe("hello");
  });

  it("debounces value changes", () => {
    const { result, rerender } = renderHook(
      ({ value }) => useDebounce(value, 500),
      { initialProps: { value: "hello" } }
    );

    rerender({ value: "world" });
    expect(result.current).toBe("hello"); // Not yet updated

    act(() => jest.advanceTimersByTime(500));
    expect(result.current).toBe("world"); // Now updated
  });
});
```

## Integration Test Patterns

### API Endpoint (Express/Next.js)

```typescript
import request from "supertest";

describe("POST /api/orders", () => {
  beforeEach(async () => {
    await db.orders.deleteMany(); // Clean state
  });

  it("creates order and returns 201 with order ID", async () => {
    const res = await request(app)
      .post("/api/orders")
      .set("Authorization", `Bearer ${validToken}`)
      .send({ items: [{ sku: "W-1", qty: 2 }], customerId: "cust_123" })
      .expect(201);

    expect(res.body.data).toHaveProperty("orderId");
    expect(res.body.data.status).toBe("pending");

    // Verify persistence
    const order = await db.orders.findById(res.body.data.orderId);
    expect(order).toBeTruthy();
    expect(order.items).toHaveLength(1);
  });

  it("returns 400 for empty items", async () => {
    const res = await request(app)
      .post("/api/orders")
      .set("Authorization", `Bearer ${validToken}`)
      .send({ items: [], customerId: "cust_123" })
      .expect(400);

    expect(res.body.error).toMatch(/items/i);
  });

  it("returns 401 without authentication", async () => {
    await request(app)
      .post("/api/orders")
      .send({ items: [{ sku: "W-1", qty: 1 }] })
      .expect(401);
  });

  it("returns 403 when user lacks permission", async () => {
    await request(app)
      .post("/api/orders")
      .set("Authorization", `Bearer ${readOnlyToken}`)
      .send({ items: [{ sku: "W-1", qty: 1 }] })
      .expect(403);
  });

  it("validates item quantity is positive", async () => {
    await request(app)
      .post("/api/orders")
      .set("Authorization", `Bearer ${validToken}`)
      .send({ items: [{ sku: "W-1", qty: -1 }] })
      .expect(400);
  });
});
```

### Database Operations

```typescript
describe("UserRepository", () => {
  let repo: UserRepository;

  beforeEach(async () => {
    repo = new UserRepository(testDb);
    await testDb.users.deleteMany();
  });

  it("creates user and returns with ID", async () => {
    const user = await repo.create({ email: "test@example.com", name: "Test" });
    expect(user.id).toBeDefined();
    expect(user.email).toBe("test@example.com");
  });

  it("throws on duplicate email", async () => {
    await repo.create({ email: "test@example.com", name: "First" });
    await expect(repo.create({ email: "test@example.com", name: "Second" }))
      .rejects.toThrow("Email already exists");
  });

  it("findById returns null for non-existent user", async () => {
    const result = await repo.findById("non-existent-id");
    expect(result).toBeNull();
  });
});
```

## E2E Test Patterns (Playwright)

```typescript
import { test, expect } from "@playwright/test";

test.describe("Authentication", () => {
  test("signup → login → dashboard", async ({ page }) => {
    // Signup
    await page.goto("/signup");
    await page.getByLabel("Email").fill("new@example.com");
    await page.getByLabel("Password").fill("SecurePass123!");
    await page.getByRole("button", { name: "Sign Up" }).click();
    await expect(page.getByText("Welcome")).toBeVisible();

    // Logout
    await page.getByRole("button", { name: "Logout" }).click();

    // Login
    await page.goto("/login");
    await page.getByLabel("Email").fill("new@example.com");
    await page.getByLabel("Password").fill("SecurePass123!");
    await page.getByRole("button", { name: "Log In" }).click();

    // Verify dashboard
    await expect(page).toHaveURL(/.*dashboard/);
    await expect(page.getByText("Welcome back")).toBeVisible();
  });

  test("shows error for wrong password", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill("user@example.com");
    await page.getByLabel("Password").fill("wrong");
    await page.getByRole("button", { name: "Log In" }).click();

    await expect(page.getByText("Invalid credentials")).toBeVisible();
    await expect(page).toHaveURL(/.*login/); // Stays on login page
  });
});
```

## Mocking Strategies

### Database (Supabase)

```typescript
jest.mock("@supabase/supabase-js", () => ({
  createClient: () => ({
    from: (table: string) => ({
      select: jest.fn().mockReturnThis(),
      insert: jest.fn().mockReturnThis(),
      update: jest.fn().mockReturnThis(),
      delete: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({ data: mockData, error: null }),
      then: jest.fn().mockResolvedValue({ data: [mockData], error: null }),
    }),
    auth: {
      getSession: jest.fn().mockResolvedValue({ data: { session: mockSession } }),
      signInWithPassword: jest.fn().mockResolvedValue({ data: { user: mockUser } }),
    },
  }),
}));
```

### HTTP API (fetch/axios)

```typescript
// Simple mock
jest.mock("./api-client", () => ({
  fetchUser: jest.fn().mockResolvedValue({ id: "1", name: "Test" }),
  fetchOrders: jest.fn().mockResolvedValue([]),
}));

// Dynamic mock for different test cases
const mockFetchUser = fetchUser as jest.MockedFunction<typeof fetchUser>;

it("handles API error", async () => {
  mockFetchUser.mockRejectedValueOnce(new Error("Network error"));
  // ... test error handling
});
```

### Redis/Cache

```typescript
jest.mock("ioredis", () =>
  jest.fn().mockImplementation(() => ({
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue("OK"),
    del: jest.fn().mockResolvedValue(1),
    expire: jest.fn().mockResolvedValue(1),
    pipeline: jest.fn().mockReturnThis(),
    exec: jest.fn().mockResolvedValue([]),
  }))
);
```

### Time/Date

```typescript
beforeEach(() => {
  jest.useFakeTimers();
  jest.setSystemTime(new Date("2026-01-15T10:00:00Z"));
});

afterEach(() => jest.useRealTimers());
```

### Environment Variables

```typescript
const originalEnv = process.env;

beforeEach(() => {
  process.env = { ...originalEnv, STRIPE_KEY: "sk_test_123" };
});

afterEach(() => {
  process.env = originalEnv;
});
```

## File Organization

```
src/
├── lib/
│   ├── pricing.ts
│   └── pricing.test.ts              # Unit — next to source
├── api/
│   ├── orders/
│   │   ├── route.ts
│   │   └── route.test.ts            # Integration — next to route
│   └── users/
│       ├── route.ts
│       └── route.test.ts
├── components/
│   ├── UserCard/
│   │   ├── UserCard.tsx
│   │   └── UserCard.test.tsx         # Component — next to component
│   └── OrderForm/
│       ├── OrderForm.tsx
│       └── OrderForm.test.tsx
├── hooks/
│   ├── useDebounce.ts
│   └── useDebounce.test.ts           # Hook — next to hook
└── e2e/                               # E2E — dedicated folder
    ├── pages/                         # Page Objects
    │   ├── login.page.ts
    │   └── checkout.page.ts
    ├── auth.spec.ts
    └── checkout.spec.ts
```

## Coverage Configuration

### Jest

```json
{
  "collectCoverageFrom": ["src/**/*.{ts,tsx}", "!src/**/*.d.ts", "!src/**/index.ts"],
  "coverageThreshold": {
    "global": { "branches": 80, "functions": 80, "lines": 80, "statements": 80 }
  }
}
```

### Vitest

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/**/*.d.ts", "src/**/index.ts"],
      thresholds: { branches: 80, functions: 80, lines: 80, statements: 80 },
    },
  },
});
```

## Coverage Commands

| Framework | Command |
|-----------|---------|
| Jest | `npx jest --coverage` |
| Vitest | `npx vitest --coverage` |
| pytest | `pytest --cov=src --cov-report=term-missing` |
| Go | `go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out` |
| Rust | `cargo tarpaulin --out Html` |

## Common Mistakes

| Mistake | Why It's Bad | Fix |
|---------|-------------|-----|
| Testing implementation details | Breaks on refactor when behavior is fine | Test inputs → outputs |
| One giant test | Can't tell which behavior failed | One assertion per test |
| Tests depend on order | Flaky in parallel, fragile | Each test sets up own state |
| Mocking the thing under test | Testing the mock, not code | Mock at boundaries only |
| `test("works")` | Useless failure message | `test("returns 404 when not found")` |
| Skipping RED phase | Test might pass for wrong reason | Always see it fail first |
| Testing after implementation | Confirmation bias | Write test before touching code |
| `test.skip()` to fix CI | Hides real failures | Fix the test or `test.fixme()` with ticket |
| No cleanup in beforeEach | Shared state between tests | Reset DB/mocks before each |
| Testing framework internals | Breaks on framework update | Test your code, not React/Express |

## CI/CD Integration

### GitHub Actions

```yaml
- name: Run Tests
  run: npm test -- --coverage --ci
- name: Upload Coverage
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
```

### Pre-commit Hook

```bash
# Run tests related to changed files only
npx jest --onlyChanged --bail
```

### Watch Mode (Development)

```bash
npx jest --watch          # Re-run on file change
npx vitest                # Vitest auto-watches by default
```
