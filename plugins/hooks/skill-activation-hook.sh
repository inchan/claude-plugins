#!/bin/bash
# Multi-Tier Skill Activation Hook
#
# Integrates 3-tier matching system:
# - Tier 1 (Bash): Keyword matching with synonyms (<50ms)
# - Tier 2 (Node.js): TF-IDF scoring (<150ms)
# - Tier 3 (Python): Semantic embedding matching (<400ms)
#
# v3.0.0 - Multi-tier intelligent matching with progressive execution

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

LOG_FILE="/tmp/claude-skill-activation.log"
DEBUG_INPUT_FILE="/tmp/claude-hook-input.json"
DEBUG_OUTPUT_FILE="/tmp/claude-hook-output.json"

# Performance targets (milliseconds)
TIER1_TARGET_MS=50
TIER2_TARGET_MS=150
TIER3_TARGET_MS=400
OVERALL_TIMEOUT_MS=500

# Matching thresholds
MIN_HIGH_CONFIDENCE_MATCHES=5
TIER2_CANDIDATE_LIMIT=20
TIER3_CANDIDATE_LIMIT=10
MAX_OUTPUT_SKILLS=5

# Cache settings
CACHE_MAX_AGE=3600  # 1 hour

# ============================================================================
# Initialization
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
MATCHERS_DIR="$SCRIPT_DIR/matchers"
CONFIG_DIR="$SCRIPT_DIR/config"

# Source library functions
source "$LIB_DIR/plugin-discovery.sh" 2>/dev/null || {
    echo "[ERROR] Failed to load plugin-discovery.sh" >&2
    exit 1
}
source "$LIB_DIR/metadata-parser.sh" 2>/dev/null || {
    echo "[ERROR] Failed to load metadata-parser.sh" >&2
    exit 1
}
source "$LIB_DIR/cache-manager.sh" 2>/dev/null || {
    echo "[ERROR] Failed to load cache-manager.sh" >&2
    exit 1
}

# Load synonyms dictionary
SYNONYMS_FILE="$CONFIG_DIR/synonyms.json"

# ============================================================================
# Logging
# ============================================================================

log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >> "$LOG_FILE"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"
}

log_perf() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PERF] $*" >> "$LOG_FILE"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Get current timestamp in milliseconds
get_ms_timestamp() {
    echo $(($(date +%s%N) / 1000000))
}

# Remove Korean particles (조사) from words for better matching
# e.g., "버그를" → "버그", "에러가" → "에러"
strip_korean_particles() {
    local text="$1"

    # Common Korean particles (ordered by length for correct matching)
    # 3-char: 에서, 으로, 처럼, 까지, 부터, 에게, 한테, 보다
    # 2-char: 을, 를, 이, 가, 은, 는, 에, 로, 와, 과, 의, 도, 만, 서
    # Pattern removes particles at word boundaries
    echo "$text" | sed -E '
        s/에서( |,|$)/\1/g
        s/으로( |,|$)/\1/g
        s/처럼( |,|$)/\1/g
        s/까지( |,|$)/\1/g
        s/부터( |,|$)/\1/g
        s/에게( |,|$)/\1/g
        s/한테( |,|$)/\1/g
        s/보다( |,|$)/\1/g
        s/을( |,|$)/\1/g
        s/를( |,|$)/\1/g
        s/이( |,|$)/\1/g
        s/가( |,|$)/\1/g
        s/은( |,|$)/\1/g
        s/는( |,|$)/\1/g
        s/에( |,|$)/\1/g
        s/로( |,|$)/\1/g
        s/와( |,|$)/\1/g
        s/과( |,|$)/\1/g
        s/의( |,|$)/\1/g
        s/도( |,|$)/\1/g
        s/만( |,|$)/\1/g
    '
}

# Load and expand keywords with synonyms (optimized: single jq call)
expand_keywords_with_synonyms() {
    local keywords="$1"

    if [[ ! -f "$SYNONYMS_FILE" ]] || ! command -v jq &> /dev/null; then
        echo "$keywords"
        return
    fi

    # Convert comma-separated keywords to JSON array and expand all at once
    # This is much faster than calling jq for each keyword
    local keywords_json=$(echo "$keywords" | tr ',' '\n' | jq -R -s 'split("\n") | map(select(length > 0) | gsub("^\\s+|\\s+$"; ""))')

    local expanded=$(jq -r --argjson words "$keywords_json" '
        # Start with original words
        ($words | join(",")) as $original |

        # Find all synonyms for each word
        [.synonyms | to_entries[] |
            select(
                (.key as $k | $words | any(. == $k)) or
                (.value as $v | $words | any(. as $w | $v | index($w)))
            ) |
            .value[]
        ] |

        # Combine original + synonyms, deduplicate
        ($original + "," + join(",")) | split(",") | unique | join(",")
    ' "$SYNONYMS_FILE" 2>/dev/null)

    if [[ -n "$expanded" ]]; then
        echo "$expanded"
    else
        echo "$keywords"
    fi
}

# ============================================================================
# Skill Data Aggregation (with Cache)
# ============================================================================

aggregate_all_skills() {
    local output_file="$1"
    local repo_root="$2"

    log_info "=== Aggregating Skills ==="
    local start_ms=$(get_ms_timestamp)

    # Check cache first
    if update_cache_if_needed false "$CACHE_MAX_AGE"; then
        log_info "Using cached skill metadata"

        # Extract from cache to aggregated format
        if command -v jq &> /dev/null; then
            load_from_cache | jq -r '
                .skills[] |
                "\(.priority)|\(.plugin)|\(.skill)|\(.keywords)"
            ' > "$output_file" 2>/dev/null || touch "$output_file"
        fi

        local count=$(wc -l < "$output_file" | xargs)
        if [[ $count -gt 0 ]]; then
            local end_ms=$(get_ms_timestamp)
            log_perf "Loaded ${count} skills from cache in $((end_ms - start_ms))ms"
            return 0
        fi
    fi

    log_info "Cache miss, aggregating from skill-rules.json files"

    # Find all skill-rules.json files
    local skill_rules_files=()
    for plugin_dir in "${repo_root}/plugins/"*/; do
        if [[ -f "${plugin_dir}skills/skill-rules.json" ]]; then
            skill_rules_files+=("${plugin_dir}skills/skill-rules.json")
            log_debug "Found skill-rules.json: ${plugin_dir}skills/skill-rules.json"
        fi
    done

    if [[ ${#skill_rules_files[@]} -eq 0 ]]; then
        log_warn "No skill-rules.json found"
        return 1
    fi

    # Aggregate all skills
    for rules_file in "${skill_rules_files[@]}"; do
        local plugin_name=$(basename "$(dirname "$(dirname "$rules_file")")")

        if command -v node &> /dev/null; then
            node -e "
            const fs = require('fs');
            try {
                const rules = JSON.parse(fs.readFileSync('${rules_file}', 'utf8'));
                if (!rules.skills) process.exit(0);

                Object.entries(rules.skills).forEach(([name, config]) => {
                    const priority = config.priority || 'medium';
                    const keywords = (config.promptTriggers?.keywords || []).join(',');
                    console.log(\`\${priority}|${plugin_name}|\${name}|\${keywords}\`);
                });
            } catch (err) {
                console.error('Error parsing ${rules_file}:', err.message);
            }
            " >> "$output_file" 2>/dev/null
        fi
    done

    local count=$(wc -l < "$output_file" | xargs)
    local end_ms=$(get_ms_timestamp)
    log_perf "Aggregated ${count} skills in $((end_ms - start_ms))ms"

    # Update cache for next time
    if [[ $count -gt 0 ]]; then
        # Build JSON format for cache (use bash date instead of AWK systime for macOS compatibility)
        local current_ts=$(date +%s)
        local cache_json=$(awk -F'|' -v ts="$current_ts" 'BEGIN { print "{\"skills\":[" }
        {
            if (NR > 1) printf ","
            printf "{\"priority\":\"%s\",\"plugin\":\"%s\",\"skill\":\"%s\",\"keywords\":\"%s\"}", $1, $2, $3, $4
        }
        END { print "],\"timestamp\":" ts "}" }' "$output_file")

        save_to_cache "$cache_json"
        log_info "Cache updated"
    fi

    return 0
}

# ============================================================================
# Tier 1: Keyword Matching (Bash)
# ============================================================================

tier1_keyword_match() {
    local prompt="$1"
    local skills_file="$2"
    local output_file="$3"

    log_info "=== TIER 1: Keyword Matching ==="
    local start_ms=$(get_ms_timestamp)

    # Convert prompt to lowercase
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    # Strip Korean particles for better matching (e.g., "버그를" → "버그")
    local prompt_stripped=$(strip_korean_particles "$prompt_lower")
    log_debug "After stripping particles: $prompt_stripped"

    # Expand prompt words with synonyms for better matching
    # Convert space-separated words to comma-separated for expand_keywords_with_synonyms()
    local prompt_words=$(echo "$prompt_stripped" | tr ' ' ',')
    local expanded_words=$(expand_keywords_with_synonyms "$prompt_words")
    # Convert back to space-separated for AWK matching
    local prompt_expanded=$(echo "$expanded_words" | tr ',' ' ')
    log_debug "Expanded prompt: $prompt_expanded"

    # AWK script for keyword matching
    # Use expanded prompt for synonym-enhanced matching
    awk -F'|' -v prompt="$prompt_expanded" '
    {
        priority = $1
        plugin = $2
        skill = $3
        keywords = tolower($4)

        # Split keywords by comma
        split(keywords, kw_array, ",")
        # Split prompt by space for bidirectional matching
        split(prompt, prompt_words, " ")

        match_count = 0
        matched_keywords = ""

        # Check each keyword
        for (i in kw_array) {
            gsub(/^[ \t]+|[ \t]+$/, "", kw_array[i])
            found = 0

            # Method 1: keyword in prompt (for single-word keywords)
            if (index(prompt, kw_array[i]) > 0) {
                found = 1
            }

            # Method 2: any word of multi-word keyword in prompt
            if (!found && index(kw_array[i], " ") > 0) {
                split(kw_array[i], kw_words, " ")
                for (w in kw_words) {
                    if (index(prompt, kw_words[w]) > 0) {
                        found = 1
                        break
                    }
                }
            }

            if (found) {
                match_count++
                if (matched_keywords != "") matched_keywords = matched_keywords ","
                matched_keywords = matched_keywords kw_array[i]
            }
        }

        # If matches found, output with confidence score
        if (match_count > 0) {
            # Score = number of matches * 0.2 (capped at 1.0)
            confidence = match_count * 0.2
            if (confidence > 1.0) confidence = 1.0

            print priority "|" plugin "|" skill "|" keywords "|" confidence "|keyword|" matched_keywords
        }
    }' "$skills_file" > "$output_file"

    local end_ms=$(get_ms_timestamp)
    local elapsed_ms=$((end_ms - start_ms))

    local match_count=$(wc -l < "$output_file" | xargs)
    log_perf "Tier 1 completed: ${match_count} matches in ${elapsed_ms}ms (target: ${TIER1_TARGET_MS}ms)"

    return 0
}

# ============================================================================
# Tier 2: TF-IDF Matching (Node.js)
# ============================================================================

tier2_tfidf_match() {
    local prompt="$1"
    local candidates_file="$2"
    local output_file="$3"

    log_info "=== TIER 2: TF-IDF Matching ==="
    local start_ms=$(get_ms_timestamp)

    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        log_warn "Node.js not found, skipping Tier 2"
        return 1
    fi

    # Check if natural package is available
    if ! node -e "require('natural')" 2>/dev/null; then
        log_warn "Node.js 'natural' package not found, skipping Tier 2"
        return 1
    fi

    # Prepare JSON input
    local candidates_json=""
    local first=true
    while IFS='|' read -r priority plugin skill keywords confidence method matched; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            candidates_json="${candidates_json},"
        fi
        candidates_json="${candidates_json}{\"plugin\":\"$plugin\",\"skill\":\"$skill\",\"keywords\":\"$keywords\",\"priority\":\"$priority\",\"description\":\"$keywords\"}"
    done < "$candidates_file"

    local input_json="{\"prompt\":\"$prompt\",\"candidates\":[$candidates_json]}"

    # Call TF-IDF matcher
    local result=$(echo "$input_json" | timeout 2s node "$MATCHERS_DIR/tfidf-matcher.js" 2>/dev/null || echo '{"matches":[]}')

    # Parse results
    echo "$result" | jq -r '.matches[]? | "\(.priority)|\(.plugin)|\(.skill)|\(.keywords // "")|\(.tfidfScore)|tfidf|tfidf"' > "$output_file" 2>/dev/null || touch "$output_file"

    local end_ms=$(get_ms_timestamp)
    local elapsed_ms=$((end_ms - start_ms))

    local match_count=$(wc -l < "$output_file" | xargs)
    log_perf "Tier 2 completed: ${match_count} matches in ${elapsed_ms}ms (target: ${TIER2_TARGET_MS}ms)"

    [[ $match_count -gt 0 ]]
}

# ============================================================================
# Tier 3: Semantic Matching (Python)
# ============================================================================

tier3_semantic_match() {
    local prompt="$1"
    local candidates_file="$2"
    local output_file="$3"

    log_info "=== TIER 3: Semantic Matching ==="
    local start_ms=$(get_ms_timestamp)

    # Check if Python is available
    if ! command -v python3 &> /dev/null; then
        log_warn "Python3 not found, skipping Tier 3"
        return 1
    fi

    # Check if sentence-transformers is available
    if ! python3 -c "import sentence_transformers" 2>/dev/null; then
        log_warn "Python 'sentence-transformers' not found, skipping Tier 3"
        return 1
    fi

    # Prepare JSON input
    local candidates_json=""
    local first=true
    while IFS='|' read -r priority plugin skill keywords score method matched; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            candidates_json="${candidates_json},"
        fi
        candidates_json="${candidates_json}{\"plugin\":\"$plugin\",\"skill\":\"$skill\",\"keywords\":\"$keywords\",\"priority\":\"$priority\",\"description\":\"$keywords\"}"
    done < "$candidates_file"

    local input_json="{\"prompt\":\"$prompt\",\"candidates\":[$candidates_json]}"

    # Call semantic matcher
    local result=$(echo "$input_json" | timeout 3s python3 "$MATCHERS_DIR/semantic-matcher.py" 2>/dev/null || echo '{"matches":[]}')

    # Parse results
    echo "$result" | jq -r '.matches[]? | "\(.priority)|\(.plugin)|\(.skill)|\(.keywords // "")|\(.semanticScore)|semantic|semantic"' > "$output_file" 2>/dev/null || touch "$output_file"

    local end_ms=$(get_ms_timestamp)
    local elapsed_ms=$((end_ms - start_ms))

    local match_count=$(wc -l < "$output_file" | xargs)
    log_perf "Tier 3 completed: ${match_count} matches in ${elapsed_ms}ms (target: ${TIER3_TARGET_MS}ms)"

    [[ $match_count -gt 0 ]]
}

# ============================================================================
# Main Matching Pipeline
# ============================================================================

execute_matching_pipeline() {
    local user_prompt="$1"
    local aggregated_skills="$2"

    local overall_start_ms=$(get_ms_timestamp)

    # Temporary files
    local tier1_output=$(mktemp)
    local tier2_output=$(mktemp)
    local tier3_output=$(mktemp)
    local final_output=$(mktemp)

    trap "rm -f '$tier1_output' '$tier2_output' '$tier3_output' '$final_output'" EXIT

    # TIER 1: Keyword matching (always execute)
    tier1_keyword_match "$user_prompt" "$aggregated_skills" "$tier1_output"
    local tier1_count=$(wc -l < "$tier1_output" | xargs)

    # Check high-confidence matches
    local high_confidence_count=$(awk -F'|' '$5 >= 0.6 {count++} END {print count+0}' "$tier1_output")

    log_info "Tier 1 results: ${tier1_count} matches, ${high_confidence_count} high-confidence"

    # Early termination if sufficient high-confidence matches
    if [[ $high_confidence_count -ge $MIN_HIGH_CONFIDENCE_MATCHES ]]; then
        log_info "Sufficient high-confidence matches, skipping Tier 2/3"
        cp "$tier1_output" "$final_output"
    elif [[ $tier1_count -eq 0 ]]; then
        log_warn "No matches in Tier 1"
        touch "$final_output"
    else
        # TIER 2: TF-IDF matching (top N candidates)
        head -n "$TIER2_CANDIDATE_LIMIT" "$tier1_output" > "${tier1_output}.top"

        if tier2_tfidf_match "$user_prompt" "${tier1_output}.top" "$tier2_output"; then
            local tier2_count=$(wc -l < "$tier2_output" | xargs)
            log_info "Tier 2 results: ${tier2_count} matches"

            # TIER 3: Semantic matching (if Tier 2 has enough results)
            if [[ $tier2_count -ge 3 ]]; then
                head -n "$TIER3_CANDIDATE_LIMIT" "$tier2_output" > "${tier2_output}.top"

                if tier3_semantic_match "$user_prompt" "${tier2_output}.top" "$tier3_output"; then
                    local tier3_count=$(wc -l < "$tier3_output" | xargs)
                    log_info "Tier 3 results: ${tier3_count} matches"

                    # Merge results (priority: Tier 3 > Tier 2 > Tier 1)
                    cat "$tier3_output" "$tier2_output" "$tier1_output" | \
                        sort -t'|' -k5,5rn | \
                        awk -F'|' '!seen[$2"|"$3]++' > "$final_output"
                else
                    # Tier 3 failed, use Tier 2 + Tier 1
                    cat "$tier2_output" "$tier1_output" | \
                        sort -t'|' -k5,5rn | \
                        awk -F'|' '!seen[$2"|"$3]++' > "$final_output"
                fi
                rm -f "${tier2_output}.top"
            else
                # Not enough Tier 2 results, use Tier 2 + Tier 1
                cat "$tier2_output" "$tier1_output" | \
                    sort -t'|' -k5,5rn | \
                    awk -F'|' '!seen[$2"|"$3]++' > "$final_output"
            fi
            rm -f "${tier1_output}.top"
        else
            # Tier 2 failed, use Tier 1 only
            cp "$tier1_output" "$final_output"
        fi
    fi

    # Calculate total time
    local overall_end_ms=$(get_ms_timestamp)
    local overall_time=$((overall_end_ms - overall_start_ms))

    log_perf "Overall pipeline completed in ${overall_time}ms (target: ${OVERALL_TIMEOUT_MS}ms)"

    # Return final output file path
    cat "$final_output"
}

# ============================================================================
# Output Formatting
# ============================================================================

build_output_json() {
    local matched_file="$1"
    local total_skills="$2"

    # Build user message
    local user_msg=""
    local matched_count=$(wc -l < "$matched_file" | xargs)

    if [[ $matched_count -eq 0 ]]; then
        user_msg="스킬 매칭 결과가 없습니다."
    else
        local plugin_count=$(cut -d'|' -f2 "$matched_file" | sort -u | wc -l | xargs)

        user_msg="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        user_msg="${user_msg}  🎯 스킬 활성화 (Multi-Tier Matching)\n"
        user_msg="${user_msg}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        user_msg="${user_msg}📦 ${plugin_count}개 플러그인 · 🔧 ${matched_count}개 스킬 (전체: ${total_skills})\n\n"
        user_msg="${user_msg}추천 스킬 (상위 ${MAX_OUTPUT_SKILLS}개):\n"

        # Get top N skills (use process substitution to avoid subshell variable scope issue)
        while IFS='|' read -r priority plugin skill keywords confidence method matched; do
            local conf_pct=$(awk -v c="$confidence" 'BEGIN {printf "%.0f", c * 100}')
            local method_icon=""
            case "$method" in
                semantic) method_icon="🧠" ;;
                tfidf) method_icon="📊" ;;
                keyword) method_icon="🔑" ;;
                *) method_icon="❓" ;;
            esac

            # Truncate matched keywords if too long
            if [[ -n "$matched" && ${#matched} -gt 30 ]]; then
                matched="${matched:0:27}..."
            fi

            if [[ -n "$matched" ]]; then
                user_msg="${user_msg}  ${method_icon} ${plugin}:${skill} (${conf_pct}%) - matched: ${matched}\n"
            else
                user_msg="${user_msg}  ${method_icon} ${plugin}:${skill} (${conf_pct}%)\n"
            fi
        done < <(head -"$MAX_OUTPUT_SKILLS" "$matched_file")

        user_msg="${user_msg}\n💡 Skill(\"plugin:skill-name\")으로 수동 활성화 가능\n"
        user_msg="${user_msg}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi

    # Build system message (detailed for Claude)
    local sys_msg="MULTI-TIER SKILL ACTIVATION\n\n"
    sys_msg="${sys_msg}Matching Methods:\n"
    sys_msg="${sys_msg}  🔑 Tier 1: Keyword matching with synonym expansion\n"
    sys_msg="${sys_msg}  📊 Tier 2: TF-IDF semantic relevance scoring\n"
    sys_msg="${sys_msg}  🧠 Tier 3: Neural embedding-based semantic matching\n\n"

    if [[ $matched_count -gt 0 ]]; then
        sys_msg="${sys_msg}Top Matched Skills:\n"
        while IFS='|' read -r priority plugin skill keywords confidence method matched; do
            sys_msg="${sys_msg}  - ${plugin}:${skill} [${method}, score: ${confidence}, matched: ${matched}]\n"
        done < <(head -10 "$matched_file")
    else
        sys_msg="${sys_msg}No skills matched the input prompt.\n"
    fi

    # Build JSON output (properly escaped)
    cat << EOF
{
  "message": "$(echo -e "$user_msg" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')",
  "systemMessage": "$(echo -e "$sys_msg" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//')"
}
EOF
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    log_info "========================================="
    log_info "Multi-Tier Skill Activation Hook Started"
    log_info "========================================="

    # Find repository root
    REPO_ROOT="${PWD}"
    while [[ ! -d "${REPO_ROOT}/.claude-plugin" && "${REPO_ROOT}" != "/" ]]; do
        REPO_ROOT="$(dirname "${REPO_ROOT}")"
    done

    if [[ ! -d "${REPO_ROOT}/.claude-plugin" ]]; then
        log_warn "Cannot find .claude-plugin directory, skill activation disabled"
        echo '{"message":"Skill activation disabled (no .claude-plugin directory)"}'
        exit 0
    fi

    log_debug "Repository root: ${REPO_ROOT}"

    # Parse user prompt from stdin
    USER_PROMPT=""
    if [[ -p /dev/stdin ]]; then
        STDIN_INPUT=$(cat)
        echo "$STDIN_INPUT" > "$DEBUG_INPUT_FILE"
        log_debug "STDIN received, saved to $DEBUG_INPUT_FILE"

        # Try parsing as JSON
        if command -v jq &> /dev/null && echo "$STDIN_INPUT" | jq -e . &> /dev/null 2>&1; then
            USER_PROMPT=$(echo "$STDIN_INPUT" | jq -r '.prompt // empty' 2>/dev/null)
            log_debug "Parsed JSON input, prompt: ${USER_PROMPT}"
        else
            USER_PROMPT="$STDIN_INPUT"
            log_debug "Plain text input: ${USER_PROMPT}"
        fi
    else
        log_debug "No stdin input"
    fi

    # Aggregate all skills (with caching)
    AGGREGATED_SKILLS=$(mktemp)
    trap "rm -f '$AGGREGATED_SKILLS'" EXIT

    if ! aggregate_all_skills "$AGGREGATED_SKILLS" "$REPO_ROOT"; then
        log_error "Failed to aggregate skills"
        echo '{"message":"Failed to load skills"}'
        exit 0
    fi

    TOTAL_SKILLS=$(wc -l < "$AGGREGATED_SKILLS" | xargs)
    log_info "Total skills: ${TOTAL_SKILLS}"

    if [[ $TOTAL_SKILLS -eq 0 ]]; then
        log_warn "No skills found"
        echo '{"message":"No skills available"}'
        exit 0
    fi

    # Execute matching pipeline if prompt provided
    if [[ -z "$USER_PROMPT" ]]; then
        log_info "No prompt provided, showing summary only"
        local plugin_count=$(cut -d'|' -f2 "$AGGREGATED_SKILLS" | sort -u | wc -l | xargs)
        echo "{\"message\":\"Loaded ${TOTAL_SKILLS} skills from ${plugin_count} plugins\"}"
        exit 0
    fi

    # Run matching pipeline with timeout protection
    MATCHED_OUTPUT=$(mktemp)
    trap "rm -f '$MATCHED_OUTPUT' '$AGGREGATED_SKILLS'" EXIT

    if ! timeout "${OVERALL_TIMEOUT_MS}ms" bash -c "
        source '$LIB_DIR/plugin-discovery.sh' 2>/dev/null
        source '$LIB_DIR/metadata-parser.sh' 2>/dev/null
        source '$LIB_DIR/cache-manager.sh' 2>/dev/null
        $(declare -f log_info)
        $(declare -f log_warn)
        $(declare -f log_perf)
        $(declare -f log_debug)
        $(declare -f get_ms_timestamp)
        $(declare -f tier1_keyword_match)
        $(declare -f tier2_tfidf_match)
        $(declare -f tier3_semantic_match)
        $(declare -f execute_matching_pipeline)
        execute_matching_pipeline '$USER_PROMPT' '$AGGREGATED_SKILLS'
    " > "$MATCHED_OUTPUT" 2>/dev/null; then
        log_warn "Matching pipeline timed out, using keyword-only fallback"
        tier1_keyword_match "$USER_PROMPT" "$AGGREGATED_SKILLS" "$MATCHED_OUTPUT"
    fi

    MATCHED_COUNT=$(wc -l < "$MATCHED_OUTPUT" | xargs)
    log_info "Final matched skills: ${MATCHED_COUNT}"

    # Build and output JSON
    OUTPUT_JSON=$(build_output_json "$MATCHED_OUTPUT" "$TOTAL_SKILLS")
    echo "$OUTPUT_JSON" | tee "$DEBUG_OUTPUT_FILE"

    log_info "Hook execution completed"
}

# ============================================================================
# Execute Main
# ============================================================================

main "$@"
exit 0
