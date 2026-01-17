# Project agents

VS Code discovers project agents from `.github/agents/*.agent.md`.

Related docs:

- Agents index: this page
- Skills index: see [docs/SKILLS.md](SKILLS.md)
- Copilot basics: see [docs/COPILOT_BASICS_CZ.md](COPILOT_BASICS_CZ.md) (or [EN](COPILOT_BASICS_EN.md))

## Spec Writer v2

- File: [.github/agents/spec-writer.agent.md](../.github/agents/spec-writer.agent.md)
- Purpose: produce clear, review-ready **Spec-Driven Development (SDD)** specifications.
- Default output: a single Markdown spec (Goal / Non-goals / AC / Edge cases / Risks / Test plan) + a short implementation plan.
- It does **not** implement code unless you explicitly ask for implementation.

### Prompt examples

- "Write an SDD spec for adding CSV export. Constraint: no API changes. Done when: handles 10k rows and has tests."
- "Write an SDD spec for refactoring module X. Non-goals: no new features. Include risks and migration plan."
- "Write an SDD spec for integrating service Y; include a sequence diagram and retry/error-handling policy."

## Git Steward

- File: [.github/agents/git-steward.agent.md](../.github/agents/git-steward.agent.md)
- Purpose: perform Git workflows in the terminal (status, add/commit, fetch, rebase onto `origin/main`, conflict resolution).
- Safety: will not push or do destructive operations unless you explicitly ask.

### Prompt examples (Git)

- "Add and commit current changes with message 'WIP: tidy up', then rebase onto origin/main. If conflicts happen, resolve using accept current."
- "Sync my branch with origin/main via rebase. No pushing."
- "Abort the ongoing rebase and restore my working tree."

## Skills

If you enable VS Code Agent Skills (`chat.useAgentSkills`), this repo also provides skills under `.github/skills/`.
See [docs/SKILLS.md](SKILLS.md).

## Notes

- If you add or change agent files under `.github/agents/`, you may need **Developer: Reload Window** in VS Code.
- Keep agent definitions in `.github/agents/` (discoverable) and treat `docs/` as the human-friendly index.

## Registry

This repo also includes a tooling mapping file (useful for future import tooling):

- `tools/agent-skills.json` (agent file → list of skills)

This mapping is maintained only in this repo (the “agent catalog”) as a safety net for a future import tool.

To keep mapping + docs in sync, ask the **Agent Registry Steward** to update `tools/agent-skills.json` and regenerate the auto-generated blocks in this doc and in `docs/SKILLS.md`.

<!-- AGENTS:BEGIN -->
(Auto-generated. Edit agent files under `.github/agents/` and mapping `tools/agent-skills.json`.)

### Agent: Agent Registry Steward

- File: [.github/agents/agent-registry.agent.md](../.github/agents/agent-registry.agent.md)
- Purpose: Creates/updates/deletes project agents and skills, and keeps tools/agent-skills.json + docs (AGENTS.md/SKILLS.md) in sync.

### Agent: Git Steward

- File: [.github/agents/git-steward.agent.md](../.github/agents/git-steward.agent.md)
- Purpose: Performs common Git workflows safely: status, add/commit, sync with origin/main, rebase, and conflict resolution.
- Skills: `git-sync-rebase`

### Agent: Ignorant

- File: [.github/agents/ignorant.agent.md](../.github/agents/ignorant.agent.md)
- Purpose: Nedělá nic jiného než že na všechno odpoví přesně: to mě nezajímá
- Skills: `ignorant`

### Agent: Spec Writer v2

- File: [.github/agents/spec-writer.agent.md](../.github/agents/spec-writer.agent.md)
- Purpose: Agent focused on writing clear, review-ready SDD specifications (single spec or spec pack).
- Skills: `requirements-extractor`, `ac-quality-check`, `risk-review`, `test-plan`, `rollout-migration`, `mcp-integration`
<!-- AGENTS:END -->
