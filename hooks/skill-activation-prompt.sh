#!/usr/bin/env bash

# Skill Activation Prompt Hook
# Analyzes user prompts and recommends relevant skills based on skill-rules.json

# Read input from stdin
INPUT=$(cat)

# Parse JSON input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
CWD=$(echo "$INPUT" | jq -r '.cwd')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode')
PROMPT=$(echo "$INPUT" | jq -r '.prompt')
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Check for empty prompt
if [ -z "$PROMPT" ] || [ "$PROMPT" = "null" ]; then
    exit 0
fi

# Load skill rules - check multiple locations
HOME_DIR="${HOME:-$USERPROFILE}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"

# Plugin paths (when running as installed plugin)
PLUGIN_RULES_PATH=""
if [ -n "$PLUGIN_ROOT" ]; then
    PLUGIN_RULES_PATH="$PLUGIN_ROOT/skills/skill-rules.json"
fi

# Legacy paths (for backward compatibility and local development)
GLOBAL_RULES_PATH="$HOME_DIR/.claude/skills/skill-rules.json"
PROJECT_RULES_PATH="$CWD/.claude/skills/skill-rules.json"

# Priority: project > plugin > global
RULES_PATH=""
if [ -f "$PROJECT_RULES_PATH" ]; then
    RULES_PATH="$PROJECT_RULES_PATH"
elif [ -n "$PLUGIN_RULES_PATH" ] && [ -f "$PLUGIN_RULES_PATH" ]; then
    RULES_PATH="$PLUGIN_RULES_PATH"
elif [ -f "$GLOBAL_RULES_PATH" ]; then
    RULES_PATH="$GLOBAL_RULES_PATH"
else
    # No rules found anywhere, exit silently
    exit 0
fi

# Load skill rules
RULES=$(cat "$RULES_PATH")

# Load enhancement rules (optional)
PLUGIN_ENHANCEMENT_PATH=""
if [ -n "$PLUGIN_ROOT" ]; then
    PLUGIN_ENHANCEMENT_PATH="$PLUGIN_ROOT/skills/prompt-enhancement-rules.json"
fi

PROJECT_ENHANCEMENT_PATH="$CWD/.claude/skills/prompt-enhancement-rules.json"
GLOBAL_ENHANCEMENT_PATH="$HOME_DIR/.claude/skills/prompt-enhancement-rules.json"

ENHANCEMENT_RULES_PATH=""
if [ -f "$PROJECT_ENHANCEMENT_PATH" ]; then
    ENHANCEMENT_RULES_PATH="$PROJECT_ENHANCEMENT_PATH"
elif [ -n "$PLUGIN_ENHANCEMENT_PATH" ] && [ -f "$PLUGIN_ENHANCEMENT_PATH" ]; then
    ENHANCEMENT_RULES_PATH="$PLUGIN_ENHANCEMENT_PATH"
elif [ -f "$GLOBAL_ENHANCEMENT_PATH" ]; then
    ENHANCEMENT_RULES_PATH="$GLOBAL_ENHANCEMENT_PATH"
fi

ENHANCEMENT_RULES=""
if [ -n "$ENHANCEMENT_RULES_PATH" ]; then
    ENHANCEMENT_RULES=$(cat "$ENHANCEMENT_RULES_PATH")
fi

# Arrays to store matches
declare -a CRITICAL_SKILLS=()
declare -a HIGH_SKILLS=()
declare -a MEDIUM_SKILLS=()
declare -a LOW_SKILLS=()
declare -a ENHANCEMENTS=()

# Function to check if prompt matches keywords
matches_keywords() {
    local keywords=$1
    local prompt_lower=$2

    echo "$keywords" | jq -r '.[]' 2>/dev/null | while read -r keyword; do
        if [ -z "$keyword" ]; then
            continue
        fi
        keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
        if echo "$prompt_lower" | grep -q "$keyword_lower"; then
            echo "match"
            return
        fi
    done
}

# Function to check if prompt matches intent patterns
matches_intent() {
    local patterns=$1
    local prompt=$2

    echo "$patterns" | jq -r '.[]' 2>/dev/null | while read -r pattern; do
        if [ -z "$pattern" ]; then
            continue
        fi
        if echo "$prompt" | grep -iE "$pattern" >/dev/null 2>&1; then
            echo "match"
            return
        fi
    done
}

# Check each skill for matches
SKILL_NAMES=$(echo "$RULES" | jq -r '.skills | keys[]')
for SKILL_NAME in $SKILL_NAMES; do
    CONFIG=$(echo "$RULES" | jq -r ".skills[\"$SKILL_NAME\"]")
    TRIGGERS=$(echo "$CONFIG" | jq -r '.promptTriggers // empty')

    if [ -z "$TRIGGERS" ] || [ "$TRIGGERS" = "null" ]; then
        continue
    fi

    MATCHED=false

    # Check keyword matching
    KEYWORDS=$(echo "$TRIGGERS" | jq -r '.keywords // empty')
    if [ -n "$KEYWORDS" ] && [ "$KEYWORDS" != "null" ]; then
        KEYWORD_MATCH=$(matches_keywords "$KEYWORDS" "$PROMPT_LOWER")
        if [ -n "$KEYWORD_MATCH" ]; then
            MATCHED=true
        fi
    fi

    # Check intent pattern matching
    if [ "$MATCHED" = "false" ]; then
        INTENT_PATTERNS=$(echo "$TRIGGERS" | jq -r '.intentPatterns // empty')
        if [ -n "$INTENT_PATTERNS" ] && [ "$INTENT_PATTERNS" != "null" ]; then
            INTENT_MATCH=$(matches_intent "$INTENT_PATTERNS" "$PROMPT")
            if [ -n "$INTENT_MATCH" ]; then
                MATCHED=true
            fi
        fi
    fi

    # Add to appropriate priority list
    if [ "$MATCHED" = "true" ]; then
        PRIORITY=$(echo "$CONFIG" | jq -r '.priority')
        case $PRIORITY in
            critical)
                CRITICAL_SKILLS+=("$SKILL_NAME")
                ;;
            high)
                HIGH_SKILLS+=("$SKILL_NAME")
                ;;
            medium)
                MEDIUM_SKILLS+=("$SKILL_NAME")
                ;;
            low)
                LOW_SKILLS+=("$SKILL_NAME")
                ;;
        esac
    fi
done

# Check enhancement rules
if [ -n "$ENHANCEMENT_RULES" ]; then
    RULE_NAMES=$(echo "$ENHANCEMENT_RULES" | jq -r '.enhancementRules | keys[]' 2>/dev/null)
    for RULE_NAME in $RULE_NAMES; do
        RULE=$(echo "$ENHANCEMENT_RULES" | jq -r ".enhancementRules[\"$RULE_NAME\"]")
        PATTERNS=$(echo "$RULE" | jq -r '.patterns[]' 2>/dev/null)

        for PATTERN in $PATTERNS; do
            pattern_lower=$(echo "$PATTERN" | tr '[:upper:]' '[:lower:]')
            if echo "$prompt_lower" | grep -q "$pattern_lower"; then
                SUGGESTIONS=$(echo "$RULE" | jq -r '.suggestions[]' 2>/dev/null)
                for SUGGESTION in $SUGGESTIONS; do
                    ENHANCEMENTS+=("$SUGGESTION")
                done
                break
            fi
        done
    done
fi

# Function to analyze complexity for default workflow recommendation
analyze_complexity() {
    local prompt=$1
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    local length=${#prompt}

    # Keywords for parallel execution
    if echo "$prompt_lower" | grep -E '(여러|동시|병렬|parallel|concurrent|각각|모두|전부)' >/dev/null; then
        echo "parallel-task-executor|독립 작업 병렬 처리에 최적"
        return
    fi

    # Keywords for complex/orchestration
    if echo "$prompt_lower" | grep -E '(복잡|전체|통합|대규모|complex|full|entire|시스템|아키텍처)' >/dev/null; then
        echo "dynamic-task-orchestrator|복잡한 프로젝트 조율에 적합"
        return
    fi

    # Keywords for simple sequential
    if echo "$prompt_lower" | grep -E '(간단|단순|하나|simple|single|quick|빠르게)' >/dev/null || [ $length -lt 50 ]; then
        echo "sequential-task-processor|간단한 순차 작업에 적합"
        return
    fi

    # Check length for complex
    if [ $length -gt 200 ]; then
        echo "dynamic-task-orchestrator|복잡한 프로젝트 조율에 적합"
        return
    fi

    # Default
    echo "agent-workflow-manager|자동 워크플로우 분석 및 실행"
}

# Generate output if matches found
TOTAL_MATCHES=$((${#CRITICAL_SKILLS[@]} + ${#HIGH_SKILLS[@]} + ${#MEDIUM_SKILLS[@]} + ${#LOW_SKILLS[@]} + ${#ENHANCEMENTS[@]}))

if [ $TOTAL_MATCHES -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 SKILL ACTIVATION CHECK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Critical skills
    if [ ${#CRITICAL_SKILLS[@]} -gt 0 ]; then
        echo "⚠️ CRITICAL SKILLS (REQUIRED):"
        for skill in "${CRITICAL_SKILLS[@]}"; do
            echo "  → $skill"
        done
        echo ""
    fi

    # High priority skills
    if [ ${#HIGH_SKILLS[@]} -gt 0 ]; then
        echo "📚 RECOMMENDED SKILLS:"
        for skill in "${HIGH_SKILLS[@]}"; do
            echo "  → $skill"
        done
        echo ""
    fi

    # Medium priority skills
    if [ ${#MEDIUM_SKILLS[@]} -gt 0 ]; then
        echo "💡 SUGGESTED SKILLS:"
        for skill in "${MEDIUM_SKILLS[@]}"; do
            echo "  → $skill"
        done
        echo ""
    fi

    # Low priority skills
    if [ ${#LOW_SKILLS[@]} -gt 0 ]; then
        echo "📌 OPTIONAL SKILLS:"
        for skill in "${LOW_SKILLS[@]}"; do
            echo "  → $skill"
        done
        echo ""
    fi

    # Context enhancements
    if [ ${#ENHANCEMENTS[@]} -gt 0 ]; then
        echo "📝 CONTEXT ENHANCEMENT:"
        # Limit to top 5 suggestions
        count=0
        for enhancement in "${ENHANCEMENTS[@]}"; do
            if [ $count -ge 5 ]; then
                break
            fi
            echo "  → $enhancement"
            count=$((count + 1))
        done
        echo ""
    fi

    echo "ACTION: Use Skill tool BEFORE responding"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
elif [ ${#PROMPT} -gt 20 ]; then
    # No matches found - recommend default workflow based on complexity
    RECOMMENDATION=$(analyze_complexity "$PROMPT")
    SKILL=$(echo "$RECOMMENDATION" | cut -d'|' -f1)
    REASON=$(echo "$RECOMMENDATION" | cut -d'|' -f2)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 SKILL ACTIVATION CHECK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 DEFAULT WORKFLOW RECOMMENDATION:"
    echo "  → $SKILL"
    echo "    ($REASON)"
    echo ""
    echo "TIP: /auto-workflow 커맨드로 자동 분석 실행 가능"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit 0
