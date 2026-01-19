# 2026-01-17 — Git-Only Agent Bootstrap & Update Installer (v0.1)

## Title & context
This repo contains a catalog of VS Code Copilot **project agents** under `.github/agents/` and optional **agent skills** under `.github/skills/`. The canonical dependency mapping (agent → required skills) is maintained in `tools/agentSkillsMap.json`.

The mapping may also assign optional **knowledge base documents** to agents via the `knowledge-base` field (paths under `knowledge-base/`).

We need a lightweight, Git-only “installer” that lets developers import selected agents (and required skills) from the public repository `JiKl-coding/jikl-copilot` into *any* target repository, including locked-down corporate environments.

## Goal
Provide two Git-only, cross-platform shell commands (install + update) that allow a developer to selectively install and later selectively update Copilot agents and their required skills into a target repository, safely and predictably.

## Non-goals
- Automatically removing skills that are no longer required by any installed agent.
- Supporting package runners or language runtimes as requirements (no `npx`, Node.js, Python, `jq`).
- Managing VS Code settings, extensions, or Copilot entitlements.
- Installing agents from arbitrary third-party sources (only the configured source repo).

## Scope / impact
**In scope (target repository):**
- Adds/updates agent directories under `.github/agents/<agentName>/`.
- Adds/updates skill directories under `.github/skills/<skillName>/`.
- Adds/updates knowledge base documents under `knowledge-base/` (only the documents required by the selected agents).
- Adds a local metadata/lock file (manifest) to track what was installed and from which source ref.

**In scope (source repository):**
- Provides the installer entrypoints (scripts and documentation) that can be executed with a single command from a target repo.
- Uses `tools/agentSkillsMap.json` as the canonical mapping for both skills and knowledge base assignments.

**Compatibility:**
- Must run in Windows Git Bash, WSL, Linux, and macOS with `git` and a POSIX-ish shell available.

## Assumptions
- The user runs commands from the root of a Git repository (the “target repository”).
- Outbound network access to GitHub (or an internal Git mirror of `JiKl-coding/jikl-copilot`) is permitted.
- The target repo can create/modify files under `.github/`.
- The mapping file format in `tools/agentSkillsMap.json` remains “simple JSON” (no comments, standard quoting).

## User stories / scenarios
1. As a developer, I can run a single command in a fresh repo, pick multiple agents from an interactive menu, and get those agents plus required skills installed under `.github/`.
2. As a developer, I can later run a separate update command, pick only a subset of installed agents, and update only those agents (and any newly required skills).
3. As a developer, I am never surprised by destructive changes: overwrites require explicit confirmation, and I can dry-run changes before applying.

## Acceptance criteria (AC)
1. **Single-command install:** From a target repo root, a single shell command fetches installer tooling using Git (no pre-existing files required) and launches the installer UX.
2. **Interactive multi-select (install):** The install command presents an interactive multi-select menu of available agents from the source repo and supports selecting one or more agents.
3. **Dependency resolution:** For each selected agent, the installer determines required skills using `tools/agentSkillsMap.json` from the chosen source ref.
3a. **Knowledge base resolution:** For each selected agent, the installer determines required knowledge base documents using the `knowledge-base` field in `tools/agentSkillsMap.json` from the chosen source ref.
4. **Correct placement:** Installed agents end up under `.github/agents/<agentName>/`; installed skills end up under `.github/skills/<skillName>/`.
4a. **Knowledge base placement:** Installed knowledge base documents end up under `knowledge-base/<path>` (same relative paths as in the mapping).
5. **Git-only minimized download:** The installer uses a Git-only approach (e.g., sparse checkout / shallow clone) to avoid downloading unrelated repository content.
6. **Conflict prompts (install):** If a destination agent/skill directory already exists, the installer prompts per item with options: **overwrite**, **skip**, or **install under alternative name**.
6a. **Conflict prompts (knowledge base):** If a destination knowledge base file already exists, the installer prompts per file with options: **overwrite**, **skip**, or **write side-by-side as `.new`**.
7. **Install summary:** At end of install, output includes: installed agents, installed skills, and a list of items skipped/overwritten/renamed.
7a. **Install summary (knowledge base):** Summary also includes installed knowledge base documents and any conflicts resolved (skipped/overwritten/side-by-side).
8. **Separate update command:** Update is a distinct command from install and is not triggered implicitly during install.
9. **Interactive multi-select (update):** Update command lists currently managed/installed agents in the target repo and supports selecting a subset to update.
10. **Pinned version default:** Update defaults to the pinned source ref stored in local metadata; user may optionally specify a different ref/tag/commit.
11. **Local modification safety:** If local changes are detected in the selected agent/skill paths, update prompts with options: **skip**, **overwrite**, or **write side-by-side as `.new`** (per file or per directory; behavior must be documented).
11a. **Local modification safety (knowledge base):** If local changes are detected in mapped knowledge base documents, update prompts with the same options: **skip**, **overwrite**, or **write side-by-side as `.new`**.
12. **Dependency consistency on update:** Updating an agent also installs/updates any newly required skills; skills no longer required are not removed but are reported as **unused candidates**.
12a. **Knowledge base consistency on update:** Updating an agent also installs/updates any newly required knowledge base documents; documents no longer required are not removed but are reported as **unused candidates**.
13. **Idempotency:** Re-running install/update with the same selections and the same source ref produces no duplicate directories and results are predictable.
14. **Dry-run:** Both install and update support a `--dry-run` mode that prints planned actions (adds/overwrites/renames) without modifying the target repo.
15. **Documentation:** Short usage instructions exist for both commands (install + update), including explanation of dependency mapping and conflict resolution behavior.
15a. **Documentation (knowledge base):** Docs explain how knowledge base documents are selected (from mapping), where they are installed (`knowledge-base/`), and how conflicts are handled.

## Edge cases & error handling
- **No shell features:** If running in a shell lacking required features (e.g., non-bash sh that can’t do arrays), installer exits with a clear message and supported environments.
- **Not a Git repo:** If the target directory is not a Git repository, installer either (a) refuses with a clear message, or (b) proceeds with reduced safety checks; choice must be explicit and documented.
- **Network/auth failures:** If cloning/fetching fails (proxy, auth, TLS interception), show the failing Git command and a suggestion for using a corporate mirror via an env var/config.
- **Missing/unknown agent mapping:** If an agent exists in `.github/agents/` but is missing from the mapping file, installer treats it as “no declared skills” and warns.
- **Missing knowledge-base field:** If an agent exists in mapping but has no `knowledge-base` field, treat as “no assigned knowledge base documents” (backward compatibility).
- **Missing knowledge base document:** If mapping references a file under `knowledge-base/` that does not exist in the source repo at the selected ref, installer fails fast (or offers to continue without that document) and reports clearly.
- **Missing skill directory:** If mapping references a skill not present in source `.github/skills/`, installer fails fast (or offers to continue without it) and reports clearly.
- **Partial installs:** If interrupted midway, next run should detect and continue safely (no silent overwrites).
- **Rename collisions:** If “install under alternative name” conflicts with an existing destination, installer re-prompts.
- **CRLF/LF:** Scripts must tolerate Windows line endings in the target repo and avoid corrupting `.agent.md` formatting.
- **Binary/large docs:** Installer treats knowledge base documents as opaque files (copy bytes); any size limits (if introduced) must be documented.

## Security & privacy
- **Transparency:** Before destructive actions, show the exact destination paths affected and require explicit user choice.
- **Source integrity:** Record the exact source repo and resolved commit SHA in local metadata, even when the user specifies a branch/tag.
- **No secret handling:** Installer must not print credentials; it should rely on Git’s configured credential helpers.
- **Path safety:** Prevent path traversal (agent/skill names must not allow `../` or absolute paths).
- **Path safety (knowledge base):** Prevent path traversal in knowledge base paths: only allow paths strictly under `knowledge-base/`.

## Telemetry/Logging
- No external telemetry.
- Console output must be structured enough for CI logs (when non-interactive mode is later added), including a final summary block.

## Test plan
**Unit-level (script logic):**
- Parse/list agents from source and validate stable ordering.
- Resolve agent → skills from the mapping for: single agent, multiple agents, overlapping skills.
- Resolve agent → knowledge base documents from mapping for: missing field, empty list, multiple docs, overlap across agents.
- Validate name sanitization and path traversal protection.
- Validate knowledge base path constraints (must start with `knowledge-base/`; reject `../` and absolute paths).
- Compute plan for `--dry-run` without writing.

**Integration (git + filesystem):**
- Install into an empty temp repo: select 2 agents, verify correct directories and manifest.
- Install knowledge base docs: select an agent with mapped knowledge base docs, verify files exist under `knowledge-base/`.
- Re-run install with same selection: verify idempotency (no duplicates; no unnecessary prompts).
- Install with pre-existing agent/skill directories: verify prompts and correct outcomes for overwrite/skip/rename.
- Install with pre-existing knowledge base file: verify overwrite/skip/side-by-side `.new` prompt.
- Update flow with local modifications:
  - modified file → choose skip
  - modified file → choose overwrite
  - modified file → choose side-by-side `.new`
- Update flow with local modifications (knowledge base file) covers skip/overwrite/side-by-side `.new`.
- Update introduces a newly required skill: verify it is installed.
- Update drops a previously required skill: verify it is reported as unused candidate but not removed.
- Update introduces a newly required knowledge base doc: verify it is installed.
- Update drops a previously required knowledge base doc: verify it is reported as unused candidate but not removed.

**Manual cross-platform verification (minimum set):**
- Windows Git Bash: install + update interactive menus work.
- WSL/Linux/macOS: install + update interactive menus work.

## Rollout / migration
- First release as “experimental”; include a clear rollback instruction: delete `.github/agents/<installed>` and `.github/skills/<installed>` and the manifest file.
- Add a “mirror” configuration option (env var) early to support corporate GitHub mirroring.

## Open questions
1. Where should the local metadata live (e.g., `.github/agent-installer/manifest.json` vs `.github/agent-installer.lock.json`)?
2. Should “managed agents” be defined strictly as those recorded in manifest, or also “anything under `.github/agents/` that matches known names”?
3. Should installer support a non-interactive mode (flags) now, or defer to later?

---

## Implementation plan (high level)
1. Define CLI surfaces: `install` and `update`, plus common flags (`--dry-run`, `--ref`, `--source <url>`). Verify: help text and docs match.
2. Choose/define manifest schema (repo, ref, resolved SHA, installed agents/skills/knowledge base docs, timestamps). Verify: schema example included in docs.
3. Implement Git-only fetch strategy (sparse + shallow) to read agent list and mapping, then fetch only selected paths (agents + skills + knowledge-base docs). Verify: network transfer size is small compared to full clone.
4. Implement interactive multi-select menus (no external tools). Verify: selection supports multiple choices and cancel.
5. Implement conflict detection + prompts (overwrite/skip/rename; update adds `.new`). Verify: behavior matches AC and is consistent across install/update.
6. Implement dependency resolution from `tools/agentSkillsMap.json` without Node/Python/jq, including `knowledge-base` paths. Verify: resolution works for current repo mappings, including missing/empty `knowledge-base`, and fails clearly on malformed JSON.
7. Implement local modification detection using Git when available (fallback to checksums if needed) for agents, skills, and knowledge base files. Verify: modified files are detected and prompt shown.
8. Write/update documentation pages with short usage. Verify: a new user can follow in <5 minutes.
9. Add lightweight integration test scripts (shell) runnable in CI later (optional). Verify: scripts produce deterministic pass/fail.
