---
description: Generate, run, and maintain end-to-end tests for critical user journeys using Playwright.
---

# /e2e

Invoke the **e2e-runner** agent to create and execute E2E tests.

## What It Does

1. Identifies critical user journeys by risk priority
2. Generates Playwright tests using Page Object Model
3. Configures multi-browser execution (Chromium, Firefox, WebKit)
4. Runs tests and captures artifacts (screenshots, videos, traces)
5. Identifies and quarantines flaky tests
6. Generates CI/CD pipeline config

## When to Use

- Testing auth, checkout, onboarding, or other critical flows
- Before major releases or production deploys
- After large feature merges
- Setting up E2E testing for a new project
- When integration bugs slip through unit tests

## Example Usage

```
User: /e2e I need tests for the checkout flow

Agent (e2e-runner):

# E2E Test Plan: Checkout Flow

## Critical Journeys (Priority Order)

1. HIGH: Complete purchase with valid card
2. HIGH: Handle declined card gracefully
3. HIGH: Require email before submit
4. MEDIUM: Apply discount code
5. MEDIUM: Update cart quantities
6. LOW: Guest vs logged-in checkout

## Step 1: Page Object

```typescript
// e2e/pages/checkout.page.ts
import { Page, expect } from "@playwright/test";

export class CheckoutPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto("/checkout");
  }

  async fillEmail(email: string) {
    await this.page.getByLabel("Email").fill(email);
  }

  async fillCard(number: string) {
    await this.page.getByLabel("Card number").fill(number);
  }

  async fillExpiry(expiry: string) {
    await this.page.getByLabel("Expiry").fill(expiry);
  }

  async fillCVC(cvc: string) {
    await this.page.getByLabel("CVC").fill(cvc);
  }

  async placeOrder() {
    await this.page.getByRole("button", { name: "Place Order" }).click();
  }

  async applyDiscount(code: string) {
    await this.page.getByLabel("Discount code").fill(code);
    await this.page.getByRole("button", { name: "Apply" }).click();
  }

  async expectConfirmation() {
    await expect(this.page.getByText("Order confirmed")).toBeVisible();
  }

  async expectError(message: string) {
    await expect(this.page.getByRole("alert")).toContainText(message);
  }
}
```

## Step 2: Tests

```typescript
// e2e/checkout.spec.ts
import { test, expect } from "@playwright/test";
import { CheckoutPage } from "./pages/checkout.page";

test.describe("Checkout Flow", () => {

  test("complete purchase with valid card", async ({ page }) => {
    // Add product to cart
    await page.goto("/products");
    await page.getByTestId("product-card").first().click();
    await page.getByRole("button", { name: "Add to Cart" }).click();

    // Navigate to checkout
    await page.getByRole("link", { name: "Cart" }).click();
    await expect(page.getByTestId("cart-count")).toHaveText("1");
    await page.getByRole("button", { name: "Checkout" }).click();

    // Fill payment details
    const checkout = new CheckoutPage(page);
    await checkout.fillEmail("buyer@example.com");
    await checkout.fillCard("4242424242424242");
    await checkout.fillExpiry("12/28");
    await checkout.fillCVC("123");

    // Place order and verify
    await checkout.placeOrder();

    // Wait for API response before asserting
    await page.waitForResponse(resp =>
      resp.url().includes("/api/orders") && resp.status() === 201
    );

    await checkout.expectConfirmation();
    await expect(page.getByTestId("order-id")).toBeVisible();

    // Screenshot for visual regression
    await page.screenshot({ path: "e2e/screenshots/checkout-success.png" });
  });

  test("shows error for declined card", async ({ page }) => {
    await page.goto("/checkout");
    const checkout = new CheckoutPage(page);

    await checkout.fillEmail("buyer@example.com");
    await checkout.fillCard("4000000000000002"); // Stripe declined test card
    await checkout.fillExpiry("12/28");
    await checkout.fillCVC("123");
    await checkout.placeOrder();

    await checkout.expectError("Card declined");
    await expect(page).toHaveURL(/.*checkout/); // Stays on checkout
  });

  test("requires email before submitting", async ({ page }) => {
    await page.goto("/checkout");
    const checkout = new CheckoutPage(page);

    // Skip email, try to submit
    await checkout.fillCard("4242424242424242");
    await checkout.placeOrder();

    await checkout.expectError("Email is required");
  });

  test("applies discount code and updates total", async ({ page }) => {
    await page.goto("/checkout");
    const checkout = new CheckoutPage(page);

    const originalTotal = await page.getByTestId("order-total").textContent();
    await checkout.applyDiscount("SAVE20");

    await expect(page.getByText("20% off applied")).toBeVisible();
    const newTotal = await page.getByTestId("order-total").textContent();
    expect(parseFloat(newTotal!)).toBeLessThan(parseFloat(originalTotal!));
  });
});
```

## Step 3: Run Tests

```bash
$ npx playwright test e2e/checkout.spec.ts

Running 4 tests using 3 workers

  ✓ [chromium] checkout.spec.ts:8:3    complete purchase (3.2s)
  ✓ [chromium] checkout.spec.ts:42:3   declined card (1.8s)
  ✓ [chromium] checkout.spec.ts:56:3   requires email (1.1s)
  ✓ [chromium] checkout.spec.ts:65:3   discount code (2.0s)

  4 passed (8.1s)
```

## Step 4: Check for Flakiness

```bash
$ npx playwright test e2e/checkout.spec.ts --repeat-each=5

Running 20 tests using 3 workers
  20 passed (41s)

Flaky rate: 0% ✓
```

## Step 5: Report

```
E2E Report: Checkout Flow
─────────────────────────────────
Tests:     4 passing, 0 failing
Browsers:  Chromium ✓  Firefox ✓  WebKit ✓
Flaky:     0% (verified with 5x repeat)
Duration:  8.1s

Artifacts:
  HTML Report:  playwright-report/index.html
  Screenshots:  e2e/screenshots/checkout-success.png
─────────────────────────────────
```
```

## Configuration

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30000,
  retries: 2,
  workers: process.env.CI ? 1 : undefined,

  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "on-first-retry",
  },

  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
    { name: "firefox", use: { browserName: "firefox" } },
    { name: "webkit", use: { browserName: "webkit" } },
    {
      name: "mobile-chrome",
      use: { ...devices["Pixel 5"] },
    },
  ],

  webServer: {
    command: "npm run dev",
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

## CI/CD Integration

```yaml
# .github/workflows/e2e.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npx playwright test
        env:
          BASE_URL: http://localhost:3000

      - name: Upload report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 14

      - name: Upload failure artifacts
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-failures
          path: |
            e2e/screenshots/
            test-results/
```

## Artifacts

**On every run:**
- HTML report with timeline, screenshots, and video
- JUnit XML for CI dashboard integration

**On failure only:**
- Screenshot at point of failure
- Video recording of the full test
- Trace file (step-by-step replay with network, DOM snapshots)
- Console logs and network request log

```bash
# View report after run
npx playwright show-report

# View trace for a failed test
npx playwright show-trace test-results/checkout-spec-ts/trace.zip
```

## Flaky Test Handling

```typescript
// Quarantine — don't delete, don't silently skip
test("flaky: real-time price update", async ({ page }) => {
  test.fixme(true, "Flaky due to WebSocket timing — #456");
});
```

| Cause | Symptom | Fix |
|-------|---------|-----|
| Race condition | Passes 4/5 runs | Use `waitForResponse()` or `waitForSelector()` |
| Animation timing | Element not visible yet | Wait for specific CSS state, not timeout |
| Shared state | Fails when run in parallel | Isolate test data per test |
| Network timing | Timeout on slow CI | Increase timeout, mock external APIs |
| Time-dependent | Fails at midnight | Mock `page.clock` |

## Best Practices

**DO:**
- Use semantic locators: `getByRole()`, `getByLabel()`, `getByTestId()`
- Wait for API responses before asserting UI state
- Use Page Object Model for reusable interactions
- Test critical flows first (auth, payment, core CRUD)
- Run before merging to main
- Review artifacts on every failure

**DON'T:**
- Use CSS selectors or XPath (brittle)
- Use `waitForTimeout()` (use condition-based waits)
- Share state between tests
- Test against production (use staging/testnet)
- Skip flaky tests without a ticket
- Rely on test execution order

## After E2E

- `/inspect` — Review if tests reveal code issues
- `/healthcheck` — Full verification suite
- `/pre-deploy` — Deployment readiness check

## Agent

`agents/e2e-runner.md`
