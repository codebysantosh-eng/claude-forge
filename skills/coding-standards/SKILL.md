---
name: coding-standards
description: Deep reference for coding standards — naming, immutability, functions, error handling, async, React patterns, API design, file organization, comments, and code smells.
---

# Coding Standards Reference

Deep reference for the **code-inspector** agent. Patterns, thresholds, and examples.

## Naming Conventions

| Thing | Convention | Good | Bad |
|-------|-----------|------|-----|
| Variables | camelCase, descriptive | `userEmail`, `orderTotal` | `data`, `tmp`, `x` |
| Functions | verb-noun camelCase | `fetchUser()`, `calculateTotal()` | `process()`, `handle()` |
| Booleans | `is`/`has`/`can`/`should` | `isActive`, `hasPermission` | `active`, `flag` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `API_URL` | `maxRetries` |
| Types/Classes | PascalCase | `UserService`, `OrderItem` | `userService` |
| Interfaces | PascalCase (no I- prefix) | `UserProps`, `ApiResponse` | `IUserProps` |
| Files (utilities) | kebab-case | `user-service.ts` | `UserService.ts` |
| Files (components) | PascalCase | `UserCard.tsx` | `user-card.tsx` |
| Files (tests) | Match source + `.test` | `pricing.test.ts` | `test-pricing.ts` |

### Naming Anti-Patterns

```typescript
// ✗ Generic — tells you nothing
const data = await fetch("/api/users");
const result = processData(data);
const temp = result.filter(x => x.active);

// ✓ Specific — instantly clear
const usersResponse = await fetch("/api/users");
const activeUsers = usersResponse.filter(user => user.active);
const userCount = activeUsers.length;
```

## Immutability (CRITICAL)

Always create new values. Never mutate.

```typescript
// ✗ MUTATION — hidden side effects, hard to debug
user.role = "admin";
items.push(newItem);
state.count++;
users.sort((a, b) => a.name.localeCompare(b.name)); // sort mutates!

// ✓ IMMUTABLE — predictable, traceable
const updatedUser = { ...user, role: "admin" };
const withNewItem = [...items, newItem];
const newState = { ...state, count: state.count + 1 };
const sorted = [...users].sort((a, b) => a.name.localeCompare(b.name)); // copy first

// ✓ Array operations — always return new array
const filtered = items.filter(item => item.active);
const mapped = items.map(item => ({ ...item, processed: true }));
const reduced = items.reduce((acc, item) => acc + item.price, 0);

// ✓ Object updates — spread for shallow, structuredClone for deep
const shallow = { ...config, debug: true };
const deep = structuredClone(complexNested);
```

## Functions

### Size and Shape

- **< 50 lines** — extract helpers if longer
- **Single responsibility** — does one thing well
- **Max 3-4 params** — options object for more
- **Return early** — guard clauses, not deep nesting

```typescript
// ✗ Deep nesting — hard to follow
function processOrder(order) {
  if (order) {
    if (order.items.length > 0) {
      if (order.status === "pending") {
        if (order.total > 0) {
          // actual logic buried 4 levels deep
        }
      }
    }
  }
}

// ✓ Guard clauses — flat, scannable
function processOrder(order) {
  if (!order) throw new Error("Order is required");
  if (order.items.length === 0) throw new Error("Order has no items");
  if (order.status !== "pending") return;
  if (order.total <= 0) throw new Error("Order total must be positive");

  // actual logic at top level
}
```

### Parameter Patterns

```typescript
// ✗ Too many params — hard to remember order
function createUser(name, email, role, avatar, team, isActive) { ... }
createUser("Alice", "a@b.com", "admin", null, "eng", true); // What's null?

// ✓ Options object — self-documenting
interface CreateUserOptions {
  name: string;
  email: string;
  role: "user" | "admin";
  avatar?: string;
  team?: string;
  isActive?: boolean;
}
function createUser(options: CreateUserOptions) { ... }
createUser({ name: "Alice", email: "a@b.com", role: "admin", team: "eng" });
```

## Error Handling

```typescript
// ✓ Custom error types
class NotFoundError extends Error {
  constructor(public resource: string, public id: string) {
    super(`${resource} not found: ${id}`);
    this.name = "NotFoundError";
  }
}

class ValidationError extends Error {
  constructor(public field: string, message: string) {
    super(message);
    this.name = "ValidationError";
  }
}

// ✓ Comprehensive async error handling
async function fetchUser(id: string): Promise<User> {
  try {
    const res = await fetch(`/api/users/${id}`);
    if (!res.ok) {
      if (res.status === 404) throw new NotFoundError("User", id);
      throw new Error(`Failed to fetch user: ${res.status} ${res.statusText}`);
    }
    return res.json();
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    throw new Error(`Network error fetching user ${id}: ${(error as Error).message}`);
  }
}

// ✓ Error handling at API boundary
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof NotFoundError) {
    return res.status(404).json({ error: `${err.resource} not found` });
  }
  if (err instanceof ValidationError) {
    return res.status(400).json({ error: err.message, field: err.field });
  }
  // Unknown error — log details, return generic message
  logger.error("Unhandled error", { error: err.message, stack: err.stack });
  return res.status(500).json({ error: "Internal server error" });
});
```

**Rules**:
- Handle at every level — never silently swallow (`catch {}`)
- Typed errors where callers need to distinguish
- Generic messages to users, detailed context in server logs
- Validate required config at startup (fail fast)

## Async Patterns

```typescript
// ✗ Sequential when independent — wastes time
const users = await fetchUsers();
const orders = await fetchOrders();
const stats = await fetchStats();

// ✓ Parallel when independent
const [users, orders, stats] = await Promise.all([
  fetchUsers(),
  fetchOrders(),
  fetchStats(),
]);

// ✓ Promise.allSettled when you don't want one failure to cancel all
const results = await Promise.allSettled([
  fetchCriticalData(),
  fetchOptionalData(),
]);

const critical = results[0].status === "fulfilled" ? results[0].value : null;
const optional = results[1].status === "fulfilled" ? results[1].value : null;

// ✓ Retry with backoff for external services
async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === attempts - 1) throw error;
      await new Promise(r => setTimeout(r, Math.pow(2, i) * 1000));
    }
  }
  throw new Error("Unreachable");
}
```

## React Patterns

### Component Structure

```tsx
// ✓ Typed props with clear interface
interface UserCardProps {
  user: User;
  onSelect: (userId: string) => void;
  variant?: "compact" | "full";
}

function UserCard({ user, onSelect, variant = "full" }: UserCardProps) {
  const handleClick = useCallback(() => onSelect(user.id), [user.id, onSelect]);

  if (variant === "compact") {
    return <span onClick={handleClick}>{user.name}</span>;
  }

  return (
    <div onClick={handleClick}>
      <h3>{user.name}</h3>
      <p>{user.email}</p>
    </div>
  );
}
```

### Memoization

```tsx
// ✓ Expensive computation
const sortedItems = useMemo(
  () => [...items].sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);

// ✓ Stable callback for child components
const handleClick = useCallback(() => onSelect(id), [id, onSelect]);

// ✓ Prevent re-renders of expensive children
const MemoizedChild = React.memo(ExpensiveComponent);

// ✓ Lazy load heavy components
const HeavyChart = lazy(() => import("./HeavyChart"));
<Suspense fallback={<Skeleton />}>
  <HeavyChart data={data} />
</Suspense>
```

### Custom Hooks

```tsx
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debounced;
}

// Usage
const searchTerm = useDebounce(input, 300);
```

## API Design

### REST Conventions

| Method | Route | Purpose | Response |
|--------|-------|---------|----------|
| GET | `/resources` | List (paginated) | 200 + array |
| GET | `/resources/:id` | Get one | 200 or 404 |
| POST | `/resources` | Create | 201 + created |
| PUT | `/resources/:id` | Full update | 200 + updated |
| PATCH | `/resources/:id` | Partial update | 200 + updated |
| DELETE | `/resources/:id` | Delete | 204 |

### Response Envelope

```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  meta?: { total: number; page: number; limit: number };
}

// Success
{ "success": true, "data": { "id": "123", "name": "Widget" } }

// Error
{ "success": false, "error": "User not found" }

// Paginated list
{ "success": true, "data": [...], "meta": { "total": 42, "page": 1, "limit": 20 } }
```

### Input Validation (Zod)

```typescript
import { z } from "zod";

const CreateOrderSchema = z.object({
  items: z.array(z.object({
    sku: z.string().min(1),
    quantity: z.number().int().positive(),
  })).min(1, "At least one item required"),
  customerId: z.string().uuid(),
  notes: z.string().max(500).optional(),
});

type CreateOrderInput = z.infer<typeof CreateOrderSchema>;
```

## File Organization

```
src/
├── app/                        # Next.js App Router / routes
│   ├── api/                   # API routes
│   │   ├── orders/route.ts
│   │   └── users/route.ts
│   ├── dashboard/page.tsx
│   └── layout.tsx
├── components/                # React components
│   ├── ui/                   # Generic (Button, Input, Modal)
│   └── features/             # Domain-specific (OrderForm, UserCard)
├── hooks/                    # Custom React hooks
├── lib/                      # Business logic and utilities
│   ├── api/                 # API clients
│   ├── utils/               # Helpers
│   └── constants.ts
├── types/                    # TypeScript types
└── styles/                   # Global styles
```

**File sizing**: 200-400 lines typical, 800 max. Split by responsibility if larger.

## Comments

```typescript
// ✗ Describes WHAT (obvious from code)
// Loop through users and filter active ones
const active = users.filter(u => u.active);

// ✓ Explains WHY (non-obvious decision)
// Filter inactive users first to avoid rate-limited API calls
// for users who won't appear in results (saves ~40% API cost)
const active = users.filter(u => u.active);

// ✓ JSDoc for public APIs
/**
 * Calculates the discount for a given amount.
 * @param cents - Amount in cents (must be non-negative)
 * @param discount - Discount configuration
 * @returns Discounted amount in cents, minimum 0
 * @throws {Error} If cents is negative
 */
function calculateDiscount(cents: number, discount: DiscountConfig): number
```

- Delete commented-out code — use git history
- TODO must have ticket: `// TODO(#123): migrate to v2`
- Don't document the obvious — only explain WHY for non-obvious decisions

## Code Smells

| Smell | Threshold | Action |
|-------|-----------|--------|
| Long function | > 50 lines | Extract helpers |
| Deep nesting | > 4 levels | Guard clauses |
| Magic numbers | Any literal in logic | Named constant |
| Large file | > 800 lines | Split by responsibility |
| God module | Does "everything" | Focus into smaller modules |
| Duplicated logic | > 3 occurrences | Extract shared function |
| Boolean params | `fn(true, false)` | Options object |
| Long param list | > 4 params | Options object |
| Primitive obsession | Strings everywhere | Value objects / types |
| Feature envy | Uses another module more than its own | Move logic to where data lives |

---

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
