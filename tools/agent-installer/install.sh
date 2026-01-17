#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

show_help() {
	say "Git-Only Agent Installer — Install"
	say ""
	say "Installs selected Copilot project agents and required skills into the current repo."
	say ""
	usage_common
	say ""
	say "Notes:"
	say "  - Agents install as files under .github/agents/*.agent.md"
	say "  - Skills install as directories under .github/skills/<skill>/"
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

	local target_root
	target_root="$PWD"

	# Safety check: prefer Git repos
	if ! is_git_repo; then
		warn "Current directory is not a Git repository."
		if ! prompt_yes_no "Continue anyway" 1; then
			die "Aborted."
		fi
	fi

	TMP_DIR=$(mktemp_dir)
	trap 'rm -rf "$TMP_DIR"' EXIT

	local src_repo
	src_repo="$TMP_DIR/src"
	clone_source_sparse "$src_repo" "$SOURCE_URL" "$SOURCE_REF"

	# First sparse checkout: mapping + agent files for selection
	set_sparse_and_checkout "$src_repo" "$SOURCE_REF" "tools/agentSkillsMap.json" ".github/agents"

	local mapping="$src_repo/tools/agentSkillsMap.json"
	[[ -f "$mapping" ]] || die "Source mapping not found: tools/agentSkillsMap.json"

	# Build selectable list: "<agentFile> — <name>"
	local -a choices=()
	while IFS=$'\t' read -r agent_file display_name; do
		[[ -n "$agent_file" ]] || continue
		choices+=("$agent_file — $display_name")
	done < <(list_agents_from_mapping "$mapping")

	local selected
	set +e
	selected=$(multi_select "Select agents to INSTALL (from $SOURCE_URL@$SOURCE_REF):" "${choices[@]}")
	local sel_rc=$?
	set -e
	if [[ $sel_rc -eq 2 ]]; then
		die "No selection."
	fi

	# Extract agent filenames
	local -a agents=()
	while IFS= read -r line; do
		agents+=("${line%% — *}")
	done <<<"$selected"

	# Resolve required skills (union)
	local skills_tmp="$TMP_DIR/skills.txt"
	: >"$skills_tmp"
	local a
	for a in "${agents[@]}"; do
		sanitize_name "$a" "agent file"
		skills_for_agent "$mapping" "$a" >>"$skills_tmp" || true
	done
	sort -u "$skills_tmp" -o "$skills_tmp"

	# Prepare second sparse checkout: selected agents + required skills
	local -a sparse=("tools/agentSkillsMap.json")
	for a in "${agents[@]}"; do
		sparse+=(".github/agents/$a")
	done
	while IFS= read -r s; do
		[[ -n "$s" ]] || continue
		sanitize_name "$s" "skill name"
		sparse+=(".github/skills/$s")
	done <"$skills_tmp"

	set_sparse_and_checkout "$src_repo" "$SOURCE_REF" "${sparse[@]}"
	local source_sha
	source_sha=$(resolve_source_sha "$src_repo")

	# Build plan and perform copies
	if [[ "$DRY_RUN" -eq 0 ]]; then
		mkdir -p "$target_root/.github/agents" "$target_root/.github/skills" "$target_root/.github/agent-installer"
	else
		say "PLAN: ensure dir .github/agents"
		say "PLAN: ensure dir .github/skills"
		say "PLAN: ensure dir .github/agent-installer"
	fi
	local manifest="$target_root/.github/agent-installer/manifest.json"

	local agents_map="$TMP_DIR/agents_map.tsv"
	local skills_map="$TMP_DIR/skills_map.tsv"
	: >"$agents_map"; : >"$skills_map"

	local -a installed_agents=() skipped_agents=() renamed_agents=()
	local -a installed_skills=() skipped_skills=() renamed_skills=()
	local overwrite_count=0

	say ""
	say "Planned install from: $SOURCE_URL"
	say "Ref: $SOURCE_REF"
	say "Resolved SHA: $source_sha"
	if [[ "$DRY_RUN" -eq 1 ]]; then
		say "Mode: DRY RUN (no writes)"
	fi

	# Show high-level plan
	say ""
	say "Agents selected:"
	for a in "${agents[@]}"; do say "  - .github/agents/$a"; done
	say "Skills required:"
	if [[ -s "$skills_tmp" ]]; then
		while IFS= read -r s; do say "  - .github/skills/$s/"; done <"$skills_tmp"
	else
		say "  (none)"
	fi

	if [[ "$DRY_RUN" -eq 0 ]]; then
		if ! prompt_yes_no "Proceed with install" 1; then
			die "Aborted."
		fi
	fi

	# Copy agents
	for a in "${agents[@]}"; do
		local src="$src_repo/.github/agents/$a"
		[[ -f "$src" ]] || die "Missing source agent file: $a"
		local dest="$target_root/.github/agents/$a"

		if [[ -e "$dest" ]]; then
			say ""
			say "Agent exists: .github/agents/$a"
			say "Choose action: (o)verwrite, (s)kip, (r)ename"
			printf '> '
			read -r action
			case "$action" in
				o|O)
					overwrite_count=$((overwrite_count+1))
					if [[ "$DRY_RUN" -eq 1 ]]; then
						say "PLAN: overwrite file $dest"
					else
						cp -f "$src" "$dest"
					fi
					installed_agents+=("$a")
					echo -e "$a\t$a\t$source_sha" >>"$agents_map"
					;;
				s|S)
					skipped_agents+=("$a")
					;;
				r|R)
					say "Enter new agent filename (must end with .agent.md):"
					printf '> '
					read -r newname
					sanitize_name "$newname" "agent filename"
					[[ "$newname" == *.agent.md ]] || die "Agent filename must end with .agent.md"
					local newdest="$target_root/.github/agents/$newname"
					if [[ -e "$newdest" ]]; then
						die "Destination already exists: .github/agents/$newname"
					fi
					if [[ "$DRY_RUN" -eq 1 ]]; then
						say "PLAN: add file $newdest (renamed from $a)"
					else
						cp -f "$src" "$newdest"
					fi
					renamed_agents+=("$a -> $newname")
					echo -e "$newname\t$a\t$source_sha" >>"$agents_map"
					;;
				*)
					die "Unknown action: $action"
					;;
			esac
		else
			copy_file_safely "$src" "$dest" "$DRY_RUN" || true
			installed_agents+=("$a")
			echo -e "$a\t$a\t$source_sha" >>"$agents_map"
		fi
	done

	# Copy skills
	if [[ -s "$skills_tmp" ]]; then
		while IFS= read -r s; do
			[[ -n "$s" ]] || continue
			local srcd="$src_repo/.github/skills/$s"
			[[ -d "$srcd" ]] || die "Missing source skill dir: $s"
			local destd="$target_root/.github/skills/$s"

			if [[ -e "$destd" ]]; then
				say ""
				say "Skill exists: .github/skills/$s"
				say "Choose action: (o)verwrite, (s)kip, (r)ename"
				printf '> '
				read -r action
				case "$action" in
					o|O)
						overwrite_count=$((overwrite_count+1))
						if [[ "$DRY_RUN" -eq 1 ]]; then
							say "PLAN: overwrite dir  $destd"
						else
							rm -rf "$destd"
							cp -R "$srcd" "$destd"
						fi
						installed_skills+=("$s")
						echo -e "$s\t$s\t$source_sha" >>"$skills_map"
						;;
					s|S)
						skipped_skills+=("$s")
						;;
					r|R)
						say "Enter new skill folder name:"
						printf '> '
						read -r newname
						sanitize_name "$newname" "skill name"
						local newdest="$target_root/.github/skills/$newname"
						if [[ -e "$newdest" ]]; then
							die "Destination already exists: .github/skills/$newname"
						fi
						if [[ "$DRY_RUN" -eq 1 ]]; then
							say "PLAN: add dir  $newdest (renamed from $s)"
						else
							cp -R "$srcd" "$newdest"
						fi
						renamed_skills+=("$s -> $newname")
						echo -e "$newname\t$s\t$source_sha" >>"$skills_map"
						;;
				*) die "Unknown action: $action";;
				esac
			else
				copy_dir_safely "$srcd" "$destd" "$DRY_RUN" || true
				installed_skills+=("$s")
				echo -e "$s\t$s\t$source_sha" >>"$skills_map"
			fi
		done <"$skills_tmp"
	fi

	# Manifest
	if [[ "$DRY_RUN" -eq 1 ]]; then
		say ""
		say "PLAN: write manifest $manifest"
	else
		write_manifest "$manifest" "$SOURCE_URL" "$SOURCE_REF" "$source_sha" "$agents_map" "$skills_map" "install"
	fi

	# Summary
	say ""
	say "=== Install summary ==="
	say "Installed agents: ${#installed_agents[@]}"
	for a in "${installed_agents[@]}"; do say "  - $a"; done
	if [[ ${#renamed_agents[@]} -gt 0 ]]; then
		say "Renamed agents:"
		for x in "${renamed_agents[@]}"; do say "  - $x"; done
	fi
	if [[ ${#skipped_agents[@]} -gt 0 ]]; then
		say "Skipped agents:"
		for x in "${skipped_agents[@]}"; do say "  - $x"; done
	fi

	say "Installed skills: ${#installed_skills[@]}"
	for s in "${installed_skills[@]}"; do say "  - $s"; done
	if [[ ${#renamed_skills[@]} -gt 0 ]]; then
		say "Renamed skills:"
		for x in "${renamed_skills[@]}"; do say "  - $x"; done
	fi
	if [[ ${#skipped_skills[@]} -gt 0 ]]; then
		say "Skipped skills:"
		for x in "${skipped_skills[@]}"; do say "  - $x"; done
	fi

	if [[ $overwrite_count -gt 0 ]]; then
		say "Overwrites performed: $overwrite_count"
	fi

	say "Manifest: .github/agent-installer/manifest.json"
}

main "$@"
