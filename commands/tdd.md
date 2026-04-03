---
description: Implement features using strict test-driven development — failing tests first, minimal implementation, then refactor.
---

# /tdd

Invoke the **tdd-developer** agent to build test-first.

## The Cycle

```
RED       Write failing test that defines expected behavior
GREEN     Write minimum code to make it pass
REFACTOR  Clean up while tests stay green
REPEAT    Until feature is complete
```

## What It Does

1. Defines interfaces and type signatures
2. Writes failing tests — verified to fail
3. Commits: `test: add failing tests for [feature]`
4. Implements minimal code to pass
5. Commits: `feat: implement [feature]`
6. Refactors with tests green
7. Verifies 80%+ coverage

## Worked Example

```
User: /tdd I need a function to calculate liquidity scores for markets

Agent (tdd-developer):

# TDD Session: Market Liquidity Score

## Step 1: Define Interface (SCAFFOLD)

  interface MarketData {
    totalVolume: number;
    bidAskSpread: number;
    activeTraders: number;
    lastTradeTime: Date;
  }

  function calculateLiquidityScore(market: MarketData): number {
    throw new Error("Not implemented");
  }

## Step 2: Write Failing Tests (RED)

  describe("calculateLiquidityScore", () => {
    it("returns high score for liquid market", () => {
      const market = {
        totalVolume: 100000,
        bidAskSpread: 0.01,
        activeTraders: 500,
        lastTradeTime: new Date(),
      };
      const score = calculateLiquidityScore(market);
      expect(score).toBeGreaterThan(80);
      expect(score).toBeLessThanOrEqual(100);
    });

    it("returns low score for illiquid market", () => {
      const market = {
        totalVolume: 100,
        bidAskSpread: 0.5,
        activeTraders: 2,
        lastTradeTime: new Date(Date.now() - 86400000),
      };
      const score = calculateLiquidityScore(market);
      expect(score).toBeLessThan(30);
    });

    it("returns 0 for zero volume", () => {
      const market = {
        totalVolume: 0,
        bidAskSpread: 0,
        activeTraders: 0,
        lastTradeTime: new Date(),
      };
      expect(calculateLiquidityScore(market)).toBe(0);
    });

    it("clamps score between 0 and 100", () => {
      const extremeMarket = {
        totalVolume: Number.MAX_SAFE_INTEGER,
        bidAskSpread: 0.001,
        activeTraders: 10000,
        lastTradeTime: new Date(),
      };
      const score = calculateLiquidityScore(extremeMarket);
      expect(score).toBeLessThanOrEqual(100);
      expect(score).toBeGreaterThanOrEqual(0);
    });
  });

## Step 3: Run Tests — Verify FAIL ✗

  $ npm test lib/liquidity.test.ts

  FAIL  lib/liquidity.test.ts
    ✕ returns high score for liquid market — Error: Not implemented
    ✕ returns low score for illiquid market
    ✕ returns 0 for zero volume
    ✕ clamps score between 0 and 100

  4 tests failed ✓ (expected — function not implemented yet)

## Step 4: Implement (GREEN)

  const WEIGHTS = { VOLUME: 0.4, SPREAD: 0.3, TRADERS: 0.2, RECENCY: 0.1 };

  function calculateLiquidityScore(market: MarketData): number {
    if (market.totalVolume === 0) return 0;

    const volumeScore = Math.min(market.totalVolume / 1000, 100);
    const spreadScore = Math.max(100 - market.bidAskSpread * 1000, 0);
    const traderScore = Math.min(market.activeTraders / 10, 100);

    const hoursSince = (Date.now() - market.lastTradeTime.getTime()) / 3600000;
    const recencyScore = Math.max(100 - hoursSince * 10, 0);

    const score =
      volumeScore * WEIGHTS.VOLUME +
      spreadScore * WEIGHTS.SPREAD +
      traderScore * WEIGHTS.TRADERS +
      recencyScore * WEIGHTS.RECENCY;

    return Math.min(Math.max(Math.round(score), 0), 100);
  }

## Step 5: Run Tests — Verify PASS ✓

  $ npm test lib/liquidity.test.ts

  PASS  lib/liquidity.test.ts
    ✓ returns high score for liquid market (3ms)
    ✓ returns low score for illiquid market (1ms)
    ✓ returns 0 for zero volume (1ms)
    ✓ clamps score between 0 and 100 (1ms)

  4 tests passed ✓

## Step 6: Refactor

  - Extracted WEIGHTS and SCALE_FACTORS as named constants
  - Added JSDoc with @param and @returns
  - Extracted clamp() utility

## Step 7: Coverage — 100% ✓

  $ npm test -- --coverage lib/liquidity.test.ts

  File           | Stmts | Branch | Funcs | Lines
  liquidity.ts   | 100%  | 100%   | 100%  | 100%
```

## Rules

- Tests BEFORE implementation — always
- One test at a time for complex features
- Test behavior, not implementation details
- 80% coverage minimum (100% for auth/payments)

## Coverage Requirements

| Code Type | Target |
|-----------|--------|
| General | 80%+ |
| Auth / payments / critical | 100% |
| Utilities / helpers | 90%+ |

## When to Use

- Implementing features from an approved design
- Fixing bugs (write test that reproduces it first)
- Refactoring (ensure tests exist before changing)
- Any new function, endpoint, or component

## After TDD

- `/inspect` — Review the implementation
- `/fix` — If build breaks
- `/scan` — If code touches auth/payments/user input
- `/e2e` — If the feature has a user-facing flow

## Agent

`agents/tdd-developer.md`

## Reference

See `skills/tdd-patterns/SKILL.md` for mocking strategies, file organization, and CI integration.
