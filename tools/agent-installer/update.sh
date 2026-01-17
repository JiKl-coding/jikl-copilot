#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

show_help() {
	say "Git-Only Agent Installer — Update"
	say ""
	say "Updates selected managed agents (and any newly required skills) in the current repo."
	say ""
	usage_common
	say ""
	say "Notes:"
	say "  - Default ref comes from .github/agent-installer/manifest.json (if present)"
	say "  - Local modifications prompt: skip / overwrite / side-by-side .new"
}

manifest_path() {
	echo "$PWD/.github/agent-installer/manifest.json"
}

list_managed_agents_from_manifest() {
	local manifest="$1"
	# Print dest agent filenames (keys under installed.agents)
	awk '
		BEGIN { inAgents=0 }
		/"agents"[[:space:]]*:[[:space:]]*\{/ { inAgents=1; next }
		inAgents && /^[[:space:]]*\}/ { inAgents=0 }
		inAgents {
			if (match($0, /^[[:space:]]*"([^"]+)"[[:space:]]*:/, m)) print m[1]
		}
	' "$manifest" | sed '/^$/d' | sort
}

local_path_modified() {
	local path="$1"
	if is_git_repo; then
		# Any porcelain output for this path means modified/untracked/etc.
		[[ -n "$(git status --porcelain -- "$path" 2>/dev/null)" ]]
		return
	fi
	# Without git: treat existing paths as potentially modified
	[[ -e "$path" ]]
}

copy_file_with_policy() {
	# Args: <src> <dest> <dryRun>
	local src="$1" dest="$2" dry="$3"

	if [[ "$dry" -eq 0 ]]; then
		mkdir -p "$(dirname "$dest")"
	fi
	if [[ ! -e "$dest" ]]; then
		if [[ "$dry" -eq 1 ]]; then say "PLAN: add file $dest"; else cp -f "$src" "$dest"; fi
		return 0
	fi

	if local_path_modified "$dest"; then
		say ""
		say "Local changes detected: $dest"
		say "Choose action: (s)kip, (o)verwrite, write (n)ew side-by-side"
		printf '> '
		read -r action
		case "$action" in
			s|S) return 2;;
			o|O)
				if [[ "$dry" -eq 1 ]]; then say "PLAN: overwrite file $dest"; else cp -f "$src" "$dest"; fi
				return 0
				;;
			n|N)
				local newdest="$dest.new"
				if [[ -e "$newdest" ]]; then die "Already exists: $newdest"; fi
				if [[ "$dry" -eq 1 ]]; then say "PLAN: write file $newdest"; else cp -f "$src" "$newdest"; fi
				return 3
				;;
			*) die "Unknown action: $action";;
		esac
	fi

	# Unmodified tracked file: overwrite without prompt
	if [[ "$dry" -eq 1 ]]; then say "PLAN: overwrite file $dest"; else cp -f "$src" "$dest"; fi
	return 0
}

copy_dir_with_policy() {
	# Args: <srcDir> <destDir> <dryRun>
	local src="$1" dest="$2" dry="$3"

	if [[ "$dry" -eq 0 ]]; then
		mkdir -p "$(dirname "$dest")"
	fi
	if [[ ! -e "$dest" ]]; then
		if [[ "$dry" -eq 1 ]]; then say "PLAN: add dir  $dest"; else cp -R "$src" "$dest"; fi
		return 0
	fi

	if local_path_modified "$dest"; then
		say ""
		say "Local changes detected: $dest"
		say "Choose action: (s)kip, (o)verwrite, write (n)ew side-by-side"
		printf '> '
		read -r action
		case "$action" in
			s|S) return 2;;
			o|O)
				if [[ "$dry" -eq 1 ]]; then
					say "PLAN: overwrite dir  $dest"
				else
					rm -rf "$dest"
					cp -R "$src" "$dest"
				fi
				return 0
				;;
			n|N)
				local newdest="$dest.new"
				if [[ -e "$newdest" ]]; then die "Already exists: $newdest"; fi
				if [[ "$dry" -eq 1 ]]; then say "PLAN: write dir  $newdest"; else cp -R "$src" "$newdest"; fi
				return 3
				;;
			*) die "Unknown action: $action";;
		esac
	fi

	# Unmodified tracked dir: overwrite without prompt
	if [[ "$dry" -eq 1 ]]; then
		say "PLAN: overwrite dir  $dest"
	else
		rm -rf "$dest"
		cp -R "$src" "$dest"
	fi
	return 0
}

main() {
	require_cmd git
	require_cmd awk
	require_cmd sed
	require_cmd sort
	require_cmd cp
	require_cmd mkdir

	if ! parse_args_common "$@"; then
		show_help
		exit 0
	fi

	local manifest
	manifest=$(manifest_path)
	if [[ -f "$manifest" ]]; then
		# If user didn't pass --ref explicitly, prefer pinned ref from manifest.
		local TMP_DIR
		TMP_DIR=$(mktemp_dir)
		trap 'rm -rf "$TMP_DIR"' EXIT
			[[ -n "$pinned" ]] && SOURCE_REF="$pinned"
		fi
	else
		warn "Manifest not found: .github/agent-installer/manifest.json"
		warn "Update will proceed, but managed agents list may be empty."
	fi

	if ! is_git_repo; then
		warn "Current directory is not a Git repository."
		if ! prompt_yes_no "Continue anyway" 1; then
			die "Aborted."
		local skills_tmp="$TMP_DIR/skills.txt"
	fi

	local -a managed=()
	if [[ -f "$manifest" ]]; then
		while IFS= read -r a; do
			[[ -n "$a" ]] || continue
			managed+=("$a")
		done < <(list_managed_agents_from_manifest "$manifest")
	fi

	[[ ${#managed[@]} -gt 0 ]] || die "No managed agents found in manifest. Run install first."

	local selected
	set +e
	selected=$(multi_select "Select agents to UPDATE:" "${managed[@]}")
	local sel_rc=$?
	set -e
	if [[ $sel_rc -eq 2 ]]; then
		die "No selection."
	fi

	local -a agents=()
	while IFS= read -r line; do agents+=("$line"); done <<<"$selected"

	local tmp
	tmp=$(mktemp_dir)
	trap 'rm -rf "$tmp"' EXIT

	local src_repo="$tmp/src"
	clone_source_sparse "$src_repo" "$SOURCE_URL" "$SOURCE_REF"

	# First sparse checkout: mapping + agent files for dependency resolution.
	set_sparse_and_checkout "$src_repo" "$SOURCE_REF" "tools/agentSkillsMap.json" ".github/agents"

	local mapping="$src_repo/tools/agentSkillsMap.json"
	[[ -f "$mapping" ]] || die "Source mapping not found: tools/agentSkillsMap.json"

	# Resolve required skills for selected agents (union)
	local skills_tmp="$tmp/skills.txt"
	: >"$skills_tmp"
	local a
	for a in "${agents[@]}"; do
		sanitize_name "$a" "agent file"
		# Determine corresponding source agent file (from manifest), default same
		local source_agent="$a"
		if [[ -f "$manifest" ]]; then
			source_agent=$(manifest_get_agent_source "$manifest" "$a" || true)
			[[ -n "$source_agent" ]] || source_agent="$a"
		fi
		skills_for_agent "$mapping" "$source_agent" >>"$skills_tmp" || true
	done
		local agents_map="$TMP_DIR/agents_map.tsv"
		local skills_map="$TMP_DIR/skills_map.tsv"
	# Second sparse checkout: only selected agent sources + required skills.
	local -a sparse=("tools/agentSkillsMap.json")
	for a in "${agents[@]}"; do
		local source_agent="$a"
		if [[ -f "$manifest" ]]; then
			source_agent=$(manifest_get_agent_source "$manifest" "$a" || true)
			[[ -n "$source_agent" ]] || source_agent="$a"
		fi
		sparse+=(".github/agents/$source_agent")
	done
	while IFS= read -r s; do
		[[ -n "$s" ]] || continue
		sanitize_name "$s" "skill name"
		sparse+=(".github/skills/$s")
	done <"$skills_tmp"
	set_sparse_and_checkout "$src_repo" "$SOURCE_REF" "${sparse[@]}"

	local source_sha
	source_sha=$(resolve_source_sha "$src_repo")

	say ""
	say "Planned update from: $SOURCE_URL"
	say "Ref: $SOURCE_REF"
	say "Resolved SHA: $source_sha"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		say "Mode: DRY RUN (no writes)"
	fi

	# Apply updates
	if [[ "$DRY_RUN" -eq 0 ]]; then
		mkdir -p "$PWD/.github/agents" "$PWD/.github/skills" "$PWD/.github/agent-installer"
	else
		say "PLAN: ensure dir .github/agents"
		say "PLAN: ensure dir .github/skills"
		say "PLAN: ensure dir .github/agent-installer"
	fi

	local agents_map="$tmp/agents_map.tsv"
	local skills_map="$tmp/skills_map.tsv"
	: >"$agents_map"; : >"$skills_map"
	if [[ -f "$manifest" ]]; then
		manifest_dump_agents_tsv "$manifest" >"$agents_map" || true
		manifest_dump_skills_tsv "$manifest" >"$skills_map" || true
	fi

	local -a updated_agents=() skipped_agents=() new_side_agents=()
	local -a updated_skills=() skipped_skills=() new_side_skills=()

	if [[ "$DRY_RUN" -eq 0 ]]; then
		if ! prompt_yes_no "Proceed with update" 1; then
			die "Aborted."
		fi
	fi

	for a in "${agents[@]}"; do
		local source_agent="$a"
		if [[ -f "$manifest" ]]; then
			source_agent=$(manifest_get_agent_source "$manifest" "$a" || true)
			[[ -n "$source_agent" ]] || source_agent="$a"
		fi
		local unused_tmp="$TMP_DIR/unused.txt"
		[[ -f "$src" ]] || die "Missing source agent file: $source_agent"
		echo -e "$a\t$source_agent\t$source_sha" >>"$agents_map"

		local dest="$PWD/.github/agents/$a"
		copy_file_with_policy "$src" "$dest" "$DRY_RUN"
		case $? in
			0) updated_agents+=("$a");;
			2) skipped_agents+=("$a");;
			3) new_side_agents+=("$a");;
		esac
	done

	# Normalize mapping TSVs (dedupe by dest key, keep last)
	awk -F'\t' 'NF>=2 { s=(NF>=3?$3:""); map[$1]=$2"\t"s } END{ for(k in map) print k"\t"map[k] }' "$agents_map" | sort >"$agents_map.norm"
	mv "$agents_map.norm" "$agents_map"

	# Update required skills
	if [[ -s "$skills_tmp" ]]; then
		while IFS= read -r s; do
			[[ -n "$s" ]] || continue
			sanitize_name "$s" "skill name"
			local srcd="$src_repo/.github/skills/$s"
			[[ -d "$srcd" ]] || die "Missing source skill dir: $s"
			local destd="$PWD/.github/skills/$s"
			echo -e "$s\t$s\t$source_sha" >>"$skills_map"
			copy_dir_with_policy "$srcd" "$destd" "$DRY_RUN"
			case $? in
				0) updated_skills+=("$s");;
				2) skipped_skills+=("$s");;
				3) new_side_skills+=("$s");;
			esac
		done <"$skills_tmp"
	fi

	awk -F'\t' 'NF>=2 { s=(NF>=3?$3:""); map[$1]=$2"\t"s } END{ for(k in map) print k"\t"map[k] }' "$skills_map" | sort >"$skills_map.norm"
	mv "$skills_map.norm" "$skills_map"

	# Unused skill candidates: skills in manifest but not required by any agent in manifest
	local unused_tmp="$tmp/unused.txt"
	: >"$unused_tmp"
	if [[ -f "$manifest" ]]; then
		manifest_list_skills "$manifest" >"$tmp/manifest_skills.txt"

		# Required skills for ALL manifest agents
		: >"$tmp/all_required.txt"
		while IFS= read -r ma; do
			local source_agent
			source_agent=$(manifest_get_agent_source "$manifest" "$ma" || true)
			[[ -n "$source_agent" ]] || source_agent="$ma"
			skills_for_agent "$mapping" "$source_agent" >>"$tmp/all_required.txt" || true
		done < <(list_managed_agents_from_manifest "$manifest")
		sort -u "$tmp/all_required.txt" -o "$tmp/all_required.txt"

		set_diff_lines "$tmp/manifest_skills.txt" "$tmp/all_required.txt" >"$unused_tmp" 2>/dev/null || true
	fi

	# Write manifest (update run)
	local out_manifest
	out_manifest=$(manifest_path)
	if [[ "$DRY_RUN" -eq 1 ]]; then
		say ""
		say "PLAN: update manifest $out_manifest"
	else
		write_manifest "$out_manifest" "$SOURCE_URL" "$SOURCE_REF" "$source_sha" "$agents_map" "$skills_map" "update"
	fi

	# Summary
	say ""
	say "=== Update summary ==="
	say "Updated agents: ${#updated_agents[@]}"
	for x in "${updated_agents[@]}"; do say "  - $x"; done
	if [[ ${#new_side_agents[@]} -gt 0 ]]; then
		say "Agents written as .new:"
		for x in "${new_side_agents[@]}"; do say "  - $x"; done
	fi
	if [[ ${#skipped_agents[@]} -gt 0 ]]; then
		say "Skipped agents:"
		for x in "${skipped_agents[@]}"; do say "  - $x"; done
	fi

	say "Updated skills: ${#updated_skills[@]}"
	for x in "${updated_skills[@]}"; do say "  - $x"; done
	if [[ ${#new_side_skills[@]} -gt 0 ]]; then
		say "Skills written as .new:"
		for x in "${new_side_skills[@]}"; do say "  - $x"; done
	fi
	if [[ ${#skipped_skills[@]} -gt 0 ]]; then
		say "Skipped skills:"
		for x in "${skipped_skills[@]}"; do say "  - $x"; done
	fi

	if [[ -s "$unused_tmp" ]]; then
		say "Unused skill candidates (not removed):"
		while IFS= read -r x; do say "  - $x"; done <"$unused_tmp"
	fi

	say "Manifest: .github/agent-installer/manifest.json"
}

main "$@"
