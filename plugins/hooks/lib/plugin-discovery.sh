#!/bin/bash
# Plugin Discovery Library
# Discovers all installed Claude Code plugins and their skills
#
# v3.0.0 - Global plugin discovery support

# Discover all installed plugins from Claude Code
discover_installed_plugins() {
    local installed_plugins_file="$HOME/.claude/plugins/installed_plugins.json"
    local marketplaces_file="$HOME/.claude/plugins/known_marketplaces.json"

    local plugins=()

    # Check if files exist
    if [[ ! -f "$installed_plugins_file" ]]; then
        echo "[WARN] installed_plugins.json not found" >&2
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "[WARN] jq not found, cannot parse JSON" >&2
        return 1
    fi

    # Parse installed plugins
    local plugin_names=$(jq -r 'keys[]' "$installed_plugins_file" 2>/dev/null)

    for plugin_name in $plugin_names; do
        # Get marketplace for this plugin
        local marketplace=$(echo "$plugin_name" | rev | cut -d'@' -f1 | rev)
        local plugin_short_name=$(echo "$plugin_name" | rev | cut -d'@' -f2- | rev)

        # Get plugin path from marketplace
        local plugin_path=""
        if [[ -f "$marketplaces_file" ]]; then
            plugin_path=$(jq -r ".\"$marketplace\".installLocation // empty" "$marketplaces_file" 2>/dev/null)

            if [[ -n "$plugin_path" ]]; then
                # Check if it's a multi-plugin marketplace
                if [[ -d "$plugin_path/plugins/$plugin_short_name" ]]; then
                    plugin_path="$plugin_path/plugins/$plugin_short_name"
                elif [[ ! -f "$plugin_path/.claude-plugin/plugin.json" ]]; then
                    # Try finding in subdirectories
                    local found_path=$(find "$plugin_path" -maxdepth 2 -name ".claude-plugin" -type d 2>/dev/null | head -1)
                    if [[ -n "$found_path" ]]; then
                        plugin_path=$(dirname "$found_path")
                    fi
                fi
            fi
        fi

        if [[ -n "$plugin_path" ]] && [[ -d "$plugin_path" ]]; then
            plugins+=("$plugin_name|$plugin_path")
        fi
    done

    # Output discovered plugins
    printf '%s\n' "${plugins[@]}"
}

# Discover skills from a plugin directory
discover_plugin_skills() {
    local plugin_path="$1"
    local plugin_name="$2"

    if [[ ! -d "$plugin_path" ]]; then
        return 1
    fi

    local plugin_json="$plugin_path/.claude-plugin/plugin.json"
    if [[ ! -f "$plugin_json" ]]; then
        return 1
    fi

    # Get skill directories from plugin.json
    local skill_dirs=()
    if command -v jq &> /dev/null; then
        skill_dirs=($(jq -r '.skills[]? // empty' "$plugin_json" 2>/dev/null | sed "s|^\\./|$plugin_path/|"))
    else
        # Fallback: assume standard ./skills directory
        if [[ -d "$plugin_path/skills" ]]; then
            skill_dirs=("$plugin_path/skills")
        fi
    fi

    # Discover SKILL.md files
    for skill_dir in "${skill_dirs[@]}"; do
        if [[ ! -d "$skill_dir" ]]; then
            continue
        fi

        # Find all SKILL.md files
        find "$skill_dir" -name "SKILL.md" -type f 2>/dev/null | while read skill_file; do
            local skill_name=$(basename "$(dirname "$skill_file")")
            echo "$plugin_name|$skill_name|$skill_file"
        done
    done
}

# Discover skill-rules.json files
discover_skill_rules() {
    local plugin_path="$1"

    find "$plugin_path" -name "skill-rules.json" -type f 2>/dev/null
}

# Main discovery function
discover_all_skills() {
    local output_format="${1:-simple}"  # simple | json

    local all_skills=()

    # Discover from installed plugins
    while IFS='|' read -r plugin_name plugin_path; do
        # Discover skills from this plugin
        while IFS='|' read -r pname skill_name skill_file; do
            all_skills+=("$pname|$skill_name|$skill_file")
        done < <(discover_plugin_skills "$plugin_path" "$plugin_name")
    done < <(discover_installed_plugins)

    # Output results
    if [[ "$output_format" == "json" ]]; then
        echo "{"
        echo "  \"skills\": ["
        local first=true
        for skill_entry in "${all_skills[@]}"; do
            IFS='|' read -r plugin_name skill_name skill_file <<< "$skill_entry"

            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi

            echo "    {"
            echo "      \"plugin\": \"$plugin_name\","
            echo "      \"name\": \"$skill_name\","
            echo "      \"file\": \"$skill_file\""
            echo -n "    }"
        done
        echo ""
        echo "  ],"
        echo "  \"total\": ${#all_skills[@]}"
        echo "}"
    else
        # Simple format: plugin|skill|file
        printf '%s\n' "${all_skills[@]}"
    fi
}

# Export functions
export -f discover_installed_plugins
export -f discover_plugin_skills
export -f discover_skill_rules
export -f discover_all_skills

# Load guard flag (prevents double-loading, exported for subshell inheritance)
export _PLUGIN_DISCOVERY_LOADED=1
