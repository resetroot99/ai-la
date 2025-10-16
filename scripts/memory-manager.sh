#!/bin/bash

################################################################################
# Developer Memory Manager
# Imports, exports, and manages developer behavior patterns and preferences
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
MEMORY_DIR="${HOME}/.ai-coding-stack/memory"
PATTERNS_FILE="${MEMORY_DIR}/dev-patterns.json"
PREFERENCES_FILE="${MEMORY_DIR}/dev-preferences.json"
BEHAVIORS_FILE="${MEMORY_DIR}/dev-behaviors.json"
EXPORT_DIR="${MEMORY_DIR}/exports"

mkdir -p "$MEMORY_DIR" "$EXPORT_DIR"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Import Functions
################################################################################

import_openai_storage() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        log_error "File not found: $input_file"
        return 1
    fi
    
    log "Importing from OpenAI storage format..."
    
    # Parse OpenAI storage JSON and convert to our format
    jq '
    {
        "coding_patterns": [
            .conversations[] | 
            select(.messages[].content | contains("code") or contains("function") or contains("class")) |
            {
                "pattern": (.messages[-1].content | split("\n")[0]),
                "context": .title,
                "frequency": 1,
                "last_used": .updated_at
            }
        ],
        "preferences": {
            "languages": [.conversations[].messages[].content | scan("\\b(Python|JavaScript|TypeScript|Go|Rust|Java)\\b") | ascii_downcase] | unique,
            "frameworks": [.conversations[].messages[].content | scan("\\b(React|Vue|Angular|Next\\.js|Django|Flask|FastAPI)\\b")] | unique,
            "tools": [.conversations[].messages[].content | scan("\\b(VSCode|Git|Docker|Kubernetes)\\b")] | unique
        },
        "behaviors": {
            "code_style": "inferred_from_conversations",
            "testing_preference": (if [.conversations[].messages[].content | contains("test")] | any then "writes_tests" else "minimal_testing" end),
            "documentation_style": (if [.conversations[].messages[].content | contains("doc") or contains("comment")] | any then "detailed" else "minimal" end)
        },
        "imported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "source": "openai_storage"
    }
    ' "$input_file" > "${MEMORY_DIR}/imported-openai.json"
    
    log "✓ Imported to ${MEMORY_DIR}/imported-openai.json"
    
    # Merge with existing patterns
    merge_patterns "${MEMORY_DIR}/imported-openai.json"
}

import_cursor_rules() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        log_error "File not found: $input_file"
        return 1
    fi
    
    log "Importing from .cursorrules format..."
    
    # Convert cursor rules to JSON
    local rules_json=$(cat "$input_file" | jq -Rs '{
        "cursor_rules": split("\n") | map(select(length > 0)),
        "imported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "source": "cursorrules"
    }')
    
    echo "$rules_json" > "${MEMORY_DIR}/imported-cursor.json"
    
    log "✓ Imported to ${MEMORY_DIR}/imported-cursor.json"
}

import_github_copilot_data() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        log_error "File not found: $input_file"
        return 1
    fi
    
    log "Importing from GitHub Copilot data..."
    
    jq '{
        "coding_patterns": .suggestions[] | {
            "pattern": .code,
            "context": .context,
            "language": .language,
            "accepted": .accepted
        },
        "imported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "source": "github_copilot"
    }' "$input_file" > "${MEMORY_DIR}/imported-copilot.json"
    
    log "✓ Imported to ${MEMORY_DIR}/imported-copilot.json"
}

import_custom_json() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        log_error "File not found: $input_file"
        return 1
    fi
    
    log "Importing custom JSON..."
    
    # Validate JSON
    if ! jq empty "$input_file" 2>/dev/null; then
        log_error "Invalid JSON format"
        return 1
    fi
    
    # Add metadata
    jq '. + {
        "imported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "source": "custom_import"
    }' "$input_file" > "${MEMORY_DIR}/imported-custom.json"
    
    log "✓ Imported to ${MEMORY_DIR}/imported-custom.json"
}

################################################################################
# Pattern Analysis
################################################################################

analyze_codebase() {
    local project_dir="$1"
    
    if [ ! -d "$project_dir" ]; then
        log_error "Directory not found: $project_dir"
        return 1
    fi
    
    log "Analyzing codebase: $project_dir"
    
    local analysis_file="${MEMORY_DIR}/codebase-analysis-$(date +%Y%m%d-%H%M%S).json"
    
    # Detect languages
    local languages=$(find "$project_dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) | \
        sed 's/.*\.//' | sort | uniq -c | sort -rn | \
        jq -R 'split(" ") | {language: .[1], count: (.[0] | tonumber)}' | jq -s '.')
    
    # Detect frameworks
    local frameworks='[]'
    if [ -f "$project_dir/package.json" ]; then
        frameworks=$(jq -r '.dependencies // {} | keys[]' "$project_dir/package.json" | \
            grep -E "react|vue|angular|next|express|fastify" | jq -R . | jq -s '.')
    fi
    
    # Detect code patterns
    local patterns=$(find "$project_dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) -exec grep -h "^import\|^from\|^class\|^function\|^def\|^const.*=.*=>" {} \; | \
        head -100 | jq -R . | jq -s '.')
    
    # Detect testing
    local has_tests=$(find "$project_dir" -type f \( -name "*test*" -o -name "*spec*" \) | wc -l)
    
    # Create analysis JSON
    cat > "$analysis_file" << EOF
{
    "project_path": "$project_dir",
    "analyzed_at": "$(date -Iseconds)",
    "languages": $languages,
    "frameworks": $frameworks,
    "common_patterns": $patterns,
    "has_tests": $([ "$has_tests" -gt 0 ] && echo "true" || echo "false"),
    "test_files_count": $has_tests,
    "total_files": $(find "$project_dir" -type f | wc -l)
}
EOF
    
    log "✓ Analysis saved to $analysis_file"
    
    # Auto-generate patterns
    generate_patterns_from_analysis "$analysis_file"
}

generate_patterns_from_analysis() {
    local analysis_file="$1"
    
    log "Generating patterns from analysis..."
    
    jq '
    {
        "coding_patterns": [
            {
                "pattern": "preferred_languages",
                "value": [.languages[] | select(.count > 10) | .language],
                "confidence": "high"
            },
            {
                "pattern": "framework_usage",
                "value": .frameworks,
                "confidence": "high"
            },
            {
                "pattern": "testing_approach",
                "value": (if .has_tests then "test_driven" else "minimal_testing" end),
                "confidence": "medium"
            }
        ],
        "preferences": {
            "primary_language": (.languages | sort_by(.count) | reverse | .[0].language),
            "uses_typescript": ([.languages[].language] | contains(["ts"])),
            "writes_tests": .has_tests
        },
        "generated_at": now | strftime("%Y-%m-%d %H:%M:%S")
    }
    ' "$analysis_file" > "${MEMORY_DIR}/generated-patterns.json"
    
    log "✓ Patterns generated at ${MEMORY_DIR}/generated-patterns.json"
}

################################################################################
# Export Functions
################################################################################

export_all() {
    local export_file="${EXPORT_DIR}/memory-export-$(date +%Y%m%d-%H%M%S).json"
    
    log "Exporting all memory data..."
    
    jq -s '
    {
        "version": "1.0",
        "exported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
        "patterns": (.[0] // {}),
        "preferences": (.[1] // {}),
        "behaviors": (.[2] // {})
    }
    ' "$PATTERNS_FILE" "$PREFERENCES_FILE" "$BEHAVIORS_FILE" > "$export_file"
    
    log "✓ Exported to $export_file"
    echo "$export_file"
}

export_for_sharing() {
    local export_file="${EXPORT_DIR}/shareable-patterns-$(date +%Y%m%d-%H%M%S).json"
    
    log "Creating shareable export (anonymized)..."
    
    jq '
    {
        "version": "1.0",
        "type": "shareable_patterns",
        "patterns": .patterns,
        "general_preferences": {
            "languages": .preferences.languages,
            "frameworks": .preferences.frameworks,
            "code_style": .behaviors.code_style
        }
    }
    ' "$PATTERNS_FILE" > "$export_file"
    
    log "✓ Shareable export created at $export_file"
    echo "$export_file"
}

################################################################################
# Merge and Update
################################################################################

merge_patterns() {
    local import_file="$1"
    
    log "Merging patterns..."
    
    if [ ! -f "$PATTERNS_FILE" ]; then
        echo '{"coding_patterns": [], "last_updated": ""}' > "$PATTERNS_FILE"
    fi
    
    jq -s '
    {
        "coding_patterns": (.[0].coding_patterns + .[1].coding_patterns) | unique_by(.pattern),
        "last_updated": now | strftime("%Y-%m-%d %H:%M:%S"),
        "sources": [.[0].source, .[1].source] | unique
    }
    ' "$PATTERNS_FILE" "$import_file" > "${PATTERNS_FILE}.tmp"
    
    mv "${PATTERNS_FILE}.tmp" "$PATTERNS_FILE"
    
    log "✓ Patterns merged successfully"
}

update_from_git_history() {
    local repo_dir="$1"
    
    if [ ! -d "$repo_dir/.git" ]; then
        log_error "Not a git repository: $repo_dir"
        return 1
    fi
    
    log "Analyzing git history..."
    
    cd "$repo_dir"
    
    # Get commit patterns
    local commit_patterns=$(git log --pretty=format:"%s" --since="3 months ago" | \
        jq -R . | jq -s '
        {
            "commit_patterns": group_by(.) | map({
                "message_pattern": .[0],
                "frequency": length
            }) | sort_by(.frequency) | reverse | .[0:20]
        }
        ')
    
    # Get file change patterns
    local file_patterns=$(git log --name-only --pretty=format: --since="3 months ago" | \
        sort | uniq -c | sort -rn | head -20 | \
        jq -R 'split(" ") | {file: .[1], changes: (.[0] | tonumber)}' | jq -s '.')
    
    # Get author patterns (coding hours)
    local time_patterns=$(git log --pretty=format:"%ad" --date=format:"%H" --since="3 months ago" | \
        sort | uniq -c | sort -rn | \
        jq -R 'split(" ") | {hour: .[1], commits: (.[0] | tonumber)}' | jq -s '.')
    
    cat > "${MEMORY_DIR}/git-analysis.json" << EOF
{
    "analyzed_at": "$(date -Iseconds)",
    "repository": "$repo_dir",
    "commit_patterns": $commit_patterns,
    "file_patterns": $file_patterns,
    "coding_hours": $time_patterns
}
EOF
    
    log "✓ Git analysis saved to ${MEMORY_DIR}/git-analysis.json"
}

################################################################################
# Generate AI Instructions
################################################################################

generate_ai_instructions() {
    log "Generating AI instructions from memory..."
    
    local instructions_file="${MEMORY_DIR}/ai-instructions.md"
    
    # Combine all memory data
    local combined_data=$(jq -s '
    {
        patterns: (.[0].coding_patterns // []),
        preferences: (.[1] // {}),
        behaviors: (.[2] // {})
    }
    ' "$PATTERNS_FILE" "$PREFERENCES_FILE" "$BEHAVIORS_FILE")
    
    cat > "$instructions_file" << 'HEADER'
# Developer Memory - AI Instructions

This file contains learned patterns and preferences for this developer.
Use this to provide more personalized and consistent coding assistance.

HEADER
    
    # Add language preferences
    echo "$combined_data" | jq -r '
    if .preferences.languages then
        "## Preferred Languages\n" +
        (.preferences.languages | map("- " + .) | join("\n")) +
        "\n"
    else "" end
    ' >> "$instructions_file"
    
    # Add framework preferences
    echo "$combined_data" | jq -r '
    if .preferences.frameworks then
        "\n## Preferred Frameworks\n" +
        (.preferences.frameworks | map("- " + .) | join("\n")) +
        "\n"
    else "" end
    ' >> "$instructions_file"
    
    # Add coding patterns
    echo "$combined_data" | jq -r '
    if .patterns then
        "\n## Coding Patterns\n" +
        (.patterns | map("- " + .pattern + " (context: " + .context + ")") | join("\n")) +
        "\n"
    else "" end
    ' >> "$instructions_file"
    
    # Add behaviors
    cat >> "$instructions_file" << 'BEHAVIORS'

## Code Style Preferences
- Follow existing patterns in the codebase
- Maintain consistency with previous implementations
- Prioritize readability and maintainability

## Testing Approach
- Write tests for critical functionality
- Follow existing test patterns
- Maintain test coverage

## Documentation Style
- Document complex logic
- Add inline comments for clarity
- Keep documentation up-to-date
BEHAVIORS
    
    log "✓ AI instructions generated at $instructions_file"
    echo "$instructions_file"
}

################################################################################
# CLI Interface
################################################################################

show_usage() {
    cat << EOF
Developer Memory Manager

Usage: $0 <command> [arguments]

Commands:
    import-openai <file>        Import from OpenAI storage JSON
    import-cursor <file>        Import from .cursorrules file
    import-copilot <file>       Import from GitHub Copilot data
    import-json <file>          Import custom JSON format
    
    analyze-codebase <dir>      Analyze codebase and extract patterns
    analyze-git <dir>           Analyze git history for patterns
    
    export                      Export all memory data
    export-shareable            Export anonymized shareable patterns
    
    generate-instructions       Generate AI instructions from memory
    
    show                        Show current memory summary
    clear                       Clear all memory data

Examples:
    $0 import-openai ~/Downloads/openai-storage.json
    $0 analyze-codebase ~/projects/my-app
    $0 generate-instructions
EOF
}

show_memory_summary() {
    log "Memory Summary:"
    echo ""
    
    if [ -f "$PATTERNS_FILE" ]; then
        local pattern_count=$(jq '.coding_patterns | length' "$PATTERNS_FILE")
        echo "Coding Patterns: $pattern_count"
    fi
    
    if [ -f "$PREFERENCES_FILE" ]; then
        echo "Preferences:"
        jq -r '.languages // [] | map("  - " + .) | join("\n")' "$PREFERENCES_FILE"
    fi
    
    if [ -f "$BEHAVIORS_FILE" ]; then
        echo "Behaviors:"
        jq -r 'to_entries | map("  - " + .key + ": " + (.value | tostring)) | join("\n")' "$BEHAVIORS_FILE"
    fi
}

clear_memory() {
    read -p "Are you sure you want to clear all memory data? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$PATTERNS_FILE" "$PREFERENCES_FILE" "$BEHAVIORS_FILE"
        log "✓ Memory cleared"
    else
        log "Cancelled"
    fi
}

# Main CLI handler
case "${1:-}" in
    import-openai)
        import_openai_storage "$2"
        ;;
    import-cursor)
        import_cursor_rules "$2"
        ;;
    import-copilot)
        import_github_copilot_data "$2"
        ;;
    import-json)
        import_custom_json "$2"
        ;;
    analyze-codebase)
        analyze_codebase "$2"
        ;;
    analyze-git)
        update_from_git_history "$2"
        ;;
    export)
        export_all
        ;;
    export-shareable)
        export_for_sharing
        ;;
    generate-instructions)
        generate_ai_instructions
        ;;
    show)
        show_memory_summary
        ;;
    clear)
        clear_memory
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

