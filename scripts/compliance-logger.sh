#!/bin/bash

################################################################################
# AI Compliance Logger
# Comprehensive logging system for AI interactions and code generation
# Stores all AI requests/responses for audit, compliance, and training
################################################################################

set -e

# Configuration
COMPLIANCE_DIR="${HOME}/.ai-coding-stack/compliance"
LOGS_DIR="${COMPLIANCE_DIR}/logs"
SESSIONS_DIR="${COMPLIANCE_DIR}/sessions"
ANALYTICS_DIR="${COMPLIANCE_DIR}/analytics"
EXPORT_DIR="${COMPLIANCE_DIR}/exports"

# Create directories
mkdir -p "$LOGS_DIR" "$SESSIONS_DIR" "$ANALYTICS_DIR" "$EXPORT_DIR"

# Session tracking
SESSION_ID=$(date +%Y%m%d-%H%M%S)-$$
SESSION_FILE="${SESSIONS_DIR}/${SESSION_ID}.jsonl"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Logging Functions
################################################################################

log_ai_request() {
    local model="$1"
    local prompt="$2"
    local context="${3:-}"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"request","timestamp":"$timestamp","session":"$SESSION_ID","model":"$model","prompt":$(echo "$prompt" | jq -Rs .),"context":$(echo "$context" | jq -Rs .)}
EOF
}

log_ai_response() {
    local model="$1"
    local response="$2"
    local tokens_used="${3:-0}"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"response","timestamp":"$timestamp","session":"$SESSION_ID","model":"$model","response":$(echo "$response" | jq -Rs .),"tokens":$tokens_used}
EOF
}

log_code_generation() {
    local language="$1"
    local code="$2"
    local purpose="$3"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"code_generation","timestamp":"$timestamp","session":"$SESSION_ID","language":"$language","code":$(echo "$code" | jq -Rs .),"purpose":"$purpose"}
EOF
}

log_code_modification() {
    local file_path="$1"
    local before="$2"
    local after="$3"
    local reason="$4"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"code_modification","timestamp":"$timestamp","session":"$SESSION_ID","file":"$file_path","before":$(echo "$before" | jq -Rs .),"after":$(echo "$after" | jq -Rs .),"reason":"$reason"}
EOF
}

log_error() {
    local error_type="$1"
    local error_message="$2"
    local context="${3:-}"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"error","timestamp":"$timestamp","session":"$SESSION_ID","error_type":"$error_type","message":"$error_message","context":"$context"}
EOF
}

log_decision() {
    local decision_type="$1"
    local decision="$2"
    local reasoning="$3"
    local timestamp=$(date -Iseconds)
    
    cat >> "$SESSION_FILE" << EOF
{"type":"decision","timestamp":"$timestamp","session":"$SESSION_ID","decision_type":"$decision_type","decision":"$decision","reasoning":"$reasoning"}
EOF
}

################################################################################
# Analytics Functions
################################################################################

generate_session_summary() {
    local session_file="$1"
    
    if [ ! -f "$session_file" ]; then
        echo "Session file not found: $session_file"
        return 1
    fi
    
    local total_requests=$(jq -s '[.[] | select(.type=="request")] | length' "$session_file")
    local total_responses=$(jq -s '[.[] | select(.type=="response")] | length' "$session_file")
    local total_code_gen=$(jq -s '[.[] | select(.type=="code_generation")] | length' "$session_file")
    local total_modifications=$(jq -s '[.[] | select(.type=="code_modification")] | length' "$session_file")
    local total_errors=$(jq -s '[.[] | select(.type=="error")] | length' "$session_file")
    local total_tokens=$(jq -s '[.[] | select(.type=="response") | .tokens] | add // 0' "$session_file")
    
    local models_used=$(jq -s '[.[] | select(.model) | .model] | unique | join(", ")' "$session_file" | tr -d '"')
    local languages_used=$(jq -s '[.[] | select(.language) | .language] | unique | join(", ")' "$session_file" | tr -d '"')
    
    cat << EOF
{
  "session_id": "$(basename "$session_file" .jsonl)",
  "summary": {
    "total_requests": $total_requests,
    "total_responses": $total_responses,
    "code_generations": $total_code_gen,
    "code_modifications": $total_modifications,
    "errors": $total_errors,
    "total_tokens": $total_tokens
  },
  "models_used": "$models_used",
  "languages_used": "$languages_used",
  "session_file": "$session_file"
}
EOF
}

generate_daily_report() {
    local date="${1:-$(date +%Y-%m-%d)}"
    local report_file="${ANALYTICS_DIR}/daily-${date}.json"
    
    echo "Generating daily report for $date..."
    
    local sessions=$(find "$SESSIONS_DIR" -name "${date}*.jsonl" 2>/dev/null)
    
    if [ -z "$sessions" ]; then
        echo "No sessions found for $date"
        return 1
    fi
    
    echo "{" > "$report_file"
    echo "  \"date\": \"$date\"," >> "$report_file"
    echo "  \"sessions\": [" >> "$report_file"
    
    local first=true
    for session in $sessions; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$report_file"
        fi
        generate_session_summary "$session" | sed 's/^/    /' >> "$report_file"
    done
    
    echo "" >> "$report_file"
    echo "  ]" >> "$report_file"
    echo "}" >> "$report_file"
    
    echo "Report saved to: $report_file"
}

################################################################################
# Export Functions
################################################################################

export_for_training() {
    local output_file="${EXPORT_DIR}/training-data-$(date +%Y%m%d-%H%M%S).jsonl"
    
    echo "Exporting data for AI training..."
    
    # Combine all sessions into training format
    find "$SESSIONS_DIR" -name "*.jsonl" -type f | while read session_file; do
        jq -c 'select(.type=="request" or .type=="response") | 
               {prompt: .prompt, response: .response, model: .model}' "$session_file" 2>/dev/null
    done > "$output_file"
    
    local count=$(wc -l < "$output_file")
    echo "Exported $count interactions to: $output_file"
}

export_code_patterns() {
    local output_file="${EXPORT_DIR}/code-patterns-$(date +%Y%m%d-%H%M%S).json"
    
    echo "Extracting code patterns..."
    
    # Extract all code generations and modifications
    find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec cat {} \; | \
    jq -s '[.[] | select(.type=="code_generation" or .type=="code_modification")] | 
           group_by(.language) | 
           map({language: .[0].language, count: length, examples: map({code: .code, purpose: .purpose}) | .[0:5]})' \
    > "$output_file"
    
    echo "Code patterns saved to: $output_file"
}

export_compliance_audit() {
    local start_date="${1:-$(date -d '30 days ago' +%Y-%m-%d)}"
    local end_date="${2:-$(date +%Y-%m-%d)}"
    local output_file="${EXPORT_DIR}/compliance-audit-${start_date}-to-${end_date}.json"
    
    echo "Generating compliance audit from $start_date to $end_date..."
    
    cat << EOF > "$output_file"
{
  "audit_period": {
    "start": "$start_date",
    "end": "$end_date"
  },
  "summary": {
EOF
    
    # Count all activities
    local total_sessions=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f | wc -l)
    local total_requests=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec cat {} \; | jq -s '[.[] | select(.type=="request")] | length')
    local total_code_gen=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec cat {} \; | jq -s '[.[] | select(.type=="code_generation")] | length')
    
    cat << EOF >> "$output_file"
    "total_sessions": $total_sessions,
    "total_ai_requests": $total_requests,
    "total_code_generations": $total_code_gen
  },
  "details": {
    "sessions_directory": "$SESSIONS_DIR",
    "logs_directory": "$LOGS_DIR"
  }
}
EOF
    
    echo "Compliance audit saved to: $output_file"
}

################################################################################
# Search and Query Functions
################################################################################

search_logs() {
    local query="$1"
    local type="${2:-all}"
    
    echo "Searching logs for: $query (type: $type)"
    
    if [ "$type" = "all" ]; then
        find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec grep -l "$query" {} \;
    else
        find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec jq -c "select(.type==\"$type\") | select(. | tostring | contains(\"$query\"))" {} \;
    fi
}

get_session_details() {
    local session_id="$1"
    local session_file="${SESSIONS_DIR}/${session_id}.jsonl"
    
    if [ ! -f "$session_file" ]; then
        echo "Session not found: $session_id"
        return 1
    fi
    
    echo "Session: $session_id"
    echo "File: $session_file"
    echo ""
    
    generate_session_summary "$session_file" | jq .
    
    echo ""
    echo "Full session log:"
    jq . "$session_file"
}

################################################################################
# Cleanup and Maintenance
################################################################################

cleanup_old_logs() {
    local days="${1:-90}"
    
    echo "Cleaning up logs older than $days days..."
    
    find "$SESSIONS_DIR" -name "*.jsonl" -type f -mtime +$days -delete
    find "$ANALYTICS_DIR" -name "*.json" -type f -mtime +$days -delete
    
    echo "Cleanup complete"
}

compress_old_logs() {
    local days="${1:-30}"
    
    echo "Compressing logs older than $days days..."
    
    find "$SESSIONS_DIR" -name "*.jsonl" -type f -mtime +$days | while read file; do
        gzip "$file"
        echo "Compressed: $file"
    done
    
    echo "Compression complete"
}

################################################################################
# Integration Hooks
################################################################################

# Hook for Continue extension
continue_hook() {
    local prompt="$1"
    local response="$2"
    local model="${3:-unknown}"
    
    log_ai_request "$model" "$prompt" "continue"
    log_ai_response "$model" "$response" 0
}

# Hook for Cline extension
cline_hook() {
    local action="$1"
    local details="$2"
    
    log_decision "cline_action" "$action" "$details"
}

# Hook for code generation
codegen_hook() {
    local language="$1"
    local code="$2"
    local file_path="${3:-unknown}"
    
    log_code_generation "$language" "$code" "Generated for: $file_path"
}

################################################################################
# CLI Interface
################################################################################

show_help() {
    cat << 'EOF'
AI Compliance Logger - Comprehensive logging for AI interactions

Usage: compliance-logger.sh <command> [options]

Commands:
  log-request <model> <prompt> [context]     Log an AI request
  log-response <model> <response> [tokens]   Log an AI response
  log-code <language> <code> <purpose>       Log code generation
  log-modification <file> <before> <after>   Log code modification
  
  session-summary <session_id>               Show session summary
  daily-report [date]                        Generate daily report
  
  export-training                            Export data for AI training
  export-patterns                            Export code patterns
  export-audit [start_date] [end_date]       Generate compliance audit
  
  search <query> [type]                      Search logs
  cleanup [days]                             Clean up old logs (default: 90 days)
  compress [days]                            Compress old logs (default: 30 days)
  
  stats                                      Show statistics
  help                                       Show this help

Examples:
  compliance-logger.sh log-request "qwen2.5-coder" "Write a function to sort array"
  compliance-logger.sh daily-report 2025-10-16
  compliance-logger.sh export-training
  compliance-logger.sh search "authentication" request
  compliance-logger.sh cleanup 60

Directories:
  Sessions:  $SESSIONS_DIR
  Analytics: $ANALYTICS_DIR
  Exports:   $EXPORT_DIR
EOF
}

show_stats() {
    echo "AI Compliance Logger Statistics"
    echo "================================"
    echo ""
    
    local total_sessions=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f | wc -l)
    local total_size=$(du -sh "$COMPLIANCE_DIR" 2>/dev/null | cut -f1)
    
    echo "Total sessions: $total_sessions"
    echo "Total storage: $total_size"
    echo ""
    
    if [ $total_sessions -gt 0 ]; then
        echo "Recent sessions:"
        find "$SESSIONS_DIR" -name "*.jsonl" -type f -printf '%T@ %p\n' | sort -rn | head -5 | while read timestamp file; do
            echo "  - $(basename "$file" .jsonl)"
        done
    fi
}

################################################################################
# Main
################################################################################

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        log-request)
            log_ai_request "$@"
            ;;
        log-response)
            log_ai_response "$@"
            ;;
        log-code)
            log_code_generation "$@"
            ;;
        log-modification)
            log_code_modification "$@"
            ;;
        session-summary)
            get_session_details "$@"
            ;;
        daily-report)
            generate_daily_report "$@"
            ;;
        export-training)
            export_for_training
            ;;
        export-patterns)
            export_code_patterns
            ;;
        export-audit)
            export_compliance_audit "$@"
            ;;
        search)
            search_logs "$@"
            ;;
        cleanup)
            cleanup_old_logs "$@"
            ;;
        compress)
            compress_old_logs "$@"
            ;;
        stats)
            show_stats
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'compliance-logger.sh help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"

