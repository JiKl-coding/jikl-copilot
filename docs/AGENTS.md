# Project agents

VS Code discovers project agents from `.github/agents/*.agent.md`.

Related docs:
- Agents index: this page
- Skills index: see [docs/SKILLS.md](SKILLS.md)
- Copilot basics: see [docs/COPILOT_BASICS.md](COPILOT_BASICS.md)

## Spec Writer v2

- File: [.github/agents/spec-writer.agent.md](../.github/agents/spec-writer.agent.md)
- Purpose: produce clear, review-ready **Spec-Driven Development (SDD)** specifications.
- Default output: a single Markdown spec (Goal / Non-goals / AC / Edge cases / Risks / Test plan) + a short implementation plan.
- It does **not** implement code unless you explicitly ask for implementation.

### Prompt examples

- "Write an SDD spec for adding CSV export. Constraint: no API changes. Done when: handles 10k rows and has tests."
- "Write an SDD spec for refactoring module X. Non-goals: no new features. Include risks and migration plan."
- "Write an SDD spec for integrating service Y; include a sequence diagram and retry/error-handling policy."

## Skills

If you enable VS Code Agent Skills (`chat.useAgentSkills`), this repo also provides skills under `.github/skills/`.
See [docs/SKILLS.md](SKILLS.md).

## Notes

- If you add or change agent files under `.github/agents/`, you may need **Developer: Reload Window** in VS Code.
- Keep agent definitions in `.github/agents/` (discoverable) and treat `docs/` as the human-friendly index.
