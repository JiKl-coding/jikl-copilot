#!/usr/bin/env bash
# Git-only agent installer bootstrap
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/JiKl-coding/jikl-copilot/main/tools/agent-installer/bootstrap.sh)
# Or with options: bash <(curl -fsSL ...) --dry-run --ref main

set -euo pipefail

# Redirect stdin from terminal so interactive prompts work when piped from curl
exec < /dev/tty

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

git clone --depth 1 --filter=blob:none --sparse https://github.com/JiKl-coding/jikl-copilot.git "$tmp_dir/jikl-copilot"
git -C "$tmp_dir/jikl-copilot" sparse-checkout set tools/agent-installer
bash "$tmp_dir/jikl-copilot/tools/agent-installer/install.sh" "$@"
