---
name: ac-quality-check
description: Improve acceptance criteria so they are testable, unambiguous, and complete.
---

# Skill: Acceptance Criteria Quality Check

## Goal
Upgrade acceptance criteria (AC) so they are verifiable, unambiguous, and complete.

## How to use (prompt)

```text
Review the following acceptance criteria and improve them.

Rules:
- Each AC must be testable/verifiable (avoid vague words like “fast”, “nice”, “robust”).
- Prefer measurable thresholds (latency, size, limits) when relevant.
- Include negative cases (invalid input, permissions, missing data).
- Separate concerns: one requirement per bullet.
- If an AC implies a behavior change, include compatibility expectations.

Output:
1) Revised AC list
2) A short note listing what was unclear/missing
```

## Quick checklist
- Is every AC observable in tests or logs?
- Do AC cover happy path + failure modes?
- Do AC cover permissions/authz (if relevant)?
- Do AC cover migration/backward compatibility (brownfield)?
