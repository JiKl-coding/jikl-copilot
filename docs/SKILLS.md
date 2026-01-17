# Agent Skills

VS Code discovers project skills from `.github/skills/<skill-name>/SKILL.md`.

Related docs:

- Agents index: see [docs/AGENTS.md](AGENTS.md)
- Copilot basics: see [docs/COPILOT_BASICS_CZ.md](COPILOT_BASICS_CZ.md) (or [EN](COPILOT_BASICS_EN.md))

## Included skills

Ask the **Agent Manager** to regenerate the auto-generated skills list below after any changes under `.github/skills/`.

<!-- SKILLS:BEGIN -->
(Auto-generated. Edit skill files under `.github/skills/<skill>/SKILL.md`.)

- `ac-quality-check` — Improve acceptance criteria so they are testable, unambiguous, and complete. (source: [.github/skills/ac-quality-check/SKILL.md](../.github/skills/ac-quality-check/SKILL.md))
- `git-sync-rebase` — Safely sync a branch with origin/main using fetch + rebase, with an optional "accept current" conflict policy. (source: [.github/skills/git-sync-rebase/SKILL.md](../.github/skills/git-sync-rebase/SKILL.md))
- `identify-self` — Provide a short identity/self-description and usage guidance when the user asks “who are you / what can you do / help”. (source: [.github/skills/identify-self/SKILL.md](../.github/skills/identify-self/SKILL.md))
- `mcp-integration` — Add an MCP integration section (tools, auth, error handling, observability, tests) to an existing spec. (source: [.github/skills/mcp-integration/SKILL.md](../.github/skills/mcp-integration/SKILL.md))
- `requirements-extractor` — Extract MUST/SHOULD/MAY requirements, constraints, flows, and open questions from long epic/PRD text (PDF/TXT export). (source: [.github/skills/requirements-extractor/SKILL.md](../.github/skills/requirements-extractor/SKILL.md))
- `risk-review` — Identify edge cases, security/privacy issues, operational risks, and delivery risks in a spec. (source: [.github/skills/risk-review/SKILL.md](../.github/skills/risk-review/SKILL.md))
- `rollout-migration` — Propose a safe rollout/migration plan with monitoring and rollback steps. (source: [.github/skills/rollout-migration/SKILL.md](../.github/skills/rollout-migration/SKILL.md))
- `sdd-spec-template` — Produce a clear, review-ready SDD specification skeleton in Markdown. (source: [.github/skills/sdd-spec-template/SKILL.md](../.github/skills/sdd-spec-template/SKILL.md))
- `test-plan` — Build a pragmatic unit/integration/e2e test strategy aligned with a spec. (source: [.github/skills/test-plan/SKILL.md](../.github/skills/test-plan/SKILL.md))
<!-- SKILLS:END -->

## Note

Agent Skills are preview in VS Code and require enabling the `chat.useAgentSkills` setting.

Tip: keep skill definitions in `.github/skills/` (discoverable) and treat `docs/` as the human-friendly index.
