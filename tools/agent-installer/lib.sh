#!/usr/bin/env bash
set -euo pipefail

# Common helpers for the Git-only agent installer.
# Git-only + standard shell utilities; no jq/node/python.

say() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_git_repo() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

now_utc() {
	# ISO-ish, portable
	date -u '+%Y-%m-%dT%H:%M:%SZ'
}

mktemp_dir() {
	# mktemp -d is available in Git Bash/WSL/macOS/Linux.
	mktemp -d 2>/dev/null || mktemp -d -t 'jikl-agent-installer'
}

sanitize_name() {
	# Reject path traversal and separators.
	# Usage: sanitize_name "value" "label"
	local value="$1"
	local label="$2"
	[[ -n "$value" ]] || die "$label must not be empty"
	case "$value" in
		*'..'*|*'/'*|*'\\'* ) die "Invalid $label: $value";;
	esac
}

parse_args_common() {
	# Outputs: sets global vars DRY_RUN, SOURCE_URL, SOURCE_REF
	DRY_RUN=0
	REF_PROVIDED=0
	SOURCE_URL="${JIKL_COPILOT_SOURCE_URL:-https://github.com/JiKl-coding/jikl-copilot.git}"
	SOURCE_REF="${JIKL_COPILOT_SOURCE_REF:-main}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dry-run)
				DRY_RUN=1
				shift
				;;
			--source)
				SOURCE_URL="$2"
				shift 2
				;;
			--ref)
				SOURCE_REF="$2"
				REF_PROVIDED=1
				shift 2
				;;
			-h|--help)
				return 1
				;;
			*)
				die "Unknown argument: $1"
				;;
		esac
	done
}

usage_common() {
	cat <<EOF
Options:
  --dry-run         Print planned actions, do not write to target repo
  --source <url>    Source repo URL (default: $SOURCE_URL)
  --ref <ref>       Source ref/tag/commit (default: $SOURCE_REF)

Environment variables:
  JIKL_COPILOT_SOURCE_URL
  JIKL_COPILOT_SOURCE_REF
EOF
}

# Clone minimal parts of the source repo into a temp dir.
# Args: <destDir> <sourceUrl> <ref>
# Creates a repo with sparse checkout initialized.
clone_source_sparse() {
	local dest="$1"
	local url="$2"
	local ref="$3"

	mkdir -p "$dest"
	git init -q "$dest"
	(
		cd "$dest"
		git remote add origin "$url"
		# Fetch requested ref shallowly.
		# Works for branches/tags; for SHAs, fetch may fail unless reachable.
		git fetch -q --filter=blob:none --depth 1 origin "$ref" \
			|| git fetch -q --depth 1 origin "$ref" \
			|| git fetch -q --filter=blob:none --depth 1 origin "refs/heads/$ref" \
			|| git fetch -q --depth 1 origin "refs/heads/$ref" \
			|| die "Failed to fetch ref '$ref' from $url"
		git sparse-checkout init --no-cone
	)
}

# Checkout a set of sparse patterns at the fetched ref.
# Args: <repoDir> <ref> <pattern...>
set_sparse_and_checkout() {
	local repo="$1"
	local ref="$2"
	shift 2
	(
		cd "$repo"
		git sparse-checkout set --no-cone -- "$@"
		git checkout -q FETCH_HEAD
	)
}

resolve_source_sha() {
	local repo="$1"
	(
		cd "$repo"
		git rev-parse HEAD
	)
}

# List agent files from source mapping file.
# Prints: <agentFile>\t<displayName>
list_agents_from_mapping() {
	local mapping_file="$1"
	awk '
		BEGIN { inAgents=0; depth=0; key=""; name="" }
		/"agents"[[:space:]]*:[[:space:]]*\{/ { inAgents=1; depth=1; next }
		inAgents {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*\{/, m)) { key=m[1]; name="" }
			if (key != "" && match($0, /"name"[[:space:]]*:[[:space:]]*"([^"]+)"/, n)) { name=n[1] }
			if (key != "" && name != "") { printf "%s\t%s\n", key, name; key=""; name="" }

			# Track brace depth to know when agents object ends
			line=$0
			opens=gsub(/\{/, "{", line)
			closes=gsub(/\}/, "}", line)
			depth += opens - closes
			if (depth <= 0) { inAgents=0; exit }
		}
	' "$mapping_file" | sort
}

# Resolve skills for a single agent file.
# Prints one skill per line.
skills_for_agent() {
	local mapping_file="$1"
	local agent_file="$2"
	awk -v agent="$agent_file" '
		BEGIN { inAgents=0; depth=0; inTarget=0; inSkills=0 }
		/"agents"[[:space:]]*:[[:space:]]*\{/ { inAgents=1; depth=1; next }
		inAgents {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:[[:space:]]*\{/, m)) {
				inTarget = (m[1] == agent) ? 1 : 0
				inSkills = 0
			}
			if (inTarget && $0 ~ /"skills"[[:space:]]*:[[:space:]]*\[/) { inSkills=1; next }
			if (inTarget && inSkills) {
				if ($0 ~ /\]/) { inSkills=0; next }
				if (match($0, /"([^"]+)"/, s)) { print s[1] }
			}

			line=$0
			opens=gsub(/\{/, "{", line)
			closes=gsub(/\}/, "}", line)
			depth += opens - closes
			if (depth <= 0) { inAgents=0; exit }
		}
	' "$mapping_file" | sed '/^$/d'
}

# Prompt helpers
prompt_yes_no() {
	local prompt="$1"
	local default_no="${2:-1}"
	local reply
	if [[ "$default_no" -eq 1 ]]; then
		printf '%s [y/N]: ' "$prompt"
	else
		printf '%s [Y/n]: ' "$prompt"
	fi
	read -r reply || return 1
	case "$reply" in
		y|Y|yes|YES) return 0;;
		n|N|no|NO|"") return 1;;
		*) return 1;;
	esac
}

# Multi-select: user inputs numbers/ranges. Prints selected items, one per line.
# Args: <title> then list items
multi_select() {
	local title="$1"; shift
	local -a items=("$@")
	local count=${#items[@]}
	local input

	[[ $count -gt 0 ]] || die "Nothing to select."

	printf '%s\n' "$title" >&2
	local i
	for ((i=0; i<count; i++)); do
		printf '  %2d) %s\n' $((i+1)) "${items[$i]}" >&2
	done
	printf '%s\n' "Enter selections as numbers (e.g. 1 3 5 or 1-3). Empty cancels." >&2
	printf '> ' >&2
	read -r input || return 1
	[[ -n "$input" ]] || return 2

	# Normalize separators
	input="${input//,/ }"
	local -A picked=()
	for token in $input; do
		if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
			local start=${token%-*}
			local end=${token#*-}
			[[ $start -ge 1 && $end -le $count && $start -le $end ]] || die "Invalid range: $token"
			for ((i=start; i<=end; i++)); do picked[$i]=1; done
		elif [[ "$token" =~ ^[0-9]+$ ]]; then
			[[ $token -ge 1 && $token -le $count ]] || die "Invalid selection: $token"
			picked[$token]=1
		else
			die "Invalid token: $token"
		fi
	done

	for i in "${!picked[@]}"; do
		echo "${items[$((i-1))]}"
	done | sort
}

copy_file_safely() {
	# Args: <src> <dest> <dryRun>
	local src="$1"
	local dest="$2"
	local dry="$3"

	if [[ "$dry" -eq 0 ]]; then
		mkdir -p "$(dirname "$dest")"
	fi
	if [[ -e "$dest" ]]; then
		return 10
	fi
	if [[ "$dry" -eq 1 ]]; then
		say "PLAN: add file $dest"
		return 0
	fi
	cp -f "$src" "$dest"
}

copy_dir_safely() {
	# Args: <srcDir> <destDir> <dryRun>
	local src="$1"
	local dest="$2"
	local dry="$3"

	if [[ -e "$dest" ]]; then
		return 10
	fi
	if [[ "$dry" -eq 1 ]]; then
		say "PLAN: add dir  $dest"
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	cp -R "$src" "$dest"
}

write_manifest() {
	# Args: <manifestPath> <sourceUrl> <sourceRef> <sourceSha> <agentsFile> <skillsFile> <mode>
	# agentsFile lines: destAgent\tsrcAgent[\tsha]
	# skillsFile lines: destSkill\tsrcSkill[\tsha]
	local manifest="$1"
	local url="$2"
	local ref="$3"
	local sha="$4"
	local agents_list="$5"
	local skills_list="$6"
	local mode="$7"

	mkdir -p "$(dirname "$manifest")"
	local ts
	ts=$(now_utc)

	# Build JSON with awk to avoid non-portable printf issues.
	awk -F"\t" -v url="$url" -v ref="$ref" -v sha="$sha" -v ts="$ts" -v mode="$mode" '
		BEGIN {
			print "{";
			print "  \"version\": 1,";
			print "  \"source\": {";
			print "    \"url\": \"" url "\",";
			print "    \"ref\": \"" ref "\",";
			print "    \"sha\": \"" sha "\"";
			print "  },";
			print "  \"lastRun\": { \"mode\": \"" mode "\", \"timestamp\": \"" ts "\" },";
			print "  \"installed\": {";
			print "    \"agents\": {";
		}
		FNR==NR {
			# agents_list: dest \t source [\t sha]
			if (NF >= 2) {
				dest=$1; src=$2; itemSha=(NF>=3?$3:sha);
				agentsSrc[dest]=src;
				agentsSha[dest]=itemSha;
			}
			next
		}
		{
			# skills_list: dest \t source [\t sha]
			if (NF >= 2) {
				dest=$1; src=$2; itemSha=(NF>=3?$3:sha);
				skillsSrc[dest]=src;
				skillsSha[dest]=itemSha;
			}
		}
		END {
			# agents
			first=1
			for (k in agentsSrc) {
				printf "      %s\"%s\": { \"source\": \"%s\", \"sha\": \"%s\" }\n", (first?"":",\n"), k, agentsSrc[k], agentsSha[k];
				first=0
			}
			if (first==1) print "";
			print "    },";
			# skills
			print "    \"skills\": {";
			first=1
			for (s in skillsSrc) {
				printf "      %s\"%s\": { \"source\": \"%s\", \"sha\": \"%s\" }\n", (first?"":",\n"), s, skillsSrc[s], skillsSha[s];
				first=0
			}
			if (first==1) print "";
			print "    }";
			print "  }";
			print "}";
		}
	' "$agents_list" "$skills_list" >"$manifest"
}

read_manifest_field() {
	# Extremely small JSON field extraction; intended for our manifest schema.
	# Args: <manifestPath> <fieldRegex>
	local manifest="$1"
	local regex="$2"
	grep -E "$regex" "$manifest" | head -n 1 | sed -E 's/.*"([^"]+)"[[:space:]]*:[[:space:]]*"([^"]+)".*/\2/'
}

manifest_get_agent_source() {
	# Args: <manifestPath> <destAgentFile>
	local manifest="$1"
	local dest_agent="$2"
	awk -v key="$dest_agent" '
		BEGIN { inAgents=0; inTarget=0 }
		/"agents"[[:space:]]*:[[:space:]]*\{/ { inAgents=1; next }
		inAgents && /^[[:space:]]*\}/ { inAgents=0 }
		inAgents {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:/, m)) inTarget = (m[1] == key) ? 1 : 0
			if (inTarget && match($0, /"source"[[:space:]]*:[[:space:]]*"([^"]+)"/, s)) { print s[1]; exit }
		}
	' "$manifest"
}

manifest_dump_agents_tsv() {
	# Args: <manifestPath>
	# Output: destAgent\tsourceAgent\tsha
	local manifest="$1"
	awk '
		BEGIN { inAgents=0; key=""; src=""; sha="" }
		/"agents"[[:space:]]*:[[:space:]]*\{/ { inAgents=1; next }
		inAgents && /^[[:space:]]*\}/ { inAgents=0 }
		inAgents {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:/, m)) { key=m[1]; src=""; sha="" }
			if (key != "" && match($0, /"source"[[:space:]]*:[[:space:]]*"([^"]+)"/, s)) src=s[1]
			if (key != "" && match($0, /"sha"[[:space:]]*:[[:space:]]*"([^"]+)"/, h)) sha=h[1]
			if (key != "" && src != "") { printf "%s\t%s\t%s\n", key, src, sha; key=""; src=""; sha="" }
		}
	' "$manifest" | sed '/^$/d'
}

manifest_dump_skills_tsv() {
	# Args: <manifestPath>
	# Output: destSkill\tsourceSkill\tsha
	local manifest="$1"
	awk '
		BEGIN { inSkills=0; key=""; src=""; sha="" }
		/"skills"[[:space:]]*:[[:space:]]*\{/ { inSkills=1; next }
		inSkills && /^[[:space:]]*\}/ { inSkills=0 }
		inSkills {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:/, m)) { key=m[1]; src=""; sha="" }
			if (key != "" && match($0, /"source"[[:space:]]*:[[:space:]]*"([^"]+)"/, s)) src=s[1]
			if (key != "" && match($0, /"sha"[[:space:]]*:[[:space:]]*"([^"]+)"/, h)) sha=h[1]
			if (key != "" && src != "") { printf "%s\t%s\t%s\n", key, src, sha; key=""; src=""; sha="" }
		}
	' "$manifest" | sed '/^$/d'
}

manifest_list_skills() {
	# Args: <manifestPath>
	local manifest="$1"
	awk '
		BEGIN { inSkills=0 }
		/"skills"[[:space:]]*:[[:space:]]*\{/ { inSkills=1; next }
		inSkills && /^[[:space:]]*\}/ { inSkills=0 }
		inSkills { if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:/, m)) print m[1] }
	' "$manifest" | sed '/^$/d' | sort -u
}

set_diff_lines() {
	# Print items in A not in B. Both files contain 1 item per line.
	# Uses awk only (portable), avoids `comm`.
	local a_file="$1"
	local b_file="$2"
	awk 'FNR==NR { b[$0]=1; next } { if (!($0 in b) && $0!="") print $0 }' "$b_file" "$a_file" | sort -u
}
