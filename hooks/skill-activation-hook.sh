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
        echo "[DEBUG] Found: ${plugin_dir}skills/skill-rules.json" >> "$LOG_FILE"
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
TOTAL_SKILLS=$(wc -l < "$AGGREGATED_SKILLS")
echo "[DEBUG] Total skills aggregated: ${TOTAL_SKILLS}" >> "$LOG_FILE"

# Output instruction to Claude
cat <<'EOF'
INSTRUCTION: MULTI-PLUGIN SKILL ACTIVATION

Available Skills by Plugin:
EOF

# Sort by plugin name first
SORTED_SKILLS=$(mktemp)
sort -t'|' -k2,2 -k3,3 "$AGGREGATED_SKILLS" > "$SORTED_SKILLS"

# Group by plugin and display
if [[ $TOTAL_SKILLS -gt 0 ]]; then
    echo ""
    current_plugin=""
    while IFS='|' read -r priority plugin skill keywords; do
        if [[ "$plugin" != "$current_plugin" ]]; then
            echo ""
            echo "📦 Plugin: $plugin"
            current_plugin="$plugin"
        fi
        echo "  - $skill [priority: $priority]"
    done < "$SORTED_SKILLS"
    echo ""
    rm -f "$SORTED_SKILLS"
fi

cat <<'EOF'

Step 1 - EVALUATE:
For each skill above, state: [plugin:skill-name] - YES/NO - [reason]

Step 2 - ACTIVATE:
Use Skill("plugin-name:skill-name") for each YES skill
Example: Skill("workflow-automation:intelligent-task-router")

Step 3 - IMPLEMENT:
Proceed with implementation after activation

CRITICAL: Skills are now namespaced by plugin (plugin-name:skill-name)
EOF

# Cleanup
rm -f "$AGGREGATED_SKILLS"

exit 0

