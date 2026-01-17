---
name: risk-review
description: Identify edge cases, security/privacy issues, operational risks, and delivery risks in a spec.
---

# Skill: Risk Review (Edge/Security/Delivery)

## Goal
Find gaps before implementation: edge cases, security/privacy risks, operational risks.

## How to use (prompt)

```text
Perform a risk review of this spec.

Sections to produce:
- Edge cases we might be missing
- Security & privacy considerations (authn/authz, secrets, data exposure, abuse)
- Operational risks (timeouts, retries, rate limiting, observability)
- Delivery risks (dependencies, migrations, rollout, backward compatibility)

For each item:
- describe impact,
- likelihood (low/med/high),
- mitigation,
- how to verify.

Keep it short but actionable.
```
