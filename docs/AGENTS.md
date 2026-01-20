# Project agents

VS Code discovers project agents from `.github/agents/*.agent.md`.

Related docs:

- Agents index: this page
- Skills index: see [docs/SKILLS.md](SKILLS.md)
- Copilot basics: see [docs/COPILOT_BASICS_CZ.md](COPILOT_BASICS_CZ.md) (or [EN](COPILOT_BASICS_EN.md))

## Spec Writer v2

- File: [.github/agents/spec-writer.agent.md](../.github/agents/spec-writer.agent.md)
- Purpose: produce clear, review-ready **Spec-Driven Development (SDD)** specifications (including spec packs with cross-linked docs).
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

## Documentation Writer

- File: [.github/agents/documentation-writer.agent.md](../.github/agents/documentation-writer.agent.md)
- Purpose: produce clear documentation from provided context/specs (READMEs, guides, API docs, ADRs, runbooks).

### Prompt examples (Docs)

- "Write a README section for feature X based on this spec. Include prerequisites, usage steps, and a verification checklist."
- "Create an ops runbook for service Y: symptoms, quick checks, mitigation, rollback. Use this incident summary + architecture notes."
- "Turn this API spec into reference docs with examples and error-handling guidance."

## Skills

If you enable VS Code Agent Skills (`chat.useAgentSkills`), this repo also provides skills under `.github/skills/`.
See [docs/SKILLS.md](SKILLS.md).

## Notes

- If you add or change agent files under `.github/agents/`, you may need **Developer: Reload Window** in VS Code.
- Keep agent definitions in `.github/agents/` (discoverable) and treat `docs/` as the human-friendly index.

## Registry

This repo also includes a tooling mapping file (useful for future import tooling):

- `tools/agentSkillsMap.json` (agent file → list of skills)

The mapping also tracks optional knowledge base document assignments per agent via the `knowledge-base` field (paths under `knowledge-base/`).

This mapping is maintained only in this repo (the “agent catalog”) as a safety net for a future import tool.

To keep mapping + docs in sync, ask the **Agent Manager** to update `tools/agentSkillsMap.json` and regenerate the auto-generated blocks in this doc and in `docs/SKILLS.md`.

<!-- AGENTS:BEGIN -->
(Auto-generated. Edit agent files under `.github/agents/` and mapping `tools/agentSkillsMap.json` (skills + knowledge-base).)

### Agent: Agent Manager

- File: [.github/agents/agent-manager.agent.md](../.github/agents/agent-manager.agent.md)
- Purpose: Maintains project agents/skills and keeps tools/agentSkillsMap.json + docs (AGENTS.md/SKILLS.md) in sync; stays strictly within agent-system scope unless explicitly asked.
- Skills: `identify-self`
- Knowledge base: (none)

### Agent: Documentation Writer

- File: [.github/agents/documentation-writer.agent.md](../.github/agents/documentation-writer.agent.md)
- Purpose: Writes documentation only (READMEs, guides, API docs, runbooks) from provided context/specs; does not refactor/implement code or run commands unless explicitly asked.
- Skills: `identify-self`
- Knowledge base: (none)

### Agent: Git-Only Agent Installer

- File: [.github/agents/git-only-agent-installer.agent.md](../.github/agents/git-only-agent-installer.agent.md)
- Purpose: Designs and implements Git-only shell scripts to install/update selected Copilot project agents and their required skills into other repositories, per the installer spec.
- Skills: `identify-self`
- Knowledge base: (none)

### Agent: Git Steward

- File: [.github/agents/git-steward.agent.md](../.github/agents/git-steward.agent.md)
- Purpose: Performs Git workflows safely (status, add/commit, sync, rebase, conflicts); Git-only scope and no code refactors/feature work unless explicitly asked.
- Skills: `identify-self`, `git-sync-rebase`
- Knowledge base: (none)

### Agent: Spec Writer v2

- File: [.github/agents/spec-writer.agent.md](../.github/agents/spec-writer.agent.md)
- Purpose: Writes clear, review-ready SDD specifications (single spec or spec pack with auto cross-links); does not implement/refactor code unless explicitly asked.
- Skills: `identify-self`, `requirements-extractor`, `ac-quality-check`, `risk-review`, `test-plan`, `rollout-migration`, `mcp-integration`
- Knowledge base: (none)
<!-- AGENTS:END -->
