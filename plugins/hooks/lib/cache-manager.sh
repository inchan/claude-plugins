#!/bin/bash
# Cache Manager Library
# Manages skill metadata cache with change detection
#
# v3.0.0 - Intelligent caching with mtime tracking

CACHE_DIR="${CACHE_DIR:-$(dirname "$0")/../cache}"
CACHE_FILE="$CACHE_DIR/skill-metadata.json"
CACHE_INDEX="$CACHE_DIR/file-index.txt"

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"

    if [[ ! -f "$CACHE_FILE" ]]; then
        echo '{"skills":[],"timestamp":0}' > "$CACHE_FILE"
    fi

    if [[ ! -f "$CACHE_INDEX" ]]; then
        touch "$CACHE_INDEX"
    fi
}

# Check if cache is valid
is_cache_valid() {
    local max_age_seconds="${1:-3600}"  # Default: 1 hour

    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    local cache_timestamp=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - cache_timestamp))

    if [[ $age -gt $max_age_seconds ]]; then
        return 1
    fi

    return 0
}

# Check if skill files have changed
detect_file_changes() {
    local current_index=$(mktemp)

    # Build current file index (file path + mtime)
    while IFS='|' read -r plugin skill file; do
        if [[ -f "$file" ]]; then
            local mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
            echo "$file|$mtime" >> "$current_index"
        fi
    done

    # Compare with cached index
    if [[ -f "$CACHE_INDEX" ]]; then
        if diff -q "$CACHE_INDEX" "$current_index" > /dev/null 2>&1; then
            rm -f "$current_index"
            return 0  # No changes
        fi
    fi

    # Files changed, update index
    mv "$current_index" "$CACHE_INDEX"
    return 1  # Changes detected
}

# Save metadata to cache
save_to_cache() {
    local metadata_json="$1"

    init_cache

    if [[ -n "$metadata_json" ]]; then
        echo "$metadata_json" > "$CACHE_FILE"
    fi
}

# Load metadata from cache
load_from_cache() {
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo '{"skills":[],"timestamp":0}'
    fi
}

# Update cache if needed
update_cache_if_needed() {
    local force_update="${1:-false}"
    local max_age="${2:-3600}"

    # Check if cache is valid
    if [[ "$force_update" != "true" ]] && is_cache_valid "$max_age"; then
        # Check file changes
        if detect_file_changes; then
            # Cache valid and no file changes
            return 0
        fi
    fi

    # Cache invalid or files changed, rebuild
    echo "[INFO] Rebuilding skill metadata cache..." >&2

    # Source required libraries (with guard to prevent double-loading)
    local lib_dir="$(dirname "$0")"
    [[ -z "${_PLUGIN_DISCOVERY_LOADED:-}" ]] && source "$lib_dir/plugin-discovery.sh"
    [[ -z "${_METADATA_PARSER_LOADED:-}" ]] && source "$lib_dir/metadata-parser.sh"

    # Discover and parse skills
    local metadata=$(discover_all_skills "simple" | parse_all_skills_metadata "json")

    # Save to cache
    save_to_cache "$metadata"

    return 1
}

# Clear cache
clear_cache() {
    rm -f "$CACHE_FILE" "$CACHE_INDEX"
    echo "[INFO] Cache cleared" >&2
}

# Get cache statistics
cache_stats() {
    init_cache

    local cache_size=0
    local cache_age=0
    local skill_count=0

    if [[ -f "$CACHE_FILE" ]]; then
        cache_size=$(du -h "$CACHE_FILE" | cut -f1)
        local cache_timestamp=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)
        local current_timestamp=$(date +%s)
        cache_age=$((current_timestamp - cache_timestamp))

        if command -v jq &> /dev/null; then
            skill_count=$(jq '.skills | length' "$CACHE_FILE" 2>/dev/null || echo 0)
        fi
    fi

    echo "Cache File: $CACHE_FILE"
    echo "Size: $cache_size"
    echo "Age: ${cache_age}s"
    echo "Skills: $skill_count"
}

# Export functions
export -f init_cache
export -f is_cache_valid
export -f detect_file_changes
export -f save_to_cache
export -f load_from_cache
export -f update_cache_if_needed
export -f clear_cache
export -f cache_stats
