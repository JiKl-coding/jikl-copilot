---
name: test-plan
description: Build a pragmatic unit/integration/e2e test strategy aligned with a spec.
---

# Skill: Test Plan Builder

## Goal
Create a pragmatic test strategy aligned with the spec.

## How to use (prompt)

```text
Write a test plan for this spec.

Include:
- Unit tests: key pure logic, boundary conditions
- Integration tests: DB/API boundaries, mocks vs real dependencies
- E2E tests: critical user journeys (if applicable)
- Non-functional tests: performance, rate limits, resiliency (if relevant)

For each test group:
- what to test,
- what to mock/stub,
- minimal set that must pass for “done”.

If the spec is brownfield, include regression coverage suggestions.
```
