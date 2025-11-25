#!/bin/bash
# Metadata Parser Library
# Parses YAML frontmatter and skill-rules.json
#
# v3.0.0 - Multi-format metadata parsing

# Parse YAML frontmatter from SKILL.md
parse_yaml_frontmatter() {
    local skill_file="$1"

    if [[ ! -f "$skill_file" ]]; then
        return 1
    fi

    # Extract YAML frontmatter between --- delimiters
    local yaml_content=$(awk '/^---$/{flag=!flag; next} flag' "$skill_file")

    if [[ -z "$yaml_content" ]]; then
        return 1
    fi

    # Parse name and description
    local name=$(echo "$yaml_content" | grep '^name:' | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    local description=$(echo "$yaml_content" | grep '^description:' | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # Output as pipe-separated
    echo "$name|$description"
}

# Parse skill-rules.json for a specific skill
parse_skill_rules() {
    local rules_file="$1"
    local skill_name="$2"

    if [[ ! -f "$rules_file" ]]; then
        return 1
    fi

    if ! command -v node &> /dev/null; then
        return 1
    fi

    # Use Node.js to parse JSON
    node -e "
    const fs = require('fs');
    const rules = JSON.parse(fs.readFileSync('${rules_file}', 'utf8'));
    const skill = rules.skills?.['${skill_name}'];

    if (!skill) process.exit(1);

    const priority = skill.priority || 'medium';
    const keywords = (skill.promptTriggers?.keywords || []).join(',');
    const patterns = (skill.promptTriggers?.intentPatterns || []).join('|||');

    console.log(\`\${priority}|\${keywords}|\${patterns}\`);
    " 2>/dev/null
}

# Aggregate metadata from both YAML and skill-rules.json
aggregate_skill_metadata() {
    local skill_file="$1"
    local plugin_name="$2"
    local skill_name="$3"

    # Parse YAML frontmatter
    local yaml_data=$(parse_yaml_frontmatter "$skill_file")
    local yaml_name=""
    local yaml_desc=""

    if [[ -n "$yaml_data" ]]; then
        IFS='|' read -r yaml_name yaml_desc <<< "$yaml_data"
    fi

    # Use yaml_name if available, fallback to skill_name
    skill_name="${yaml_name:-$skill_name}"

    # Try to find skill-rules.json
    local plugin_dir=$(dirname "$(dirname "$skill_file")")
    local rules_file="$plugin_dir/skill-rules.json"

    local priority="medium"
    local keywords=""
    local patterns=""

    if [[ -f "$rules_file" ]]; then
        local rules_data=$(parse_skill_rules "$rules_file" "$skill_name")
        if [[ -n "$rules_data" ]]; then
            IFS='|' read -r priority keywords patterns <<< "$rules_data"
        fi
    fi

    # Output aggregated metadata
    # Format: plugin|skill|description|priority|keywords|patterns|file
    echo "$plugin_name|$skill_name|$yaml_desc|$priority|$keywords|$patterns|$skill_file"
}

# Parse all skills and aggregate metadata
parse_all_skills_metadata() {
    local output_format="${1:-simple}"

    if [[ "$output_format" == "json" ]]; then
        echo "{"
        echo "  \"skills\": ["
    fi

    local first=true

    # Read from stdin (expected format: plugin|skill|file)
    while IFS='|' read -r plugin_name skill_name skill_file; do
        local metadata=$(aggregate_skill_metadata "$skill_file" "$plugin_name" "$skill_name")

        if [[ -z "$metadata" ]]; then
            continue
        fi

        if [[ "$output_format" == "json" ]]; then
            IFS='|' read -r p s desc prio kw pat f <<< "$metadata"

            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi

            # Escape quotes for JSON
            desc=$(echo "$desc" | sed 's/"/\\"/g')
            kw=$(echo "$kw" | sed 's/"/\\"/g')
            pat=$(echo "$pat" | sed 's/"/\\"/g')

            echo "    {"
            echo "      \"plugin\": \"$p\","
            echo "      \"skill\": \"$s\","
            echo "      \"description\": \"$desc\","
            echo "      \"priority\": \"$prio\","
            echo "      \"keywords\": \"$kw\","
            echo "      \"patterns\": \"$pat\","
            echo "      \"file\": \"$f\""
            echo -n "    }"
        else
            echo "$metadata"
        fi
    done

    if [[ "$output_format" == "json" ]]; then
        echo ""
        echo "  ]"
        echo "}"
    fi
}

# Export functions
export -f parse_yaml_frontmatter
export -f parse_skill_rules
export -f aggregate_skill_metadata
export -f parse_all_skills_metadata

# Load guard flag (prevents double-loading, exported for subshell inheritance)
export _METADATA_PARSER_LOADED=1
