# Agent Skills

VS Code discovers project skills from `.github/skills/<skill-name>/SKILL.md`.

Related docs:
- Agents index: see [docs/AGENTS.md](AGENTS.md)
- Copilot basics: see [docs/COPILOT_BASICS.md](COPILOT_BASICS.md)

## Included skills

- `sdd-spec-template` — SDD spec skeleton (source: [.github/skills/sdd-spec-template/SKILL.md](../.github/skills/sdd-spec-template/SKILL.md))
- `requirements-extractor` — extract MUST/SHOULD/MAY from long epic/PRD text (source: [.github/skills/requirements-extractor/SKILL.md](../.github/skills/requirements-extractor/SKILL.md))
- `ac-quality-check` — improve acceptance criteria quality (source: [.github/skills/ac-quality-check/SKILL.md](../.github/skills/ac-quality-check/SKILL.md))
- `risk-review` — edge/security/operational/delivery risk review (source: [.github/skills/risk-review/SKILL.md](../.github/skills/risk-review/SKILL.md))
- `test-plan` — unit/integration/e2e test strategy (source: [.github/skills/test-plan/SKILL.md](../.github/skills/test-plan/SKILL.md))
- `rollout-migration` — rollout + migration + rollback planning (source: [.github/skills/rollout-migration/SKILL.md](../.github/skills/rollout-migration/SKILL.md))
- `mcp-integration` — MCP integration addendum for specs (source: [.github/skills/mcp-integration/SKILL.md](../.github/skills/mcp-integration/SKILL.md))

## Note

Agent Skills are preview in VS Code and require enabling the `chat.useAgentSkills` setting.

Tip: keep skill definitions in `.github/skills/` (discoverable) and treat `docs/` as the human-friendly index.
