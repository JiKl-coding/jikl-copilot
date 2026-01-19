
# Git-only agent installer

> **Note:** This script was created using the spec-writte agent and the git-only agent.

This folder contains a Git-only installer for importing Copilot project agents and their required skills into another repository.

The installer also copies any required knowledge-base documents assigned to agents via the mapping in `tools/agentSkillsMap.json`. These are placed under `knowledge-base/` in the target repository.

Constraints:
- Git + POSIX-ish shell only (Git Bash / WSL / macOS / Linux)
- No Node.js, Python, `jq`, `npx`
- Safe by default (never overwrite without explicit user choice)

## Install (from a target repo)

From the root of your *target* repo:

### Simple (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh | bash
```

With options:

```bash
curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh | bash -s -- --dry-run
```

### Manual (alternative)

```bash
tmp_dir="$(mktemp -d)" && \
  git clone --depth 1 --filter=blob:none --sparse https://github.com/JiKl-coding/jikl-copilot.git "$tmp_dir/jikl-copilot" && \
  git -C "$tmp_dir/jikl-copilot" sparse-checkout set tools/agent-installer && \
  bash "$tmp_dir/jikl-copilot/tools/agent-installer/install.sh" && \
  rm -rf "$tmp_dir"
```

### Options

- `--dry-run` — Show what would be installed without making any changes to the target repo. Useful for previewing the impact before committing to the installation.
- `--ref <tag|branch|commit>` — Install from a specific Git ref (tag, branch name, or commit SHA) instead of the default `main` branch. Use this to pin to a specific version or test unreleased changes.
- `--source <url>` — Use a different source repository URL. Useful for corporate GitHub mirrors or forks.

**Examples:**

```bash
# Preview what would be installed
curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh | bash -s -- --dry-run

# Install from a specific tag
curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh | bash -s -- --ref v1.0.0

# Use a corporate mirror
curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh | bash -s -- --source https://github.internal.corp/mirrors/jikl-copilot.git
```

## Conflict handling

If a selected agent or skill already exists in the target repo, the installer will prompt you per item with options to overwrite, skip, or rename.

If a required knowledge-base document already exists, the installer will prompt you per file with options to overwrite, skip, or write side-by-side as `.new`.

## What it writes

- Agents: `.github/agents/*.agent.md`
- Skills: `.github/skills/<skill>/`
- Knowledge base documents: `knowledge-base/<path>`
- Manifest: `.github/agent-installer/manifest.json`

The manifest pins the source repo/ref and resolved SHA and tracks which agent files and skill folders were installed.
