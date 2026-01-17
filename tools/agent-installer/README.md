# Git-only agent installer

This folder contains a Git-only installer/updater for importing Copilot project agents and their required skills into another repository.

Constraints:
- Git + POSIX-ish shell only (Git Bash / WSL / macOS / Linux)
- No Node.js, Python, `jq`, `npx`
- Safe by default (never overwrite without explicit user choice)

## Install (from a target repo)

From the root of your *target* repo:

```bash
tmp_dir="$(mktemp -d)" && \
  git clone --depth 1 --filter=blob:none --sparse https://github.com/JiKl-coding/jikl-copilot.git "$tmp_dir/jikl-copilot" && \
  git -C "$tmp_dir/jikl-copilot" sparse-checkout set tools/agent-installer && \
  bash "$tmp_dir/jikl-copilot/tools/agent-installer/install.sh" && \
  rm -rf "$tmp_dir"
```

Options:
- `--dry-run`
- `--ref <tag|branch|commit>`
- `--source <url>` (use this for corporate mirrors)

## Update (from a target repo)

```bash
tmp_dir="$(mktemp -d)" && \
  git clone --depth 1 --filter=blob:none --sparse https://github.com/JiKl-coding/jikl-copilot.git "$tmp_dir/jikl-copilot" && \
  git -C "$tmp_dir/jikl-copilot" sparse-checkout set tools/agent-installer && \
  bash "$tmp_dir/jikl-copilot/tools/agent-installer/update.sh" && \
  rm -rf "$tmp_dir"
```

## What it writes

- Agents: `.github/agents/*.agent.md`
- Skills: `.github/skills/<skill>/`
- Manifest: `.github/agent-installer/manifest.json`

The manifest pins the source repo/ref and resolved SHA and tracks which agent files and skill folders were installed.
