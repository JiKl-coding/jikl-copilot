---
name: sdd-spec-template
description: Produce a clear, review-ready SDD specification skeleton in Markdown.
---

# Skill: SDD Spec Template

## Goal
Produce a clear, review-ready SDD specification in Markdown.

## How to use (prompt)

```text
Write an SDD specification in Markdown using this exact structure:

1. Title & context
2. Goal (1–3 sentences)
3. Non-goals (bullets)
4. Scope / Impact (what changes where; API/DB/UI; compatibility)
5. Assumptions (if any)
6. User stories / Scenarios (brief)
7. Acceptance criteria (AC) – 5–12 verifiable items
8. Edge cases & error handling
9. Security & privacy (if relevant)
10. Telemetry/Logging (if relevant)
11. Test plan (unit/integration/e2e; mocks; minimum set)
12. Rollout / Migration (if relevant)
13. Open questions

Constraints:
- Keep it concise, but specific.
- AC must be testable and unambiguous.
- If information is missing, ask up to 3 targeted questions, otherwise proceed with clearly stated assumptions.
```

## Notes
- Works best when you provide: target users, constraints, and definition of done.
