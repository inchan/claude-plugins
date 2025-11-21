#!/bin/bash
# Multi-Plugin UserPromptSubmit Hook
#
# Aggregates skill-rules.json from all plugins and suggests relevant skills
# based on user prompt keywords and intent patterns
#
# v2.0.0 - Multi-plugin architecture support

# Logging
LOG_FILE="/tmp/claude-skill-activation.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Multi-plugin skill-activation-hook executed" >> "$LOG_FILE"

# Find repository root (where .claude-plugin exists)
REPO_ROOT="${PWD}"
while [[ ! -d "${REPO_ROOT}/.claude-plugin" && "${REPO_ROOT}" != "/" ]]; do
    REPO_ROOT="$(dirname "${REPO_ROOT}")"
done

if [[ ! -d "${REPO_ROOT}/.claude-plugin" ]]; then
    echo "[WARN] Cannot find .claude-plugin directory, skill activation disabled" >&2
    exit 0
fi

echo "[DEBUG] Repository root: ${REPO_ROOT}" >> "$LOG_FILE"

# Get user prompt from stdin (if available)
USER_PROMPT=""
if [[ -p /dev/stdin ]]; then
    USER_PROMPT=$(cat)
fi

echo "[DEBUG] User prompt: ${USER_PROMPT}" >> "$LOG_FILE"

# Collect all skill-rules.json from plugins
SKILL_RULES_FILES=()
for plugin_dir in "${REPO_ROOT}/plugins/"*/; do
    if [[ -f "${plugin_dir}skills/skill-rules.json" ]]; then
        SKILL_RULES_FILES+=("${plugin_dir}skills/skill-rules.json")
        echo "[DEBUG] Found1234: ${plugin_dir}skills/skill-rules.json" >> "$LOG_FILE"
    fi
done

if [[ ${#SKILL_RULES_FILES[@]} -eq 0 ]]; then
    echo "[WARN] No skill-rules.json found in any plugin" >> "$LOG_FILE"
    exit 0
fi

echo "[DEBUG] Total skill-rules.json files: ${#SKILL_RULES_FILES[@]}" >> "$LOG_FILE"

# Aggregate all skills with priority
# Output format: priority|plugin|skill-name|keywords
AGGREGATED_SKILLS=$(mktemp)

for rules_file in "${SKILL_RULES_FILES[@]}"; do
    plugin_name=$(basename "$(dirname "$(dirname "$rules_file")")")

    # Extract skills using node (if available) or skip
    if command -v node &> /dev/null; then
        node -e "
        const fs = require('fs');
        const rules = JSON.parse(fs.readFileSync('${rules_file}', 'utf8'));
        if (!rules.skills) process.exit(0);

        Object.entries(rules.skills).forEach(([name, config]) => {
            const priority = config.priority || 'medium';
            const keywords = (config.promptTriggers?.keywords || []).join(',');
            console.log(\`\${priority}|${plugin_name}|\${name}|\${keywords}\`);
        });
        " >> "$AGGREGATED_SKILLS" 2>/dev/null
    fi
done

# Count total skills
TOTAL_SKILLS=$(wc -l < "$AGGREGATED_SKILLS" | xargs)
echo "[DEBUG] Total skills aggregated: ${TOTAL_SKILLS}" >> "$LOG_FILE"

# Match skills based on USER_PROMPT keywords
match_skills_by_keywords() {
    local prompt="$1"
    local skills_file="$2"

    # Convert prompt to lowercase for case-insensitive matching
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    # AWK script: Match keywords against prompt
    awk -F'|' -v prompt="$prompt_lower" '
    {
        priority = $1
        plugin = $2
        skill = $3
        keywords = tolower($4)

        # Split keywords by comma
        split(keywords, kw_array, ",")

        # Check each keyword
        for (i in kw_array) {
            # Trim whitespace
            gsub(/^[ \t]+|[ \t]+$/, "", kw_array[i])

            # If keyword found in prompt, print with match score
            if (index(prompt, kw_array[i]) > 0) {
                # Score = number of matching keywords
                print priority "|" plugin "|" skill "|" keywords
                next
            }
        }
    }' "$skills_file"
}

# Match skills by keywords first
MATCHED_SKILLS=$(mktemp)
if [[ -n "$USER_PROMPT" ]]; then
    match_skills_by_keywords "$USER_PROMPT" "$AGGREGATED_SKILLS" > "$MATCHED_SKILLS"

    # If no match, fallback to priority-only
    if [[ ! -s "$MATCHED_SKILLS" ]]; then
        echo "[DEBUG] No keyword match, using priority fallback" >> "$LOG_FILE"
        cp "$AGGREGATED_SKILLS" "$MATCHED_SKILLS"
    else
        MATCHED_COUNT=$(wc -l < "$MATCHED_SKILLS" | xargs)
        echo "[DEBUG] Keyword matched skills: ${MATCHED_COUNT}" >> "$LOG_FILE"
    fi
else
    # No prompt, use all skills
    echo "[DEBUG] No prompt provided, using all skills" >> "$LOG_FILE"
    cp "$AGGREGATED_SKILLS" "$MATCHED_SKILLS"
fi

# Build output message
OUTPUT_MSG="INSTRUCTION: MULTI-PLUGIN SKILL ACTIVATION\n\nAvailable Skills by Plugin:\n"

# Sort by plugin name first
SORTED_SKILLS=$(mktemp)
sort -t'|' -k2,2 -k3,3 "$MATCHED_SKILLS" > "$SORTED_SKILLS"

# Group by plugin and display
if [[ $TOTAL_SKILLS -gt 0 ]]; then
    OUTPUT_MSG="${OUTPUT_MSG}\n"
    current_plugin=""
    while IFS='|' read -r priority plugin skill keywords; do
        if [[ "$plugin" != "$current_plugin" ]]; then
            OUTPUT_MSG="${OUTPUT_MSG}\n📦 Plugin: $plugin\n"
            current_plugin="$plugin"
        fi
        OUTPUT_MSG="${OUTPUT_MSG}  - $skill [priority: $priority]\n"
    done < "$SORTED_SKILLS"
    OUTPUT_MSG="${OUTPUT_MSG}\n"
    rm -f "$SORTED_SKILLS"
fi

OUTPUT_MSG="${OUTPUT_MSG}\nStep 1 - EVALUATE:\nFor each skill above, state: [plugin:skill-name] - YES/NO - [reason]\n\n"
OUTPUT_MSG="${OUTPUT_MSG}Step 2 - ACTIVATE:\nUse Skill(\"plugin-name:skill-name\") for each YES skill\n"
OUTPUT_MSG="${OUTPUT_MSG}Example: Skill(\"workflow-automation:intelligent-task-router\")\n\n"
OUTPUT_MSG="${OUTPUT_MSG}Step 3 - IMPLEMENT:\nProceed with implementation after activation\n\n"
OUTPUT_MSG="${OUTPUT_MSG}CRITICAL: Skills are now namespaced by plugin (plugin-name:skill-name)"

# Output as JSON for Claude Code (stdout)
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "$(echo -e "$OUTPUT_MSG" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')"
  }
}
EOF

# Display progress and summary to user (stderr) - Clean Line Style
if [[ $TOTAL_SKILLS -gt 0 ]]; then
    PLUGIN_COUNT=$(sort -t'|' -k2,2 -u "$MATCHED_SKILLS" | wc -l | xargs)
    MATCHED_SKILLS_COUNT=$(wc -l < "$MATCHED_SKILLS" | xargs)

    # Clean line header
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "  스킬 활성화" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2

    # Stats line
    echo "📦 ${PLUGIN_COUNT}개 플러그인 · 🔧 ${MATCHED_SKILLS_COUNT}개 스킬 (전체: ${TOTAL_SKILLS})" >&2
    echo "" >&2

    # Suggested skills section
    echo "🎯 제안 스킬:" >&2

    # Priority mapping for sorting: critical=4, high=3, medium=2, low=1
    awk -F'|' '{
        priority=$1
        if (priority == "critical") p=4
        else if (priority == "high") p=3
        else if (priority == "medium") p=2
        else p=1
        print p"|"$0
    }' "$MATCHED_SKILLS" | sort -t'|' -k1,1nr | cut -d'|' -f2- | head -3 | while IFS='|' read -r priority plugin skill keywords; do
        # Format: plugin:skill
        echo "  • ${plugin}:${skill}" >&2
    done

    # Footer line
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
fi

# Cleanup
rm -f "$AGGREGATED_SKILLS" "$MATCHED_SKILLS"

exit 0

