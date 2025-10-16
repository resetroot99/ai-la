#!/bin/bash

################################################################################
# AI Evaluation Framework
# Measures and tracks AI improvement in code quality, efficiency, and context
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
EVAL_DIR="${HOME}/.ai-coding-stack/evaluation"
BENCHMARKS_DIR="${EVAL_DIR}/benchmarks"
RESULTS_DIR="${EVAL_DIR}/results"
HISTORY_DIR="${EVAL_DIR}/history"

mkdir -p "$BENCHMARKS_DIR" "$RESULTS_DIR" "$HISTORY_DIR"

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
MODEL="${AI_MODEL:-qwen2.5-coder:32b}"

################################################################################
# Logging
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# AI Query Helper
################################################################################

ai_query() {
    local prompt="$1"
    local model="${2:-$MODEL}"
    
    local start_time=$(date +%s%3N)
    
    local response=$(curl -s "${OLLAMA_HOST}/api/generate" -d "{
        \"model\": \"$model\",
        \"prompt\": \"$prompt\",
        \"stream\": false
    }" | jq -r '.response')
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    echo "$response"
    echo "$duration" > /tmp/ai_query_duration
}

################################################################################
# 1. Code Quality Metrics
################################################################################

evaluate_code_quality() {
    log_step "Evaluating Code Quality"
    
    local test_cases=(
        "Write a function to validate email addresses"
        "Create a REST API endpoint for user authentication"
        "Implement a binary search algorithm"
        "Write a function to parse JSON safely"
        "Create a database connection pool manager"
    )
    
    local total_score=0
    local test_count=${#test_cases[@]}
    
    for i in "${!test_cases[@]}"; do
        local prompt="${test_cases[$i]}"
        log "Test $((i+1))/$test_count: $prompt"
        
        local code=$(ai_query "$prompt")
        
        # Evaluate code quality
        local quality_score=$(evaluate_code_snippet "$code" "$prompt")
        
        log_info "Quality Score: $quality_score/100"
        total_score=$((total_score + quality_score))
    done
    
    local avg_score=$((total_score / test_count))
    
    echo "$avg_score" > "${RESULTS_DIR}/code_quality_score.txt"
    log "✓ Average Code Quality Score: $avg_score/100"
    
    return $avg_score
}

evaluate_code_snippet() {
    local code="$1"
    local prompt="$2"
    
    local score=0
    
    # Check for error handling (20 points)
    if echo "$code" | grep -qi "try\|catch\|error\|exception\|if.*err"; then
        score=$((score + 20))
    fi
    
    # Check for documentation (20 points)
    if echo "$code" | grep -qi "\/\/\|#\|\/\*\*\|\"\"\""; then
        score=$((score + 20))
    fi
    
    # Check for type hints/annotations (20 points)
    if echo "$code" | grep -qi ":\s*\w\+\|<\w\+>\|@type"; then
        score=$((score + 20))
    fi
    
    # Check for validation (20 points)
    if echo "$code" | grep -qi "validate\|check\|verify\|assert"; then
        score=$((score + 20))
    fi
    
    # Check for best practices (20 points)
    if echo "$code" | grep -qi "const\|let\|async\|await\|return"; then
        score=$((score + 20))
    fi
    
    echo "$score"
}

################################################################################
# 2. Efficiency Metrics
################################################################################

evaluate_efficiency() {
    log_step "Evaluating Efficiency"
    
    local test_prompts=(
        "Write a function to find duplicates in an array"
        "Implement a cache with LRU eviction"
        "Create a function to merge sorted arrays"
    )
    
    local total_time=0
    local total_tokens=0
    
    for prompt in "${test_prompts[@]}"; do
        log "Testing: $prompt"
        
        local start=$(date +%s%3N)
        local response=$(ai_query "$prompt")
        local duration=$(cat /tmp/ai_query_duration)
        
        local tokens=$(echo "$response" | wc -w)
        
        log_info "Response time: ${duration}ms"
        log_info "Tokens generated: $tokens"
        
        total_time=$((total_time + duration))
        total_tokens=$((total_tokens + tokens))
    done
    
    local avg_time=$((total_time / ${#test_prompts[@]}))
    local avg_tokens=$((total_tokens / ${#test_prompts[@]}))
    local tokens_per_sec=$((avg_tokens * 1000 / avg_time))
    
    echo "$avg_time" > "${RESULTS_DIR}/avg_response_time.txt"
    echo "$tokens_per_sec" > "${RESULTS_DIR}/tokens_per_second.txt"
    
    log "✓ Average Response Time: ${avg_time}ms"
    log "✓ Tokens per Second: $tokens_per_sec"
}

################################################################################
# 3. Context Understanding Metrics
################################################################################

evaluate_context_understanding() {
    log_step "Evaluating Context Understanding"
    
    # Create test project context
    local test_project_dir="/tmp/test_project"
    mkdir -p "$test_project_dir"
    
    cat > "$test_project_dir/user.py" << 'EOF'
class User:
    def __init__(self, username, email):
        self.username = username
        self.email = email
    
    def validate_email(self):
        return "@" in self.email
EOF
    
    cat > "$test_project_dir/auth.py" << 'EOF'
def authenticate(username, password):
    # TODO: Implement authentication
    pass
EOF
    
    # Test context awareness
    local context_tests=(
        "Complete the authenticate function in auth.py using the User class"
        "Add a method to User class to hash passwords"
        "Create a function to register new users"
    )
    
    local total_score=0
    
    for test in "${context_tests[@]}"; do
        log "Testing: $test"
        
        local context="Project files:\n$(cat $test_project_dir/*.py)"
        local prompt="Context:\n$context\n\nTask: $test"
        
        local response=$(ai_query "$prompt")
        
        # Check if response references existing code
        local score=0
        
        if echo "$response" | grep -qi "User\|username\|email"; then
            score=$((score + 30))
        fi
        
        if echo "$response" | grep -qi "import\|from"; then
            score=$((score + 20))
        fi
        
        if echo "$response" | grep -qi "validate\|hash\|password"; then
            score=$((score + 30))
        fi
        
        if echo "$response" | grep -qi "def\|class\|return"; then
            score=$((score + 20))
        fi
        
        log_info "Context Score: $score/100"
        total_score=$((total_score + score))
    done
    
    local avg_score=$((total_score / ${#context_tests[@]}))
    
    echo "$avg_score" > "${RESULTS_DIR}/context_understanding_score.txt"
    log "✓ Average Context Understanding Score: $avg_score/100"
    
    rm -rf "$test_project_dir"
}

################################################################################
# 4. Learning Progress Tracking
################################################################################

track_learning_progress() {
    log_step "Tracking Learning Progress"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local history_file="${HISTORY_DIR}/evaluation_${timestamp}.json"
    
    # Collect all metrics
    local quality_score=$(cat "${RESULTS_DIR}/code_quality_score.txt" 2>/dev/null || echo "0")
    local response_time=$(cat "${RESULTS_DIR}/avg_response_time.txt" 2>/dev/null || echo "0")
    local tokens_per_sec=$(cat "${RESULTS_DIR}/tokens_per_second.txt" 2>/dev/null || echo "0")
    local context_score=$(cat "${RESULTS_DIR}/context_understanding_score.txt" 2>/dev/null || echo "0")
    
    # Calculate overall score
    local overall_score=$(( (quality_score + context_score) / 2 ))
    
    # Save to history
    cat > "$history_file" << EOF
{
  "timestamp": "$timestamp",
  "date": "$(date -Iseconds)",
  "metrics": {
    "code_quality": $quality_score,
    "context_understanding": $context_score,
    "overall_score": $overall_score,
    "efficiency": {
      "avg_response_time_ms": $response_time,
      "tokens_per_second": $tokens_per_sec
    }
  },
  "model": "$MODEL",
  "knowledge_base_sources": $(find ~/.ai-coding-stack/learning/knowledge-base -name "*.json" 2>/dev/null | wc -l)
}
EOF
    
    log "✓ Progress saved to: $history_file"
    
    # Show improvement
    show_improvement
}

show_improvement() {
    log_step "Learning Progress Over Time"
    
    local history_files=($(ls -t "${HISTORY_DIR}"/evaluation_*.json 2>/dev/null))
    
    if [ ${#history_files[@]} -lt 2 ]; then
        log_info "Not enough data to show improvement (need at least 2 evaluations)"
        return
    fi
    
    # Compare latest with first
    local latest="${history_files[0]}"
    local first="${history_files[-1]}"
    
    local latest_score=$(jq -r '.metrics.overall_score' "$latest")
    local first_score=$(jq -r '.metrics.overall_score' "$first")
    
    local improvement=$((latest_score - first_score))
    local improvement_pct=$((improvement * 100 / first_score))
    
    echo ""
    echo "📊 Improvement Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "First Evaluation:  $first_score/100"
    echo "Latest Evaluation: $latest_score/100"
    echo ""
    
    if [ $improvement -gt 0 ]; then
        echo -e "${GREEN}Improvement: +$improvement points (+${improvement_pct}%)${NC}"
    elif [ $improvement -lt 0 ]; then
        echo -e "${RED}Regression: $improvement points (${improvement_pct}%)${NC}"
    else
        echo "No change"
    fi
    
    echo ""
    echo "Total Evaluations: ${#history_files[@]}"
    echo ""
}

################################################################################
# 5. Benchmark Suite
################################################################################

run_benchmark_suite() {
    log_step "Running Comprehensive Benchmark Suite"
    
    local benchmark_file="${BENCHMARKS_DIR}/standard_benchmark.json"
    
    if [ ! -f "$benchmark_file" ]; then
        create_benchmark_suite
    fi
    
    local total_tests=$(jq '.tests | length' "$benchmark_file")
    local passed=0
    local failed=0
    
    log "Running $total_tests benchmark tests..."
    
    for i in $(seq 0 $((total_tests - 1))); do
        local test_name=$(jq -r ".tests[$i].name" "$benchmark_file")
        local test_prompt=$(jq -r ".tests[$i].prompt" "$benchmark_file")
        local expected_keywords=$(jq -r ".tests[$i].expected_keywords[]" "$benchmark_file")
        
        log "Test $((i+1))/$total_tests: $test_name"
        
        local response=$(ai_query "$test_prompt")
        
        # Check if response contains expected keywords
        local test_passed=true
        
        while IFS= read -r keyword; do
            if ! echo "$response" | grep -qi "$keyword"; then
                test_passed=false
                break
            fi
        done <<< "$expected_keywords"
        
        if [ "$test_passed" = true ]; then
            passed=$((passed + 1))
            log_info "✓ Passed"
        else
            failed=$((failed + 1))
            log_warn "✗ Failed"
        fi
    done
    
    local pass_rate=$((passed * 100 / total_tests))
    
    echo "$pass_rate" > "${RESULTS_DIR}/benchmark_pass_rate.txt"
    
    log ""
    log "Benchmark Results:"
    log "  Passed: $passed/$total_tests"
    log "  Failed: $failed/$total_tests"
    log "  Pass Rate: $pass_rate%"
}

create_benchmark_suite() {
    log "Creating standard benchmark suite..."
    
    cat > "${BENCHMARKS_DIR}/standard_benchmark.json" << 'EOF'
{
  "version": "1.0",
  "tests": [
    {
      "name": "Basic Function",
      "prompt": "Write a function to calculate factorial",
      "expected_keywords": ["def", "factorial", "return"]
    },
    {
      "name": "Error Handling",
      "prompt": "Write a function to read a file with error handling",
      "expected_keywords": ["try", "except", "open"]
    },
    {
      "name": "API Endpoint",
      "prompt": "Create a REST API endpoint for user registration",
      "expected_keywords": ["post", "request", "response", "user"]
    },
    {
      "name": "Database Query",
      "prompt": "Write a SQL query to find top 10 users by score",
      "expected_keywords": ["SELECT", "ORDER BY", "LIMIT"]
    },
    {
      "name": "Async Function",
      "prompt": "Write an async function to fetch data from API",
      "expected_keywords": ["async", "await", "fetch"]
    },
    {
      "name": "Class Implementation",
      "prompt": "Create a class for a shopping cart",
      "expected_keywords": ["class", "def", "self"]
    },
    {
      "name": "Algorithm",
      "prompt": "Implement quicksort algorithm",
      "expected_keywords": ["def", "partition", "sort"]
    },
    {
      "name": "Testing",
      "prompt": "Write unit tests for a login function",
      "expected_keywords": ["test", "assert", "def"]
    },
    {
      "name": "Documentation",
      "prompt": "Write a documented function to validate email",
      "expected_keywords": ["def", "\"\"\"", "return"]
    },
    {
      "name": "Security",
      "prompt": "Write a function to hash passwords securely",
      "expected_keywords": ["hash", "salt", "bcrypt"]
    }
  ]
}
EOF
    
    log "✓ Benchmark suite created"
}

################################################################################
# 6. Generate Report
################################################################################

generate_report() {
    log_step "Generating Evaluation Report"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="${RESULTS_DIR}/report_${timestamp}.md"
    
    # Collect metrics
    local quality_score=$(cat "${RESULTS_DIR}/code_quality_score.txt" 2>/dev/null || echo "N/A")
    local context_score=$(cat "${RESULTS_DIR}/context_understanding_score.txt" 2>/dev/null || echo "N/A")
    local response_time=$(cat "${RESULTS_DIR}/avg_response_time.txt" 2>/dev/null || echo "N/A")
    local tokens_per_sec=$(cat "${RESULTS_DIR}/tokens_per_second.txt" 2>/dev/null || echo "N/A")
    local benchmark_pass=$(cat "${RESULTS_DIR}/benchmark_pass_rate.txt" 2>/dev/null || echo "N/A")
    
    # Calculate overall grade
    local overall_score=$(( (quality_score + context_score) / 2 ))
    local grade="F"
    
    if [ $overall_score -ge 90 ]; then
        grade="A+"
    elif [ $overall_score -ge 85 ]; then
        grade="A"
    elif [ $overall_score -ge 80 ]; then
        grade="B+"
    elif [ $overall_score -ge 75 ]; then
        grade="B"
    elif [ $overall_score -ge 70 ]; then
        grade="C+"
    elif [ $overall_score -ge 65 ]; then
        grade="C"
    elif [ $overall_score -ge 60 ]; then
        grade="D"
    fi
    
    cat > "$report_file" << EOF
# AI Evaluation Report

**Date:** $(date)  
**Model:** $MODEL  
**Overall Grade:** $grade ($overall_score/100)

---

## Summary

| Metric | Score | Grade |
|--------|-------|-------|
| **Code Quality** | $quality_score/100 | $(get_grade $quality_score) |
| **Context Understanding** | $context_score/100 | $(get_grade $context_score) |
| **Benchmark Pass Rate** | $benchmark_pass% | $(get_grade $benchmark_pass) |
| **Overall** | $overall_score/100 | $grade |

## Performance Metrics

- **Average Response Time:** ${response_time}ms
- **Tokens per Second:** $tokens_per_sec
- **Efficiency Rating:** $(get_efficiency_rating $tokens_per_sec)

## Detailed Analysis

### Code Quality ($quality_score/100)

Measures:
- Error handling implementation
- Code documentation
- Type hints and annotations
- Input validation
- Best practices adherence

### Context Understanding ($context_score/100)

Measures:
- Ability to reference existing code
- Understanding of project structure
- Appropriate use of imports
- Consistency with codebase

### Benchmark Results ($benchmark_pass%)

Standard benchmark suite with 10 tests covering:
- Basic functions
- Error handling
- API endpoints
- Database queries
- Async operations
- Classes
- Algorithms
- Testing
- Documentation
- Security

## Learning Progress

$(show_learning_progress_summary)

## Recommendations

$(generate_recommendations $quality_score $context_score $benchmark_pass)

---

*Generated by AI Evaluation Framework*
EOF
    
    log "✓ Report generated: $report_file"
    
    # Display report
    cat "$report_file"
}

get_grade() {
    local score=$1
    
    if [ $score -ge 90 ]; then echo "A+"
    elif [ $score -ge 85 ]; then echo "A"
    elif [ $score -ge 80 ]; then echo "B+"
    elif [ $score -ge 75 ]; then echo "B"
    elif [ $score -ge 70 ]; then echo "C+"
    elif [ $score -ge 65 ]; then echo "C"
    elif [ $score -ge 60 ]; then echo "D"
    else echo "F"
    fi
}

get_efficiency_rating() {
    local tokens_per_sec=$1
    
    if [ $tokens_per_sec -ge 150 ]; then echo "Excellent"
    elif [ $tokens_per_sec -ge 100 ]; then echo "Good"
    elif [ $tokens_per_sec -ge 50 ]; then echo "Average"
    else echo "Needs Improvement"
    fi
}

show_learning_progress_summary() {
    local history_files=($(ls -t "${HISTORY_DIR}"/evaluation_*.json 2>/dev/null))
    
    if [ ${#history_files[@]} -eq 0 ]; then
        echo "No historical data available."
        return
    fi
    
    echo "Total evaluations: ${#history_files[@]}"
    echo ""
    
    if [ ${#history_files[@]} -ge 2 ]; then
        local latest="${history_files[0]}"
        local first="${history_files[-1]}"
        
        local latest_score=$(jq -r '.metrics.overall_score' "$latest")
        local first_score=$(jq -r '.metrics.overall_score' "$first")
        
        local improvement=$((latest_score - first_score))
        
        echo "First evaluation score: $first_score/100"
        echo "Latest evaluation score: $latest_score/100"
        echo "Improvement: +$improvement points"
    fi
}

generate_recommendations() {
    local quality=$1
    local context=$2
    local benchmark=$3
    
    echo ""
    
    if [ $quality -lt 75 ]; then
        echo "- **Code Quality:** Consider learning from more high-quality open-source projects"
    fi
    
    if [ $context -lt 75 ]; then
        echo "- **Context Understanding:** Analyze more of your local projects to improve context awareness"
    fi
    
    if [ $benchmark -lt 80 ]; then
        echo "- **Benchmarks:** Run learning system to improve on failed test cases"
    fi
    
    echo "- Run \`./scripts/ai-learning-system.sh learn-local ~/projects\` to improve"
    echo "- Enable continuous learning with \`./scripts/ai-learning-system.sh enable-continuous\`"
}

################################################################################
# CLI Interface
################################################################################

show_help() {
    cat << 'EOF'
AI Evaluation Framework - Measure AI improvement over time

Usage: ai-evaluation.sh <command>

Commands:
  full              Run complete evaluation suite
  quality           Evaluate code quality only
  efficiency        Evaluate efficiency only
  context           Evaluate context understanding only
  benchmark         Run benchmark suite only
  report            Generate evaluation report
  progress          Show learning progress
  compare           Compare two evaluations
  
  help              Show this help

Examples:
  # Run full evaluation
  ai-evaluation.sh full
  
  # Check progress
  ai-evaluation.sh progress
  
  # Generate report
  ai-evaluation.sh report

Results saved to: $RESULTS_DIR
History saved to: $HISTORY_DIR
EOF
}

################################################################################
# Main
################################################################################

main() {
    local command="${1:-help}"
    
    case "$command" in
        full)
            evaluate_code_quality
            evaluate_efficiency
            evaluate_context_understanding
            run_benchmark_suite
            track_learning_progress
            generate_report
            ;;
        quality)
            evaluate_code_quality
            ;;
        efficiency)
            evaluate_efficiency
            ;;
        context)
            evaluate_context_understanding
            ;;
        benchmark)
            run_benchmark_suite
            ;;
        report)
            generate_report
            ;;
        progress)
            show_improvement
            ;;
        compare)
            # TODO: Implement comparison
            log_info "Comparison feature coming soon"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'ai-evaluation.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"

