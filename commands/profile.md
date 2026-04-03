---
description: Profile code for performance bottlenecks — algorithms, bundle size, queries, rendering, memory.
---

# /profile

Invoke the **performance-profiler** agent to find and fix slowness.

## What It Does

1. Measures current performance (Lighthouse, bundle analysis, query timing)
2. Identifies bottlenecks by category: algorithmic, React, database, bundle, network
3. Fixes with smallest effective change
4. Measures again — reports before/after delta

## Targets

| Metric | Target |
|--------|--------|
| LCP | < 2.5s |
| Bundle (gzip) | < 200KB |
| TTI | < 3.8s |
| DB queries | No N+1, all indexed |

## When to Use

- After feature is built and functionally correct
- UI feels sluggish
- Database queries are slow
- Bundle size exceeds budget
- Before high-traffic launch

## Rules

- Measure first, optimize second, verify third
- Never optimize on intuition
- Don't sacrifice readability for marginal gains

## After Profiling

- `/inspect` — Verify optimization didn't introduce bugs
- `/tdd` — Add performance regression tests
- `/healthcheck` — Full verification

## Agent

`agents/performance-profiler.md`
